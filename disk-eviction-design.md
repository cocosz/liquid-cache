# RFC: Disk Budget Eviction with Lease-Based Safety

## Problem

LiquidCache currently has no disk size limit. When memory is full, entries are squeezed to disk (`MemoryArrow` → `DiskLiquid`), but disk grows unbounded. On long-running systems, this eventually fills the disk.

Adding a naive disk size limit creates a race condition: if we evict (delete) disk entries while a concurrent query is reading them, the query breaks.

## Why This Is Tricky

LiquidCache's read path has a two-phase contract per row group:

1. **FillCache** — identify missing batches, fetch them all from Parquet into cache
2. **ReadFromCache** — read everything from cache, no fallback to Parquet

Once a query enters phase 2, it assumes all its batches exist in the cache index. Today this is safe because memory eviction (squeeze) only *replaces* entries in the index (`MemoryArrow` → `DiskLiquid`) — it never removes them. But disk eviction must *remove* entries entirely, which would cause `index.get()` to return `None` mid-query.

### Concrete Example

```
Query 1: SELECT sum(revenue) FROM sales WHERE year = 2024
Query 2: SELECT count(*) FROM orders WHERE status = 'pending'

T1  Query 1 fills cache with batches B0–B3 (on disk, 400 MB used)
T2  Query 1 enters ReadFromCache, starts reading B0, B1...
T3  Query 2 starts filling cache, disk hits 500 MB limit
T4  Disk eviction removes B2 (Query 1 hasn't read it yet)
T5  Query 1 tries to read B2 → index.get() returns None → 💥
```

### Code Path

- `LiquidStream::poll_next` transitions to `ReadFromCache` state (`src/datafusion/src/reader/runtime/liquid_stream.rs:654`)
- `LiquidCacheReader` reads batches via `column.get_arrow_array_with_filter` (`src/datafusion/src/reader/runtime/liquid_cache_reader.rs:247`)
- Which calls `cache_store.get(&entry_id).read()` (`src/datafusion/src/cache/column.rs:184`)
- Which calls `index.get(entry_id)?` (`src/core/src/cache/core.rs:496`) — returns `None` if evicted

## Proposed Solution: Lease-Based Disk Eviction

### Core Idea

Before a query starts reading from cache, it acquires a **lease** on the entries it needs. Disk eviction skips leased entries. Leases are released automatically when the reader finishes (RAII via `Drop`).

The eviction policy still decides *what* to evict. The lease tracker decides *whether it's safe right now*. Clean separation.

### New Components

#### 1. `LeaseTracker` (new struct in `src/core/src/cache/lease.rs`)

A concurrent map of `EntryID → AtomicUsize` tracking how many active readers hold each entry.

```rust
#[derive(Debug, Default)]
pub struct LeaseTracker {
    counts: RwLock<AHashMap<EntryID, AtomicUsize>>,
}

impl LeaseTracker {
    /// Increment the reader count for an entry.
    pub fn acquire(&self, entry_id: &EntryID) { ... }

    /// Decrement the reader count for an entry.
    pub fn release(&self, entry_id: &EntryID) { ... }

    /// Returns true if any reader holds this entry.
    pub fn is_leased(&self, entry_id: &EntryID) -> bool { ... }
}
```

#### 2. `CacheLease` (RAII handle)

Held by a reader for its lifetime. Releases all entries on drop.

```rust
pub struct CacheLease {
    entries: Vec<EntryID>,
    tracker: Arc<LeaseTracker>,
}

impl Drop for CacheLease {
    fn drop(&mut self) {
        for entry_id in &self.entries {
            self.tracker.release(entry_id);
        }
    }
}
```

#### 3. Disk budget in `BudgetAccounting` (`src/core/src/cache/budget.rs`)

Mirror the existing memory budget with `max_disk_bytes`, watermark thresholds, and `try_reserve_disk`:

```rust
pub struct BudgetAccounting {
    max_memory_bytes: usize,
    used_memory_bytes: AtomicUsize,
    max_disk_bytes: usize,              // new
    low_watermark_bytes: usize,         // new — e.g. 70% of max_disk_bytes
    high_watermark_bytes: usize,        // new — e.g. 90% of max_disk_bytes
    used_disk_bytes: AtomicUsize,
}

impl BudgetAccounting {
    pub fn try_reserve_disk(&self, bytes: usize) -> Result<(), ()> { ... }
    pub fn sub_used_disk_bytes(&self, bytes: usize) { ... }
    pub fn above_low_watermark(&self) -> bool { ... }
    pub fn above_high_watermark(&self) -> bool { ... }
    pub fn low_watermark_bytes(&self) -> usize { ... }
}
```

### Modified Components

#### 4. `LiquidCache` struct (`src/core/src/cache/core.rs`)

Add `lease_tracker` field:

```rust
pub struct LiquidCache {
    index: ArtIndex,
    config: CacheConfig,
    budget: BudgetAccounting,
    cache_policy: Box<dyn CachePolicy>,
    hydration_policy: Box<dyn HydrationPolicy>,
    squeeze_policy: Box<dyn SqueezePolicy>,
    observer: Arc<Observer>,
    io_context: Arc<dyn IoContext>,
    lease_tracker: Arc<LeaseTracker>,  // new
}
```

#### 5. `LiquidCacheReader` (`src/datafusion/src/reader/runtime/liquid_cache_reader.rs`)

Acquire lease on construction, release on drop:

```rust
pub(crate) struct LiquidCacheReader {
    state: ReaderState,
    row_filter: Option<LiquidRowFilter>,
    _lease: CacheLease,  // new — held for reader's lifetime
}

impl LiquidCacheReader {
    pub(crate) fn new(...) -> Self {
        // Compute all (column, batch) EntryIDs this reader will access
        let entry_ids = compute_entry_ids(&selection, batch_size, &cached_row_group, &projection_columns);
        let lease = CacheLease::acquire(cached_row_group.lease_tracker(), entry_ids);
        // ... rest unchanged ...
        Self { state, row_filter, _lease: lease }
    }
}
```

