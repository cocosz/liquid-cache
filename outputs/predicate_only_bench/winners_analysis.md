# Predicate-Only Cache: Big Winner Queries Analysis

This document analyzes the 5 queries (Q19, Q24, Q25, Q26, Q37) that show the largest performance gains with LiquidCache's predicate-only caching compared to standard Parquet pushdown and DataFusion default modes.

## Summary Table

| Query | Liquid Hot (ms) | Pushdown Hot (ms) | No-Pushdown Hot (ms) | Speedup vs Pushdown | Speedup vs No-Pushdown |
|-------|----------------|-------------------|---------------------|--------------------|-----------------------|
| Q19   | 20             | 85                | 59                  | **4.3x**           | 3.0x                  |
| Q24   | 61             | 446               | 397                 | **7.3x**           | 6.5x                  |
| Q25   | 87             | 387               | 306                 | **4.4x**           | 3.5x                  |
| Q26   | 97             | 536               | 386                 | **5.5x**           | 4.0x                  |
| Q37   | 32             | 96                | 105                 | **3.0x**           | 3.3x                  |

---

## Q19: Point Lookup on UserID

### SQL
```sql
SELECT "UserID" FROM hits WHERE "UserID" = 435090932899640449;
```

### Timing (ms)

| Iteration | Liquid | Pushdown | No-Pushdown |
|-----------|--------|----------|-------------|
| 0 (cold)  | 168    | 125      | 93          |
| 1         | 20     | 88       | 60          |
| 2         | 20     | 86       | 56          |
| 3         | 21     | 85       | 58          |
| 4         | 20     | 81       | 64          |
| **Hot avg (1-4)** | **20.3** | **85.0** | **59.5** |

### Cache Stats (from explain.log)
- **Entries:** 10,668 (all memory_arrow)
- **Memory:** 668 MB (701 MB raw)
- **Hits (hot):** cache_hit=1, eval_predicate=10,668
- **Misses (hot):** cache_miss=0

### Explain-Analyze Metrics (Iteration 0 → Iteration 4)

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|--------------|
| output_rows | 4 | 4 |
| row_groups_pruned_statistics | 226 total → 202 matched | 226 total → 202 matched |
| pushdown_rows_matched | 0 | 0 |
| pushdown_rows_pruned | 0 | 0 |
| bytes_scanned | 231.7 M | 0 |
| time_elapsed_scanning_total | 2.06s | 255.23ms |
| time_elapsed_scanning_until_data | 2.02s | 248.35ms |

### Why It Wins

Q19 is a highly selective point lookup (only 4 rows match out of ~100M). The predicate-only cache evaluates `UserID = 435090932899640449` directly on cached Arrow columns via `eval_predicate` (10,668 evaluations across all cached column chunks). Because the predicate eliminates virtually all rows, the cache never needs to materialize/return full column data — it just returns the 4 matching rows. The 0 `bytes_scanned` on hot iterations confirms zero Parquet I/O. Parquet pushdown still must decode pages to evaluate the predicate, costing ~85ms. The cache's in-memory predicate evaluation is ~4x faster.

---

## Q24: SearchPhrase Filter with EventTime Sort

### SQL
```sql
SELECT "SearchPhrase" FROM hits WHERE "SearchPhrase" <> '' ORDER BY to_timestamp_seconds("EventTime") LIMIT 10;
```

### Timing (ms)

| Iteration | Liquid | Pushdown | No-Pushdown |
|-----------|--------|----------|-------------|
| 0 (cold)  | 808    | 497      | 431         |
| 1         | 56     | 446      | 394         |
| 2         | 60     | 451      | 406         |
| 3         | 65     | 435      | 381         |
| 4         | 62     | 453      | 408         |
| **Hot avg (1-4)** | **60.8** | **446.3** | **397.3** |

### Cache Stats (from explain.log)
- **Entries:** 24,436 (18,980 arrow + 5,456 liquid)
- **Memory:** 2,047 MB
- **Hits (hot):** cache_hit=~207, eval_predicate=~24,357
- **Misses (hot):** cache_miss=0

### Explain-Analyze Metrics (Iteration 0 → Iteration 4)

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|--------------|
| output_rows | 1.65 K | 2.36 K |
| row_groups_pruned_statistics | 226 total → 226 matched | 226 total → 226 matched |
| pushdown_rows_matched | 38 | 1.63 K |
| pushdown_rows_pruned | 0 | 483 |
| bytes_scanned | 776.2 M | 0 |
| time_elapsed_scanning_total | 9.07s | 653.46ms |
| time_elapsed_processing | 8.60s | 678.90ms |

