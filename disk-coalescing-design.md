# Column-Level Disk Coalescing Design

## Problem

When memory budget < compressed working set, entries spill to disk as individual batches (8192 rows each). Reading them back requires thousands of random IO operations through the t4 key-value store, making disk-spill queries 10-40× slower than reading from Parquet directly.

**Example:** Q19 at 256MB budget → 1,857 individual disk reads → 682ms vs 85ms Parquet baseline.

## Proposed Solution

Store all batches of a column within a row group as a single contiguous disk entry. On read, fetch the entire column chunk in one IO operation and split into individual batch arrays.

## Current Architecture

```
EntryID = (file_id: u16, row_group_id: u16, column_id: u16, batch_id: u16) → usize

Index: CongeeArc<EntryID, Arc<CacheEntry>>
  - Each batch is one entry
  - 10,668 entries for Q19 (202 RGs × 53 batches × 1 column)

Disk key: entry_id_to_key(EntryID) → T4Key
  - One t4 key per batch
  - One disk read per batch on access
```

## Proposed Architecture

### Option A: Column-level disk key with batch-level memory index

Keep batch-level `EntryID` for memory. Add a column-level `DiskGroupID` for disk writes/reads.

```rust
/// Groups all batches of a column in a row group for disk IO.
struct DiskGroupID {
    file_id: u16,
    row_group_id: u16,
    column_id: u16,
}

/// Individual batch entries stay the same in memory
struct EntryID { file_id, row_group_id, column_id, batch_id }
```

### Changes Required

#### 1. `src/core/src/cache/core.rs`

**New method: `write_column_to_disk`**
```rust
/// When squeezing a column to disk, collect ALL batches for that column
/// in this row group, concatenate their bytes, write as one t4 entry.
async fn write_column_to_disk(&self, disk_group: DiskGroupID, batch_entries: &[EntryID]) {
    let mut combined_bytes = Vec::new();
    let mut offsets = Vec::new(); // byte offset of each batch within combined

    for entry_id in batch_entries {
        let batch = self.index.get(entry_id)?;
        let bytes = match batch.as_ref() {
            CacheEntry::MemoryLiquid(arr) => arr.to_bytes(),
            CacheEntry::MemoryArrow(arr) => arrow_to_bytes(arr),
            _ => continue,
        };
        offsets.push(combined_bytes.len() as u32);
        combined_bytes.extend_from_slice(&bytes);
    }

    // Write header (offsets) + data as single entry
    let disk_key = disk_group_to_key(&disk_group);
    let payload = encode_coalesced_entry(&offsets, &combined_bytes);
    self.store.put(disk_key, payload).await?;
}
```

**New method: `read_column_from_disk`**
```rust
/// Read all batches for a column in one IO, split into individual arrays.
async fn read_column_from_disk(&self, disk_group: DiskGroupID) -> Vec<(EntryID, LiquidArrayRef)> {
    let disk_key = disk_group_to_key(&disk_group);
    let payload = self.store.get(&disk_key).await?; // ONE IO operation
    decode_coalesced_entry(&payload) // split by offsets
}
```

#### 2. `src/core/src/cache/policies/squeeze.rs`

**Modify `TranscodeSqueezeEvict`:**

When a batch is selected for disk eviction, don't write it individually. Instead, mark it as "pending disk write" and wait until ALL batches for that column+row_group are ready, then coalesce.

Alternative: Keep individual squeeze decisions but change the write path to append to an existing column-level disk entry.

#### 3. `src/core/src/cache/cached_batch.rs`

**New variant or modified DiskLiquid:**
```rust
CacheEntry::DiskCoalesced {
    data_type: DataType,
    disk_group: DiskGroupID,
    batch_index: u16,      // which batch within the coalesced blob
    total_batches: u16,    // how many batches in this group
    group_disk_bytes: usize, // total size on disk
}
```

#### 4. `src/core/src/cache/core.rs` — `read_disk_liquid_array` modification

```rust
async fn read_disk_liquid_array(&self, entry_id: &EntryID) -> LiquidArrayRef {
    let batch = self.index.get(entry_id)?;
    match batch.as_ref() {
        CacheEntry::DiskCoalesced { disk_group, batch_index, .. } => {
            // Check if column group is already cached in a local buffer
            let arrays = self.read_column_from_disk(*disk_group).await;
            // Optionally hydrate ALL batches back to memory
            arrays[*batch_index as usize]
        }
        CacheEntry::DiskLiquid { .. } => {
            // Legacy per-batch path (backwards compat)
            self.store.get(&entry_id_to_key(entry_id)).await
        }
    }
}
```

#### 5. Eviction changes

The cache policy's `find_memory_victim` returns individual batch `EntryID`s. The squeeze path needs to detect when it's evicting batches from the same column and coalesce the disk write:

```rust
async fn squeeze_victims(&self, victims: Vec<EntryID>) -> Result<(), CacheFull> {
    // Group victims by (file, rg, col)
    let groups: HashMap<DiskGroupID, Vec<EntryID>> = group_by_column(victims);

    for (disk_group, batch_entries) in groups {
        // Check if ALL batches for this column are being evicted
        if batch_entries.len() == expected_batch_count {
            self.write_column_to_disk(disk_group, &batch_entries).await?;
            // Update index: each batch → DiskCoalesced
        } else {
            // Partial eviction: write individually (or buffer until full)
            for entry in batch_entries {
                self.squeeze_victim_inner(entry).await?;
            }
        }
    }
}
```

## Expected Performance

| Metric | Current (per-batch) | Proposed (per-column) |
|--------|--------------------|-----------------------|
| IO operations for Q19 @ 256MB | 1,857 | ~35 (1 per column per spilled RG) |
| Expected latency at 16K IOPS | 682ms | 35/16000 = 2ms + read time |
| Total read volume | 117MB | 117MB (same data, fewer ops) |
| Expected hot time @ 256MB | ~680ms | ~80-120ms |

## Risks and Trade-offs

1. **Partial eviction complexity** — What if only 30/53 batches of a column are evicted? Need to handle mixed states.
2. **Read amplification** — Reading one batch requires fetching the entire column group. Acceptable because predicates always scan all batches anyway.
3. **Write amplification** — If batches are evicted one at a time (S3-FIFO picks individuals), must buffer writes until a full column group is ready.
4. **Memory during read** — Reading a 3MB coalesced entry temporarily requires 3MB of extra memory. Acceptable.
5. **Backwards compatibility** — Existing `DiskLiquid`/`DiskArrow` entries need to coexist with new `DiskCoalesced` entries during transition.

## Implementation Order

1. Add `DiskGroupID` type and key conversion
2. Add `DiskCoalesced` variant to `CacheEntry`
3. Implement `write_column_to_disk` / `read_column_from_disk`
4. Modify `squeeze_victims` to group by column before writing
5. Modify `eval_predicate_internal` / `read_disk_liquid_array` to use coalesced reads
6. Add tests
7. Benchmark

## Files to Modify

- `src/core/src/cache/utils.rs` — new DiskGroupID type
- `src/core/src/cache/cached_batch.rs` — new CacheEntry variant
- `src/core/src/cache/core.rs` — coalesced read/write methods, modified squeeze
- `src/core/src/cache/budget.rs` — disk budget tracking per group
- `src/core/src/cache/policies/squeeze.rs` — grouping logic before disk write
- `src/core/src/cache/index.rs` — possibly add column-group queries
