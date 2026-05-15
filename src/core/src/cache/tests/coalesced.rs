//! Tests for column-level disk coalescing.

use arrow::array::Int32Array;

use crate::cache::{
    AlwaysHydrate, DiskGroupID, EntryID, LiquidCacheBuilder, LiquidPolicy,
    TranscodeSqueezeEvict,
    cached_batch::CacheEntry,
    utils::create_test_arrow_array,
};
use crate::sync::Arc;

/// Build entry IDs that share a DiskGroupID (same file=1, rg=2, col=3, varying batch).
fn make_entry_id(batch: u16) -> EntryID {
    // Layout: file_id(16) | rg_id(16) | col_id(16) | batch_id(16)
    let val: usize = (1usize << 48) | (2usize << 32) | (3usize << 16) | (batch as usize);
    EntryID::from(val)
}

#[test]
fn disk_group_id_from_entry_id_strips_batch() {
    let e0 = make_entry_id(0);
    let e1 = make_entry_id(1);
    let e99 = make_entry_id(99);

    let g0 = DiskGroupID::from_entry_id(e0);
    let g1 = DiskGroupID::from_entry_id(e1);
    let g99 = DiskGroupID::from_entry_id(e99);

    assert_eq!(g0, g1);
    assert_eq!(g1, g99);
    assert_eq!(g0.file_id(), 1);
    assert_eq!(g0.row_group_id(), 2);
    assert_eq!(g0.column_id(), 3);
}

#[tokio::test]
async fn squeeze_coalesces_same_column_entries() {
    // Create a cache small enough that inserting 4 entries forces squeeze.
    let test_array = create_test_arrow_array(128);
    let entry_size = test_array.get_array_memory_size();

    // Capacity for ~2 entries — inserting a 3rd triggers squeeze of 2 victims.
    let cache = LiquidCacheBuilder::new()
        .with_cache_policy(Box::new(LiquidPolicy::new()))
        .with_hydration_policy(Box::new(AlwaysHydrate::new()))
        .with_squeeze_policy(Box::new(TranscodeSqueezeEvict))
        .with_max_memory_bytes(entry_size * 2)
        .with_squeeze_victims_concurrently(false)
        .build()
        .await;

    // Insert 4 entries sharing the same column (same DiskGroupID).
    for batch in 0..4u16 {
        let entry_id = make_entry_id(batch);
        cache.insert(entry_id, test_array.clone()).await.unwrap();
    }

    // After squeeze, the evicted entries should be DiskCoalesced.
    let mut coalesced_count = 0;
    let mut memory_count = 0;
    for batch in 0..4u16 {
        let entry_id = make_entry_id(batch);
        if let Some(entry) = cache.index().get(&entry_id) {
            match entry.as_ref() {
                CacheEntry::DiskCoalesced {
                    disk_group,
                    batch_index,
                    total_batches,
                    ..
                } => {
                    assert_eq!(disk_group.file_id(), 1);
                    assert_eq!(disk_group.row_group_id(), 2);
                    assert_eq!(disk_group.column_id(), 3);
                    assert!(*batch_index < *total_batches);
                    coalesced_count += 1;
                }
                CacheEntry::MemoryArrow(_)
                | CacheEntry::MemoryLiquid(_)
                | CacheEntry::MemorySqueezedLiquid(_) => {
                    memory_count += 1;
                }
                _ => {}
            }
        }
    }

    // At least 2 entries must have been coalesced to disk.
    assert!(
        coalesced_count >= 2,
        "Expected at least 2 coalesced entries, got {coalesced_count}"
    );
}

#[tokio::test]
async fn coalesced_entries_are_readable() {
    let array: Arc<dyn arrow::array::Array> =
        Arc::new(Int32Array::from(vec![10, 20, 30, 40, 50, 60, 70, 80]));
    let entry_size = array.get_array_memory_size();

    // Capacity for ~2 entries.
    let cache = LiquidCacheBuilder::new()
        .with_cache_policy(Box::new(LiquidPolicy::new()))
        .with_hydration_policy(Box::new(AlwaysHydrate::new()))
        .with_squeeze_policy(Box::new(TranscodeSqueezeEvict))
        .with_max_memory_bytes(entry_size * 2)
        .with_squeeze_victims_concurrently(false)
        .build()
        .await;

    // Insert 4 entries with same column.
    for batch in 0..4u16 {
        let entry_id = make_entry_id(batch);
        cache.insert(entry_id, array.clone()).await.unwrap();
    }

    // Read them all back — coalesced reads should return the original data.
    for batch in 0..4u16 {
        let entry_id = make_entry_id(batch);
        let result = cache.get(&entry_id).read().await;
        assert!(
            result.is_some(),
            "Entry batch={batch} should be readable"
        );
        let read_array = result.unwrap();
        assert_eq!(read_array.len(), 8, "batch={batch} should have 8 elements");
    }
}

#[tokio::test]
async fn singleton_groups_use_per_batch_disk() {
    // When only 1 entry per DiskGroupID is squeezed, it uses the legacy per-batch path.
    let test_array = create_test_arrow_array(128);
    let entry_size = test_array.get_array_memory_size();

    let cache = LiquidCacheBuilder::new()
        .with_cache_policy(Box::new(LiquidPolicy::new()))
        .with_hydration_policy(Box::new(AlwaysHydrate::new()))
        .with_squeeze_policy(Box::new(TranscodeSqueezeEvict))
        .with_max_memory_bytes(entry_size * 2)
        .with_squeeze_victims_concurrently(false)
        .build()
        .await;

    // Insert entries with DIFFERENT columns (different DiskGroupIDs).
    let e1 = EntryID::from((1usize << 48) | (2usize << 32) | (3usize << 16) | 0); // col=3
    let e2 = EntryID::from((1usize << 48) | (2usize << 32) | (4usize << 16) | 0); // col=4
    let e3 = EntryID::from((1usize << 48) | (2usize << 32) | (5usize << 16) | 0); // col=5

    cache.insert(e1, test_array.clone()).await.unwrap();
    cache.insert(e2, test_array.clone()).await.unwrap();
    cache.insert(e3, test_array.clone()).await.unwrap();

    // Squeezed entries should be DiskLiquid (per-batch), not DiskCoalesced.
    let mut disk_liquid_count = 0;
    for entry_id in [e1, e2, e3] {
        if let Some(entry) = cache.index().get(&entry_id) {
            match entry.as_ref() {
                CacheEntry::DiskLiquid { .. } | CacheEntry::DiskArrow { .. } => {
                    disk_liquid_count += 1;
                }
                _ => {}
            }
        }
    }

    // At least 1 should be on disk via the per-batch path (not coalesced).
    assert!(
        disk_liquid_count >= 1,
        "Expected at least 1 per-batch disk entry, got {disk_liquid_count}"
    );
}
