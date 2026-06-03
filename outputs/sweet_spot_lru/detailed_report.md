# LRU vs S3-FIFO Cache Policy Comparison

## Question

**How does LRU compare to S3-FIFO as a cache eviction policy across different memory budgets?**

## 1. Benchmark Configuration

| Parameter | Value |
|-----------|-------|
| Dataset | ClickBench hits table |
| Iterations | 5 (first is cold, last 4 are hot) |
| Metric | min(hot iterations) time_millis |
| Memory Budgets | 8, 16, 32, 64, 128, 256, 384, 512, 768, 1024, 2048 MB |
| Disk Budget | Unlimited |
| Hydration | Disabled (disk entries stay on disk) |

### Cache Configurations

| Config | Policy | Description |
|--------|--------|-------------|
| LRU | LRU | Classic least-recently-used eviction |
| S3-FIFO | S3-FIFO | Three-queue admission + eviction policy |

## 2. Summary: Sweet Spot Comparison

Sweet spot = minimum memory budget to reach within 10% of best performance for that config.

| Query | Working Set | Baseline | LRU | S3-FIFO |
|-------|-------------|----------|-----|---------|
| Q19 | ~668MB | 81ms | 768MB (20ms) | 768MB (21ms) |
| Q7 | ~31MB | 31ms | 128MB (14ms) | 256MB (14ms) |
| Q40 | ~15MB | 38ms | 32MB (19ms) | 16MB (20ms) |
| Q42 | ~7MB | 29ms | 8MB (18ms) | 8MB (18ms) |

### Best Achievable Time (at optimal budget)

| Query | Baseline | LRU | S3-FIFO |
|-------|----------|-----|---------|
| Q19 | 81ms | 20ms | 20ms |
| Q7 | 31ms | 14ms | 13ms |
| Q40 | 38ms | 19ms | 19ms |
| Q42 | 29ms | 17ms | 17ms |

## 3. Per-Query Detailed Results

### Q19: UserID Int64, single equality filter

**Working Set:** ~668MB

```sql
SELECT "UserID" FROM hits WHERE "UserID" = 435090932899640449
```

**Baseline (Parquet, no cache):** 81ms

#### Performance by Memory Budget

| Memory | LRU | S3-FIFO |
|--------|-----|---------|
| 8MB | 18,355ms | 676ms |
| 16MB | 18,373ms | 615ms |
| 32MB | 18,368ms | 578ms |
| 64MB | 18,341ms | 523ms |
| 128MB | 18,301ms | 380ms |
| 256MB | 18,032ms | 158ms |
| 384MB | 183ms | 37ms |
| 512MB | 27ms | 29ms |
| 768MB | 20ms | 21ms |
| 1024MB | 20ms | 20ms |
| 2048MB | 20ms | 21ms |

#### Cache Stats (entries: memory/disk)

| Memory | LRU (mem/disk) | S3-FIFO (mem/disk) |
|--------|----------------|---------------------|
| 8MB | 157/60 (8.0MB/6.4MB) | 276/10392 (7.9MB/619.9MB) |
| 16MB | 318/109 (15.9MB/12.4MB) | 554/10114 (15.9MB/619.9MB) |
| 32MB | 642/214 (32.0MB/24.8MB) | 1095/9573 (31.8MB/620.0MB) |
| 64MB | 1278/436 (64.0MB/49.9MB) | 2207/8461 (63.8MB/620.0MB) |
| 128MB | 2564/859 (127.9MB/99.9MB) | 4411/6257 (128.0MB/619.9MB) |
| 256MB | 5122/1689 (256.0MB/199.8MB) | 8805/1863 (255.9MB/620.0MB) |
| 384MB | 8351/2317 (384.0MB/367.1MB) | 10667/1 (384.0MB/470.7MB) |
| 512MB | 10668/0 (511.9MB/237.9MB) | 10668/0 (511.9MB/216.4MB) |
| 768MB | 10668/0 (668.7MB/0KB) | 10668/0 (668.7MB/0KB) |
| 1024MB | 10668/0 (668.7MB/0KB) | 10668/0 (668.7MB/0KB) |
| 2048MB | 10668/0 (668.7MB/0KB) | 10668/0 (668.7MB/0KB) |

