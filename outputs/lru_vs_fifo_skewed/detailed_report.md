# LRU vs S3-FIFO: Skewed Multi-Query Experiment

## Question

**Does LRU's recency-based eviction help retain "hot" query entries when a "cold" query periodically pollutes the cache?**

## Experiment Design

| Parameter | Value |
|-----------|-------|
| HOT query | Q19: `SELECT "UserID" FROM hits WHERE "UserID" = 435090932899640449` |
| COLD query | Q7: `SELECT "AdvEngineID", COUNT(*) FROM hits WHERE "AdvEngineID" <> 0 GROUP BY "AdvEngineID" ORDER BY COUNT(*) DESC` |
| Sequence | Q19, Q19, Q19, Q7, Q19, Q19, Q19, Q7, Q19, Q19, Q19, Q7 (12 steps) |
| Memory budgets | 128, 256, 384, 512 MB (all below Q19's 668MB working set) |
| Disk budget | Unlimited |
| Hydration | Disabled |

**Working sets:**
- Q19: 668.7MB (10,668 entries — UserID column, all row groups)
- Q7: 181.2MB (11,540 entries — AdvEngineID column, all row groups)
- Combined: ~850MB

**Key measurement:** Latency of Q19 immediately after Q7 runs ("post-cold" at steps 4 and 8).

## Baselines

| Query | Parquet min hot | Liquid unlimited min hot | Working Set |
|-------|----------------|--------------------------|-------------|
| Q19 | 81ms | 20ms | 668.7MB |
| Q7 | 29ms | 14ms | 181.2MB |

## Results Summary

| Budget | LRU PostCold Q19 | S3-FIFO PostCold Q19 | Δ | LRU All Q19 avg | S3-FIFO All Q19 avg |
|--------|-------------------|----------------------|---|-----------------|---------------------|
| 128MB | 399ms | 378ms | -5% (noise) | 2377ms | 2349ms |
| 256MB | 139ms | 138ms | = | 2130ms | 2131ms |
| 384MB | 34ms | 37ms | = | 1554ms | 1573ms |
| 512MB | 28ms | 30ms | = | 744ms | 762ms |

## Per-Step Detail (384MB — most interesting budget)

| Step | Query | LRU | S3-FIFO | Note |
|------|-------|-----|---------|------|
| 0 | Q19 | 13,721ms | 13,876ms | Cold fill (both cache UserID) |
| 1 | Q19 | 35ms | 36ms | Warm (all UserID entries in cache) |
| 2 | Q19 | 35ms | 32ms | Warm |
| 3 | Q7 | 1,531ms | 1,534ms | Cold fill AdvEngineID → evicts some UserID |
| 4 | **Q19** | **34ms** | **37ms** | **Post-cold** ◀ |
| 5 | Q19 | 33ms | 37ms | |
| 6 | Q19 | 34ms | 34ms | |
| 7 | Q7 | 15ms | 15ms | Q7 now cached from step 3 |
| 8 | **Q19** | **34ms** | **36ms** | **Post-cold** ◀ |
| 9 | Q19 | 34ms | 35ms | |
| 10 | Q19 | 30ms | 34ms | |
| 11 | Q7 | 15ms | 17ms | |

## Analysis

### No meaningful difference between LRU and S3-FIFO

At every budget, the post-cold Q19 latency differs by ≤5ms (noise range). Both policies produce identical behavior:

- **128MB:** Both ~400ms post-cold. Budget holds only 128/668 = 19% of Q19's working set. Massive disk IO regardless of eviction ordering.
- **256MB:** Both ~138ms post-cold. Budget holds ~38% of working set.
- **384MB:** Both ~35ms post-cold. This is close to the unlimited baseline (20ms). The combined entries (10,668 + 11,540 = 22,208) fit at 384MB because Q7 and Q19 use different columns — they don't compete. Cache holds both working sets.
- **512MB:** Both ~29ms post-cold. Same as above, no eviction needed.

### Why it still doesn't differentiate

**At 384MB+:** The two queries cache *different columns* (UserID vs AdvEngineID). They occupy different entries that coexist in memory without evicting each other. Total = 668.7 + 181.2 = 850MB, but after squeezing/liquid compression, both fit in 384MB (22,208 entries at 384MB). The post-cold Q19 stays fast because Q7 doesn't evict Q19's entries.

**At 128-256MB:** Q19's entries get evicted during Q19's own cold fill (step 0 takes 18,000ms). After step 0, Q19 reads from disk on every subsequent run regardless of Q7's interference. The high latency (400ms at 128MB, 139ms at 256MB) comes from reading Q19's own disk-spilled entries — Q7 adds only marginal additional pressure.

### Fundamental insight

The LRU vs FIFO ordering difference requires entries within **the same queue** to have different value to the workload. In this experiment:

1. **Different columns → different entries → no competition at 384MB+**
2. **Same column entries are all equally valuable** — for Q19, every UserID entry is accessed exactly once per query execution in sequential order

For LRU to outperform FIFO, we'd need a workload where within a single column's entries, some are accessed multiple times per query (e.g., hash-join probes, index lookups) while others are accessed once. ClickBench's columnar scan patterns don't create this.

## Conclusion

**LRU and S3-FIFO remain equivalent** even under multi-query cache pollution. The 4-queue type-aware eviction priority determines behavior; within-queue ordering (recency vs arrival) is irrelevant because:

1. Different queries cache different columns → entries don't compete when budget is sufficient
2. Same-column entries are uniformly accessed in sequential scans → no "hot" vs "cold" entries within a queue
3. Both policies arrive at the same steady-state cache contents

**To truly differentiate LRU from FIFO, the workload would need point lookups or skewed key distributions where some entries in the same column are accessed 10×+ more than others.** This doesn't occur in analytical scan workloads like ClickBench.
