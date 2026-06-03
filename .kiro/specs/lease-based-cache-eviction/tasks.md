# Tasks: Lease-Based Cache Eviction

## Task 1: Implement LeaseTracker and CacheLease

- [x] 1.1 Create `src/core/src/cache/lease.rs` with `LeaseTracker` struct using `RwLock<AHashMap<EntryID, AtomicUsize>>`, implementing `new()`, `acquire()`, `release()`, `is_leased()`, and `lease_count()` methods
- [ ] 1.2 Implement `CacheLease` struct with `acquire()` constructor, `entries()`, `len()`, `is_empty()` accessors, and `Drop` implementation that releases all entries
- [ ] 1.3 Register the `lease` module in `src/core/src/cache/mod.rs` and add public exports for `LeaseTracker` and `CacheLease`
- [ ] 1.4 Write unit tests for LeaseTracker: acquire increments count, release decrements count, zero-count cleanup removes entry, is_leased correctness, multiple acquires on same entry
- [ ] 1.5 Write unit tests for CacheLease: RAII release on drop, empty lease, panic safety via catch_unwind
- [ ] 1.6 Write concurrent test for LeaseTracker: multiple threads acquiring/releasing overlapping entries, verify final counts are consistent (include shuttle variant)

## Task 2: Integrate LeaseTracker into LiquidCache

- [ ] 2.1 Add `lease_tracker: Arc<LeaseTracker>` field to `LiquidCache` struct in `src/core/src/cache/core.rs`, initialize in `LiquidCache::new()`, and add `pub fn lease_tracker(&self) -> &Arc<LeaseTracker>` accessor
- [ ] 2.2 Add `pub fn lease_tracker(&self) -> &Arc<LeaseTracker>` method to `CachedRowGroup` in `src/datafusion/src/cache/mod.rs` that delegates to `self.cache_store.lease_tracker()`

## Task 3: Wire leases into LiquidCacheReader

- [ ] 3.1 Add a helper function to compute lease entry IDs from (selection, batch_size, row_count, cached_row_group, projection_columns) — this produces the Cartesian product of (selected batches × columns) as EntryIDs
- [ ] 3.2 Modify `LiquidCacheReader` to accept and store a `CacheLease` field (`_lease: CacheLease`), acquired during construction using the computed entry IDs
- [ ] 3.3 Update `LiquidStream` to pass the `CachedRowGroup` (which provides access to `lease_tracker()`) through to `LiquidCacheReader::new()` so it can acquire leases
- [ ] 3.4 Write tests verifying that LiquidCacheReader acquires leases on construction and releases them on drop, including early-drop scenario

## Task 4: Verify build and existing tests

- [ ] 4.1 Run `cargo check` to verify the full workspace compiles without errors
- [ ] 4.2 Run existing tests in `src/core` and `src/datafusion` to verify no regressions