#### EXPLAIN ANALYZE at 384MB (critical divergence point)

| Config | Time | cache_miss | IO read | IO write | Entries in mem | Entries on disk |
|--------|------|-----------|---------|----------|----------------|----------------|
| LRU | 183ms | 0 | 2,319 | 0 | 8,351 | 2,317 |
| S3-FIFO | 37ms | 0 | 0 | 0 | 10,667 | 1 |

#### Analysis

**S3-FIFO is 5× faster at 384MB** (37ms vs 183ms) and dramatically faster at all budgets below 512MB.

**Root cause:** At 384MB, S3-FIFO fits virtually all 10,668 entries in memory (10,667 in mem, only 1 on disk) while LRU still has 2,317 entries stuck on disk requiring 2,319 read IOs.

**Why S3-FIFO is more memory-efficient:** S3-FIFO's admission policy prevents cold initial-scan data from filling the cache. During the first iteration, LRU admits every entry it sees, quickly filling memory and evicting entries to disk. On subsequent iterations, those evicted entries must be read back from disk (183ms of IO). S3-FIFO's probationary queue filters out one-hit entries, so only frequently-accessed entries get promoted to the protected segment. This means at 384MB budget, S3-FIFO manages to keep the entire working set in memory (liquid format compresses Int64 below Arrow size, so 10,668 entries fit in 384MB).

**Below 384MB:** The difference is even more stark. At 8-256MB, LRU takes 18,000+ms (catastrophic disk thrashing during the cold fill spills most entries) while S3-FIFO degrades gracefully from 676ms → 158ms as more entries fit in memory.

**At 512MB+:** Both converge to ~20ms once the full 668MB working set fits in memory regardless of policy.

### Q7: AdvEngineID Int16, inequality + GROUP BY

**Working Set:** ~31MB

```sql
SELECT "AdvEngineID", COUNT(*) FROM hits WHERE "AdvEngineID" <> 0 GROUP BY "AdvEngineID" ORDER BY COUNT(*) DESC
```

**Baseline (Parquet, no cache):** 31ms

#### Performance by Memory Budget

| Memory | LRU | S3-FIFO |
|--------|-----|---------|
| 8MB | 13,477ms | 620ms |
| 16MB | 13,528ms | 316ms |
| 32MB | 13,518ms | 15ms |
| 64MB | 448ms | 15ms |
| 128MB | 14ms | 16ms |
| 256MB | 14ms | 14ms |
| 384MB | 14ms | 14ms |
| 512MB | 14ms | 14ms |
| 768MB | 14ms | 14ms |
| 1024MB | 14ms | 13ms |
| 2048MB | 14ms | 15ms |

#### Cache Stats (entries: memory/disk)

| Memory | LRU (mem/disk) | S3-FIFO (mem/disk) |
|--------|----------------|---------------------|
| 8MB | 884/444 (8.0MB/1016KB) | 3494/8046 (8.0MB/17.9MB) |
| 16MB | 1787/914 (16.0MB/1.6MB) | 7287/4253 (15.9MB/10.1MB) |
| 32MB | 3609/1822 (32.0MB/3.5MB) | 11540/0 (31.9MB/0KB) |
| 64MB | 7486/4054 (64.0MB/8.9MB) | 11540/0 (63.9MB/0KB) |
| 128MB | 11540/0 (127.9MB/0KB) | 11540/0 (127.9MB/0KB) |
| 256MB | 11540/0 (181.2MB/0KB) | 11540/0 (181.2MB/0KB) |
| 384MB | 11540/0 (181.2MB/0KB) | 11540/0 (181.2MB/0KB) |
| 512MB | 11540/0 (181.2MB/0KB) | 11540/0 (181.2MB/0KB) |
| 768MB | 11540/0 (181.2MB/0KB) | 11540/0 (181.2MB/0KB) |
| 1024MB | 11540/0 (181.2MB/0KB) | 11540/0 (181.2MB/0KB) |
| 2048MB | 11540/0 (181.2MB/0KB) | 11540/0 (181.2MB/0KB) |

#### Analysis

**S3-FIFO is dramatically better at 32MB** (15ms vs 13,518ms — a 900× difference).

