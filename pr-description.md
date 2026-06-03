## Summary

Adds configurable disk size limits to LiquidCache with automatic eviction when the budget is exceeded, and a Parquet fallback reader so queries don't crash if a cache entry is evicted mid-read.

## Changes

### 1. Parquet Fallback Reader
When `ReadFromCache` encounters a missing entry (evicted from cache), it reads the batch directly from the source Parquet file instead of erroring. This makes the read path resilient to concurrent eviction.

### 2. Disk Eviction
Configurable `max_disk_bytes` with a watermark (default 0.9). When disk usage exceeds `max_disk_bytes * watermark`, entries are evicted via the cache policy's `find_disk_victims` (FIFO among disk entries for `LiquidPolicy`).

### 3. Configuration
```rust
LiquidCacheLocalBuilder::new()
    .with_max_disk_bytes(10 * 1024 * 1024 * 1024) // 10 GB
    .with_disk_watermark(0.9)                      // evict at 90%
    .build(config)
    .await?;
```

## How it works

| Disk usage | Behavior |
|---|---|
| Below watermark | Write normally, no eviction |
| Above watermark | Evict oldest disk entries until under budget, then write |
| Entry evicted mid-query | Fallback reader fetches from Parquet directly |

## Testing
- All existing tests pass
- Added unit tests for: `BudgetAccounting` disk tracking, `ArtIndex::remove`, `LiquidPolicy::find_disk_victims`, fallback reader with evicted batch