#### 6. Watermark-Based Disk Eviction (`src/core/src/cache/core.rs`)

Disk eviction uses a two-watermark system to avoid a hard cliff between "fully cached" and "reading raw Parquet":

- **Low watermark (soft threshold, e.g. 70%):** A background task starts evicting unleased entries best-effort. Queries keep caching normally. Goal: proactively make room before it's urgent.
- **High watermark (hard threshold, e.g. 90%):** Eviction runs inline during `write_batch_to_disk`. If we still can't free enough (everything leased), new inserts skip caching and fall back to direct Parquet reads.

```rust
/// Background eviction — triggered when disk usage crosses the low watermark.
/// Runs periodically, evicts unleased entries best-effort.
async fn background_evict_to_low_watermark(&self) {
    let target = self.budget.low_watermark_bytes();
    while self.budget.disk_usage_bytes() > target {
        let candidates = self.cache_policy.find_disk_victims(8);
        if candidates.is_empty() {
            break;
        }
        for victim in candidates {
            if self.lease_tracker.is_leased(&victim) {
                continue; // active reader — skip
            }
            self.index.remove(&victim);
            self.io_context.delete(&victim).await;
            self.budget.sub_used_disk_bytes(size);
        }
    }
}

/// Inline eviction — triggered when disk usage crosses the high watermark
/// during write_batch_to_disk. Blocks until space is freed or gives up.
async fn inline_evict_for_write(&self, needed_bytes: usize) -> bool {
    let mut freed = 0;
    while freed < needed_bytes {
        let candidates = self.cache_policy.find_disk_victims(8);
        if candidates.is_empty() {
            break;
        }
        for victim in candidates {
            if self.lease_tracker.is_leased(&victim) {
                continue;
            }
            self.index.remove(&victim);
            self.io_context.delete(&victim).await;
            self.budget.sub_used_disk_bytes(size);
            freed += size;
        }
    }
    freed >= needed_bytes // false = caller should skip caching
}
```

#### 7. `CachePolicy` trait (`src/core/src/cache/policies/cache/mod.rs`)

Add method for disk victim selection:

```rust
pub trait CachePolicy: std::fmt::Debug + Send + Sync {
    fn find_victim(&self, cnt: usize) -> Vec<EntryID>;              // existing (memory)
    fn find_disk_victims(&self, cnt: usize) -> Vec<EntryID> { vec![] } // new (disk)
    fn notify_insert(&self, ...) {}
    fn notify_access(&self, ...) {}
}
```

#### 8. `IoContext` trait (`src/core/src/cache/io_context.rs`)

Add delete capability:

```rust
pub trait IoContext: Debug + Send + Sync {
    async fn read(&self, ...) -> Result<Bytes, std::io::Error>;
    async fn write(&self, ...) -> Result<(), std::io::Error>;
    async fn delete(&self, entry_id: &EntryID) -> Result<usize, std::io::Error>; // new — returns freed bytes
}
```

### Flow Comparison

```
                Memory eviction (today)       Disk eviction (proposed)
                ───────────────────────       ──────────────────────────
Trigger         memory budget full            low watermark: background
                                              high watermark: inline
Who decides     cache_policy.find_victim      cache_policy.find_disk_victims
Lease check     not needed                    REQUIRED
What happens    entry squeezed, replaced      entry REMOVED from index,
                in index (still findable)     DELETED from t4::Store
Entry after     DiskLiquid (still in index)   gone entirely
```

### Edge Cases

**All disk entries are leased (everything in use)**
Eviction can't free anything. At high watermark, the inserting query skips caching this batch and reads directly from Parquet. At low watermark, the background task simply stops and retries later. Correctness over space efficiency.

**Disk usage between low and high watermark**
Background eviction is running but queries cache normally. This is the steady-state under moderate load — the system is proactively cleaning up without impacting query performance.

**Long-running query holds leases for a long time**
This delays eviction of those entries. Acceptable trade-off. A future enhancement could add lease timeouts or warnings for abnormally long-held leases.

**Query errors or panics mid-read**
`CacheLease` uses `Drop`, so leases are released even on panic unwind. No leaked leases.

### Implementation Order

1. `LeaseTracker` + `CacheLease` (pure addition, no behavior change)
2. Disk budget tracking in `BudgetAccounting` (add `max_disk_bytes`, `try_reserve_disk`)
3. `IoContext::delete` (add to trait + `DefaultIoContext` impl)
4. `CachePolicy::find_disk_victims` (add to trait, implement in policies)
5. Wire lease acquire/release into `LiquidCacheReader`
6. Disk eviction loop in `LiquidCache`
7. `ArtIndex::remove` method

Steps 1–4 are additive and can be reviewed independently. Steps 5–7 are the behavioral change.

### Open Questions

1. **Lease granularity**: Per-entry (proposed) vs per-row-group? Per-entry is more flexible but has more overhead. Per-row-group is simpler but blocks eviction of entries that aren't actually being read.

2. **Disk victim selection policy**: Should `find_disk_victims` reuse the same LRU/SIEVE/etc. logic as memory victims, or use a separate policy? Disk entries are cold by definition (already evicted from memory), so the access pattern may differ.

3. **Watermark defaults**: What are sensible defaults for low/high watermarks? 70%/90%? Should they be user-configurable from the start?

4. **Background task frequency**: How often should the background eviction task check disk usage? Timer-based (e.g. every 5s), or event-driven (triggered when a write crosses the low watermark)?