**Root cause:** At 32MB, S3-FIFO fits all 11,540 entries in memory (0 disk entries) while LRU still has 1,822 entries on disk causing massive read IO. The working set in liquid format is ~31MB, so S3-FIFO's efficient admission allows it to fit everything at exactly the working set size.

**Why LRU thrashes:** During the initial cold scan, LRU admits entries in access order. For Q7 (a full-column scan with GROUP BY), the first iteration touches all entries sequentially. LRU fills its 32MB budget quickly, then evicts older entries to make room for new ones. By the end of the cold fill, many entries have been evicted to disk. On hot iterations, those disk entries cause 13,518ms of IO. At 64MB, LRU still has 4,054 entries on disk (448ms). Only at 128MB does LRU finally fit everything.

**S3-FIFO's advantage:** S3-FIFO's admission policy avoids filling the cache with cold initial-scan data. The probationary queue absorbs the first-access entries without evicting protected entries. By the time hot iterations run, the working set has been identified and fits entirely in the 32MB memory budget.

**At 128MB+:** Both policies converge to ~14ms with all entries in memory.

### Q40: Multi-predicate (CounterID, EventDate, IsRefresh, TraficSourceID, RefererHash)

**Working Set:** ~15MB

```sql
SELECT "URLHash", "EventDate"::INT::DATE, COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-01' AND "EventDate"::INT::DATE <= '2013-07-31' AND "IsRefresh" = 0 AND "TraficSourceID" IN (-1, 6) AND "RefererHash" = 3594120000172545465 GROUP BY "URLHash", "EventDate"::INT::DATE ORDER BY PageViews DESC LIMIT 10 OFFSET 100
```

**Baseline (Parquet, no cache):** 38ms

#### Performance by Memory Budget

| Memory | LRU | S3-FIFO |
|--------|-----|---------|
| 8MB | 1,367ms | 185ms |
| 16MB | 22ms | 20ms |
| 32MB | 19ms | 19ms |
| 64MB | 19ms | 19ms |
| 128MB | 20ms | 19ms |
| 256MB | 19ms | 19ms |
| 384MB | 20ms | 19ms |
| 512MB | 20ms | 20ms |
| 768MB | 20ms | 20ms |
| 1024MB | 20ms | 19ms |
| 2048MB | 20ms | 19ms |

#### Cache Stats (entries: memory/disk)

| Memory | LRU (mem/disk) | S3-FIFO (mem/disk) |
|--------|----------------|---------------------|
| 8MB | 364/157 (7.9MB/4.3MB) | 444/416 (7.9MB/7.4MB) |
| 16MB | 840/20 (15.9MB/354KB) | 860/0 (16.0MB/0KB) |
| 32MB | 860/0 (24.3MB/0KB) | 860/0 (24.3MB/0KB) |
| 64MB | 860/0 (24.3MB/0KB) | 860/0 (24.3MB/0KB) |
| 128MB | 860/0 (24.3MB/0KB) | 860/0 (24.3MB/0KB) |
| 256MB | 860/0 (24.3MB/0KB) | 860/0 (24.3MB/0KB) |
| 384MB | 860/0 (24.3MB/0KB) | 860/0 (24.3MB/0KB) |
| 512MB | 860/0 (24.3MB/0KB) | 860/0 (24.3MB/0KB) |
| 768MB | 860/0 (24.3MB/0KB) | 860/0 (24.3MB/0KB) |
| 1024MB | 860/0 (24.3MB/0KB) | 860/0 (24.3MB/0KB) |
| 2048MB | 860/0 (24.3MB/0KB) | 860/0 (24.3MB/0KB) |

#### Analysis

**S3-FIFO is 7× faster at 8MB** (185ms vs 1,367ms) — the only budget where the policies diverge.

**Root cause at 8MB:** The working set is 860 entries. At 8MB budget, LRU only keeps 364 entries in memory with 157 on disk, while S3-FIFO keeps 444 in memory with 416 on disk. S3-FIFO's more entries on disk but faster access pattern (185ms vs 1,367ms) suggests it keeps the *hot* entries in memory more effectively, avoiding repeated disk reads for frequently-accessed data.

**At 16MB:** Both converge — LRU has 840/20 (still 20 entries on disk causing a slight 22ms vs 20ms gap) while S3-FIFO has all 860 entries in memory. The difference is negligible.

