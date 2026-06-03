# Requirements: Lease-Based Cache Eviction

## Acceptance Criteria

### LeaseTracker Core Operations

- 1.1 Given a new LeaseTracker, when `acquire` is called with an EntryID, then `is_leased` returns true for that entry and `lease_count` returns 1.
- 1.2 Given a LeaseTracker with an active lease on entry E (count=N), when `acquire` is called again for E, then `lease_count` returns N+1.
- 1.3 Given a LeaseTracker with `lease_count(E) == N > 1`, when `release` is called for E, then `lease_count` returns N-1 and `is_leased` returns true.
- 1.4 Given a LeaseTracker with `lease_count(E) == 1`, when `release` is called for E, then `lease_count` returns 0, `is_leased` returns false, and the entry is removed from the internal map (zero-count cleanup).
- 1.5 Given a new LeaseTracker, when `is_leased` is called for an entry that was never acquired, then it returns false and `lease_count` returns 0.

### CacheLease RAII Behavior

- 2.1 Given a LeaseTracker and a list of EntryIDs, when `CacheLease::acquire` is called, then every entry in the list has its lease count incremented by 1.
- 2.2 Given a CacheLease holding entries [A, B, C], when the CacheLease is dropped, then the lease count for each of A, B, C is decremented by 1.
- 2.3 Given a CacheLease holding entries, when the owning scope panics, then the CacheLease's Drop implementation still runs and all entries are released (RAII panic safety).
- 2.4 Given an empty entry list, when `CacheLease::acquire` is called, then a valid CacheLease is returned with `len() == 0` and `is_empty() == true`, and no leases are acquired.

### Concurrent Access

- 3.1 Given multiple threads concurrently calling `acquire` and `release` on overlapping EntryIDs, when all threads complete, then the final lease count for each entry equals (total acquires - total releases) for that entry.
- 3.2 Given N threads each creating a CacheLease on the same entry and then dropping it, when all threads complete, then `is_leased` returns false for that entry.

### LiquidCache Integration

- 4.1 Given a LiquidCache instance, when `lease_tracker()` is called, then it returns an `Arc<LeaseTracker>` that is the same instance across multiple calls.
- 4.2 Given a CachedRowGroup, when `lease_tracker()` is called, then it returns the same `Arc<LeaseTracker>` as the underlying LiquidCache.

### LiquidCacheReader Lease Integration

- 5.1 Given a LiquidCacheReader constructed with a selection and projection columns, when the reader is created, then leases are acquired for all (column × batch) EntryIDs that the reader will access.
- 5.2 Given a LiquidCacheReader that has been fully consumed (all batches read), when the reader is dropped, then all leases acquired in 5.1 are released.
- 5.3 Given a LiquidCacheReader that is dropped before being fully consumed, then all leases acquired in 5.1 are still released (early drop safety).

### Entry ID Computation

- 6.1 Given a RowSelection, batch_size, row_count, and projection_columns, when computing lease entry IDs, then the result contains one EntryID for each (selected_batch, column) pair.
- 6.2 Given a RowSelection that selects no rows, when computing lease entry IDs, then the result is empty.
- 6.3 Given a RowSelection and projection_columns, the computed entry IDs contain no duplicates.