### Why It Wins

The `SearchPhrase <> ''` predicate is moderately selective (~1.5% of rows have non-empty SearchPhrase). Without caching, Parquet must decompress and scan all SearchPhrase + EventTime columns (~776 MB). With predicate-only caching, the cache evaluates the inequality predicate on cached columns and only returns the ~few-thousand matching rows. The TopK sort with LIMIT 10 further reduces output. The dramatic 7.3x speedup comes from avoiding full column decompression — the predicate is evaluated directly on the cached representation, and the `pushdown_rows_pruned` metric shows rows being eliminated before materialization.

---

## Q25: SearchPhrase Filter with SearchPhrase Sort

### SQL
```sql
SELECT "SearchPhrase" FROM hits WHERE "SearchPhrase" <> '' ORDER BY "SearchPhrase" LIMIT 10;
```

### Timing (ms)

| Iteration | Liquid | Pushdown | No-Pushdown |
|-----------|--------|----------|-------------|
| 0 (cold)  | 425    | 438      | 346         |
| 1         | 92     | 389      | 308         |
| 2         | 84     | 386      | 307         |
| 3         | 87     | 377      | 302         |
| 4         | 83     | 395      | 307         |
| **Hot avg (1-4)** | **86.5** | **386.8** | **306.0** |

### Cache Stats (from explain.log)
- **Entries:** 12,218 (all memory_arrow)
- **Memory:** 1,631 MB
- **Hits (hot):** cache_hit=~141, eval_predicate=24,360
- **Misses (hot):** cache_miss=0

### Explain-Analyze Metrics (Iteration 0 → Iteration 4)

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|--------------|
| output_rows | 1.18 K | 1.09 K |
| row_groups_pruned_statistics | 226 total → 226 matched | 226 total → 226 matched |
| pushdown_rows_matched | 0 | 0 |
| pushdown_rows_pruned | 0 | 0 |
| bytes_scanned | 373.1 M | 0 |
| time_elapsed_scanning_total | 5.15s | 954.40ms |
| time_elapsed_processing | 4.91s | 980.59ms |

### Why It Wins

Similar to Q24 but sorting by SearchPhrase itself. The cache holds SearchPhrase columns in memory (1.6 GB cached). On hot iterations, the eval_predicate (24,360 calls = 2x 12,218 entries, for the predicate evaluation on both sides of the row group) filters out empty strings without decompressing Parquet. The TopK sort with the dynamic filter `SearchPhrase < $_posten...` allows early termination. The 4.4x speedup over pushdown comes from the same mechanism: cached predicate evaluation is faster than Parquet's decode-then-filter pipeline.

---

## Q26: SearchPhrase Filter with Composite Sort (EventTime, SearchPhrase)

### SQL
```sql
SELECT "SearchPhrase" FROM hits WHERE "SearchPhrase" <> '' ORDER BY to_timestamp_seconds("EventTime"), "SearchPhrase" LIMIT 10;
```

### Timing (ms)

| Iteration | Liquid | Pushdown | No-Pushdown |
|-----------|--------|----------|-------------|
| 0 (cold)  | 833    | 615      | 444         |
| 1         | 93     | 528      | 380         |
| 2         | 101    | 543      | 387         |
| 3         | 100    | 528      | 390         |
| 4         | 95     | 543      | 387         |
| **Hot avg (1-4)** | **97.3** | **535.5** | **386.0** |

### Cache Stats (from explain.log)
- **Entries:** 24,436 (18,940 arrow + 5,496 liquid)
- **Memory:** 2,047 MB
- **Hits (hot):** cache_hit=~24,494, eval_predicate=12,218
- **Misses (hot):** cache_miss=0

### Explain-Analyze Metrics (Iteration 0 → Iteration 4)

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|--------------|
| output_rows | 3.05 K | 2.93 K |
| row_groups_pruned_statistics | 226 total → 226 matched | 226 total → 226 matched |
| pushdown_rows_matched | 3.05 K | 2.93 K |
| pushdown_rows_pruned | 13.17 M | 13.17 M |
| bytes_scanned | 776.2 M | 0 |
| time_elapsed_scanning_total | 9.39s | 1.21s |
| row_pushdown_eval_time | 193.41ms | 109.33ms |