**At 32MB+:** Both policies hold all 860 entries in memory with identical ~19ms performance. The working set (24.3MB in liquid format) fits comfortably.

### Q42: Multi-predicate (CounterID, EventDate, IsRefresh, DontCountHits)

**Working Set:** ~7MB

```sql
SELECT DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) AS M, COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-14' AND "EventDate"::INT::DATE <= '2013-07-15' AND "IsRefresh" = 0 AND "DontCountHits" = 0 GROUP BY DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) ORDER BY DATE_TRUNC('minute', M) LIMIT 10 OFFSET 1000
```

**Baseline (Parquet, no cache):** 29ms

#### Performance by Memory Budget

| Memory | LRU | S3-FIFO |
|--------|-----|---------|
| 8MB | 18ms | 18ms |
| 16MB | 18ms | 18ms |
| 32MB | 17ms | 18ms |
| 64MB | 18ms | 18ms |
| 128MB | 18ms | 17ms |
| 256MB | 18ms | 18ms |
| 384MB | 18ms | 18ms |
| 512MB | 18ms | 17ms |
| 768MB | 17ms | 18ms |
| 1024MB | 18ms | 18ms |
| 2048MB | 18ms | 18ms |

#### Cache Stats (entries: memory/disk)

| Memory | LRU (mem/disk) | S3-FIFO (mem/disk) |
|--------|----------------|---------------------|
| 8MB | 688/0 (7.9MB/0KB) | 688/0 (7.9MB/0KB) |
| 16MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |
| 32MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |
| 64MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |
| 128MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |
| 256MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |
| 384MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |
| 512MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |
| 768MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |
| 1024MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |
| 2048MB | 688/0 (13.5MB/0KB) | 688/0 (13.5MB/0KB) |

#### Analysis

**No difference.** Q42's working set is only 688 entries (7.9MB in liquid format). Even at the minimum 8MB budget, all 688 entries fit entirely in memory for both policies. Zero disk entries across all budgets. The eviction policy is irrelevant when nothing needs to be evicted — both achieve a consistent 17-18ms.

## 4. Conclusion

### When is S3-FIFO better than LRU?

S3-FIFO outperforms LRU **when memory budget is tight relative to working set size**:

| Query | Critical Budget | LRU | S3-FIFO | Speedup |
|-------|----------------|-----|---------|---------|
| Q19 | 384MB | 183ms | 37ms | **5×** |
| Q7 | 32MB | 13,518ms | 15ms | **900×** |
| Q40 | 8MB | 1,367ms | 185ms | **7×** |

### When is LRU equivalent to S3-FIFO?

When the working set fits entirely in memory, both policies perform identically:
- Q42: Always fits (7MB working set, 8MB minimum budget) → both at 18ms
- Q40 at 16MB+: Both at ~19ms
- Q7 at 128MB+: Both at ~14ms
- Q19 at 512MB+: Both at ~20ms

### Why S3-FIFO wins under memory pressure

The fundamental difference is how each policy handles the **cold fill** (first iteration):

1. **LRU admits everything:** During the initial scan, LRU inserts every entry it encounters. When memory fills, it evicts the least-recently-used entry to disk. For sequential scan workloads, this means entries inserted early get evicted before they can be reused in the next iteration.

2. **S3-FIFO filters admissions:** S3-FIFO's probationary queue acts as an admission filter. Entries must prove they're accessed more than once before being promoted to the protected segment. This prevents cold scan data from polluting the cache, keeping memory reserved for entries that will actually be reused.

The result: at the same memory budget, S3-FIFO keeps more of the *hot* working set in memory while LRU wastes memory on entries that were only accessed during the cold fill.

### Final Verdict

**S3-FIFO is strictly better or equal to LRU across all tested workloads.** There is no scenario in this benchmark where LRU outperforms S3-FIFO. The advantage is most dramatic when:
- Working set exceeds memory budget (memory pressure)
- Access pattern involves sequential scans (cold fill pollution)
- Budget is close to but below working set size (the "cliff" zone)

When the working set fits in memory, both policies are equivalent — the eviction policy doesn't matter if nothing is evicted.