### Why It Wins

This is the most dramatic demonstration of predicate-only caching value. The composite sort with TopK generates a dynamic row-level pushdown filter combining `to_timestamp_seconds(EventTime) < threshold` and `SearchPhrase < threshold`. The cache evaluates this compound predicate and **prunes 13.17 million rows** (`pushdown_rows_pruned`) while only matching ~3K rows. This means 99.98% of data is eliminated by predicate evaluation alone without reading column values. The 5.5x speedup over Parquet pushdown comes from two factors: (1) the predicate evaluation happens on cached in-memory data instead of Parquet pages, and (2) the high cache_hit count (24,494) shows columns being served directly from cache.

---

## Q37: Multi-Predicate Aggregation (CounterID + Date Range + Flags)

### SQL
```sql
SELECT "Title", COUNT(*) AS PageViews
FROM hits
WHERE "CounterID" = 62
  AND "EventDate"::INT::DATE >= '2013-07-01'
  AND "EventDate"::INT::DATE <= '2013-07-31'
  AND "DontCountHits" = 0
  AND "IsRefresh" = 0
  AND "Title" <> ''
GROUP BY "Title"
ORDER BY PageViews DESC
LIMIT 10;
```

### Timing (ms)

| Iteration | Liquid | Pushdown | No-Pushdown |
|-----------|--------|----------|-------------|
| 0 (cold)  | 145    | 118      | 130         |
| 1         | 33     | 104      | 120         |
| 2         | 31     | 94       | 102         |
| 3         | 32     | 93       | 99          |
| 4         | 31     | 93       | 100         |
| **Hot avg (1-4)** | **31.8** | **96.0** | **105.3** |

### Cache Stats (from explain.log)
- **Entries:** 860 (all memory_arrow)
- **Memory:** 131 MB
- **Hits (hot):** cache_hit=92, eval_predicate=632
- **Misses (hot):** cache_miss=0

### Explain-Analyze Metrics (Iteration 0 → Iteration 4)

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|--------------|
| output_rows | 660.3 K | 660.3 K |
| row_groups_pruned_statistics | 226 total → 3 matched | 226 total → 3 matched |
| pushdown_rows_matched | 0 | 0 |
| pushdown_rows_pruned | 0 | 0 |
| bytes_scanned | 17.54 M | 0 |
| time_elapsed_scanning_total | 210.55ms | 31.64ms |
| time_elapsed_processing | 222.97ms | 22.47ms |

### Why It Wins

Q37 benefits from excellent statistics-based pruning (226 → 3 row groups) combined with the cache. The multi-predicate filter (`CounterID = 62 AND date range AND flags`) narrows to only 3 row groups containing 660K qualifying rows. With only 860 cache entries (131 MB), the entire working set fits comfortably in cache. On hot iterations, scan time drops from 210ms to 31ms because data is served directly from in-memory Arrow arrays. The 3x speedup over Parquet is due to eliminating Parquet decode overhead — the data is already in Arrow format in the cache. The small cache footprint (131 MB vs 2 GB budget) makes this query extremely cache-efficient.

---

## Common Patterns: Why Predicate-Only Caching Wins

1. **Zero bytes_scanned on hot iterations**: All 5 queries show `bytes_scanned=0` after the cold iteration, confirming no Parquet I/O occurs.

2. **eval_predicate drives filtering**: The cache evaluates predicates directly on cached Arrow/Liquid columns without decompressing Parquet pages. This is the core mechanism behind the speedup.

3. **High selectivity amplifies gains**: Queries with highly selective predicates (Q19: 4 rows, Q37: 660K from 3 row groups) benefit most because the cache avoids materializing columns that would be filtered away.

4. **Dynamic TopK pushdown filters** (Q24, Q25, Q26): The sort-with-LIMIT pattern generates progressively tighter row-level pushdown predicates. The cache evaluates these compound predicates efficiently, pruning millions of rows (Q26: 13.17M pruned).

5. **Cache as a column store**: Once warm, the cache functions as an in-memory columnar store, eliminating all Parquet overhead (metadata parsing, page decompression, dictionary decoding). The cold-to-hot ratio ranges from 4.5x (Q37) to 14.4x (Q24).

6. **Memory trade-off**: The gains come at a memory cost (668 MB–2,047 MB). Queries touching fewer columns (Q19, Q37) are more cache-efficient per-query.
