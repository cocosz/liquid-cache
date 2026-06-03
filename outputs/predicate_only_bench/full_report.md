# Predicate-Only Cache: Detailed Query Analysis

## Configuration

| Parameter | Value |
|-----------|-------|
| Cache Memory Budget | 2 GB |
| Iterations per query | 5 |
| Instance Type | c6a.4xlarge |
| Dataset | ClickBench hits.parquet (~14.8 GB) |
| File Partitions | 16 groups |
| Modes Tested | Liquid (predicate cache), Parquet (pushdown), DataFusionDefault (no pushdown) |

---

## Strategy Comparison: All Predicates vs Numeric-Only Predicates

Two caching strategies tested:
- **All Predicates:** Cache every column used in WHERE clause (including strings like SearchPhrase, Title)
- **Numeric-Only Predicates:** Cache only numeric/date columns used in WHERE; string predicates read from Parquet

| Query | No Pushdown | Pushdown | All Pred (hot) | Numeric-Only (hot) | All Pred Speedup vs Pushdown | Numeric-Only Speedup vs Pushdown |
|-------|-------------|----------|----------------|--------------------|-----------------------------|----------------------------------|
| Q19   | 60 ms       | 85 ms    | **20 ms**      | **22 ms**          | 4.25×                       | 3.86×                            |
| Q24   | 397 ms      | 446 ms   | **61 ms**      | 396 ms             | 7.31×                       | 1.13×                            |
| Q26   | 386 ms      | 536 ms   | **97 ms**      | 440 ms             | 5.53×                       | 1.22×                            |
| Q37   | 105 ms      | 96 ms    | **32 ms**      | **79 ms**          | 3.00×                       | 1.22×                            |

Note: "hot" = average of iterations 1–4. Pushdown/No-Pushdown values are also average of iterations 1–4.

### Cache Memory Usage Comparison

| Query | All Predicates | Numeric-Only | Savings |
|-------|---------------|-------------|---------|
| Q19   | 668 MB (10,668 entries) | 668 MB (10,668 entries) | 0% (same — UserID is numeric) |
| Q24   | 2,047 MB (24,436 entries) | 768 MB (12,218 entries) | 63% less memory |
| Q26   | 2,047 MB (24,436 entries) | 768 MB (12,218 entries) | 63% less memory |
| Q37   | 131 MB (860 entries) | 13 MB (688 entries) | 90% less memory |

### Key Findings

Caching all predicate columns (including strings) gives dramatically better performance (3–7× vs pushdown) but uses significantly more memory. The numeric-only strategy saves 63–90% memory for string-filtered queries but loses most of the speedup because the string column (SearchPhrase/Title) is the selective filter. For Q19 where the predicate is purely numeric (UserID), both strategies perform identically. The trade-off is clear: All Predicates uses 2–10× more cache memory but delivers 3–6× better latency for string-filtered queries.

---

## Q19: Point Lookup on Numeric Column

### SQL

```sql
SELECT "UserID" FROM hits WHERE "UserID" = 435090932899640449;
```

### Cached Columns

| Column | Type | All Predicates | Numeric-Only |
|--------|------|---------------|-------------|
| UserID | Int64 | ✅ cached | ✅ cached |

### Timing Results (ms)

| Iteration | No Pushdown | Pushdown | All-Pred LC | Numeric-Only LC |
|-----------|-------------|----------|-------------|-----------------|
| 0 (cold)  | 93          | 125      | 168         | 162             |
| 1         | 60          | 88       | 20          | 21              |
| 2         | 56          | 86       | 20          | 24              |
| 3         | 58          | 85       | 21          | 20              |
| 4         | 64          | 81       | 20          | 21              |

### CacheStats — All Predicates (iter 4)

```
total_entries: 10668
memory_arrow_entries: 10668
memory_arrow_bytes: 701,150,208 (668 MB)
memory_liquid_entries: 0
disk_usage_bytes: 0
max_memory_bytes: 2,147,483,648
```

### CacheStats — Numeric-Only (iter 4)

```
total_entries: 10668
memory_arrow_entries: 10668
memory_arrow_bytes: 701,150,208 (668 MB)
memory_liquid_entries: 0
disk_usage_bytes: 0
max_memory_bytes: 2,147,483,648
```

### EXPLAIN ANALYZE — Cold (Iteration 0, All Predicates)

```
DataSourceExec: file_groups={16 groups: [...]}, projection=[UserID], file_type=liquid_parquet,
  metrics=[output_rows=4, bytes_scanned=231.7 M,
    row_groups_pruned_statistics=226 total → 202 matched,
    pushdown_rows_matched=0, pushdown_rows_pruned=0,
    time_elapsed_opening=245.83ms, time_elapsed_processing=1.80s,
    time_elapsed_scanning_total=2.06s, time_elapsed_scanning_until_data=2.02s]

Cache: entries=10668, mem=668MB, disk=0MB
  Hits: cache_hit=1, eval_predicate=21336
  Misses: cache_miss=10668
Time: 168ms
```

### EXPLAIN ANALYZE — Hot (Iteration 4, All Predicates)

```
DataSourceExec: file_groups={16 groups: [...]}, projection=[UserID], file_type=liquid_parquet,
  metrics=[output_rows=4, bytes_scanned=0,
    row_groups_pruned_statistics=226 total → 202 matched,
    pushdown_rows_matched=0, pushdown_rows_pruned=0,
    time_elapsed_opening=5.46ms, time_elapsed_processing=260.63ms,
    time_elapsed_scanning_total=255.23ms, time_elapsed_scanning_until_data=248.35ms]

Cache: entries=10668, mem=668MB, disk=0MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
Time: 20ms
```

### EXPLAIN ANALYZE — Hot (Iteration 4, Numeric-Only)

```
DataSourceExec: file_groups={16 groups: [...]}, projection=[UserID], file_type=liquid_parquet,
  metrics=[output_rows=4, bytes_scanned=0,
    row_groups_pruned_statistics=226 total → 202 matched,
    pushdown_rows_matched=0, pushdown_rows_pruned=0,
    time_elapsed_opening=6.15ms, time_elapsed_processing=251.33ms,
    time_elapsed_scanning_total=245.25ms, time_elapsed_scanning_until_data=238.43ms]

Cache: entries=10668, mem=668MB, disk=0MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
Time: 21ms
```

> **Observation:** Q19 is identical between strategies — UserID is numeric, so both cache it the same way. bytes_scanned=0 on hot for both.

### Key DataSourceExec Metrics — All Predicates

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|-------------|
| bytes_scanned | 231.7 M | 0 |
| pushdown_rows_matched | 0 | 0 |
| row_groups_pruned | 226→202 matched | 226→202 matched |
| time_elapsed_scanning | 2.06s | 255.23ms |
| time_elapsed_opening | 245.83ms | 5.46ms |
| eval_predicate | 21,336 | 10,668 |
| cache_hit | 1 | 1 |
| cache_miss | 10,668 | 0 |

### Key DataSourceExec Metrics — Numeric-Only

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|-------------|
| bytes_scanned | 231.7 M | 0 |
| pushdown_rows_matched | 0 | 0 |
| row_groups_pruned | 226→202 matched | 226→202 matched |
| time_elapsed_scanning | 2.01s | 245.25ms |
| time_elapsed_opening | 246.38ms | 6.15ms |
| eval_predicate | 21,336 | 10,668 |
| cache_hit | 1 | 1 |
| cache_miss | 10,668 | 0 |

> Both strategies are identical for Q19 — UserID is numeric, so both cache it the same way.

### Analysis

Q19 is a point lookup on UserID (Int64). Statistics-based pruning eliminates 24 of 226 row groups. Since the predicate column is purely numeric, both strategies cache identical data (668 MB, 10,668 entries). The hot latency is 20–21 ms in both cases — a 4× speedup over pushdown. The speedup comes from evaluating the predicate directly on cached Arrow arrays without Parquet decoding overhead. bytes_scanned drops to 0 on hot iterations because all data is served from cache.

---

## Q24: String Filter with Sort

### SQL

```sql
SELECT "SearchPhrase" FROM hits WHERE "SearchPhrase" <> '' ORDER BY to_timestamp_seconds("EventTime") LIMIT 10;
```

### Cached Columns

| Column | Type | All Predicates | Numeric-Only |
|--------|------|---------------|-------------|
| SearchPhrase | Utf8 (string) | ✅ cached | ❌ read from Parquet |
| EventTime | Int32 | ✅ cached | ✅ cached |

### Timing Results (ms)

| Iteration | No Pushdown | Pushdown | All-Pred LC | Numeric-Only LC |
|-----------|-------------|----------|-------------|-----------------|
| 0 (cold)  | 431         | 497      | 808         | 459             |
| 1         | 394         | 446      | 56          | 392             |
| 2         | 406         | 451      | 60          | 399             |
| 3         | 381         | 435      | 65          | 392             |
| 4         | 408         | 453      | 62          | 401             |

### CacheStats — All Predicates (iter 4)

```
total_entries: 24436
memory_arrow_entries: 18980
memory_liquid_entries: 5456
memory_arrow_bytes: 1,987,470,211
memory_liquid_bytes: 159,761,593
memory_usage_bytes: 2,147,231,804 (2,047 MB)
disk_usage_bytes: 0
max_memory_bytes: 2,147,483,648
```

### CacheStats — Numeric-Only (iter 4)

```
total_entries: 12218
memory_arrow_entries: 12218
memory_liquid_entries: 0
memory_arrow_bytes: 806,033,032 (768 MB)
memory_usage_bytes: 806,033,032
disk_usage_bytes: 0
max_memory_bytes: 2,147,483,648
```

### EXPLAIN ANALYZE — Cold (Iteration 0, All Predicates)

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC NULLS LAST], fetch=10
    SortExec: TopK(fetch=10), expr=[to_timestamp_seconds(EventTime@1) ASC NULLS LAST]
      DataSourceExec: file_groups={16 groups: [...]}, projection=[SearchPhrase, EventTime],
        file_type=liquid_parquet,
        metrics=[output_rows=1.65 K, bytes_scanned=776.2 M,
          row_groups_pruned_statistics=226 total → 226 matched,
          pushdown_rows_matched=38, pushdown_rows_pruned=0,
          time_elapsed_opening=178.99ms, time_elapsed_processing=8.60s,
          time_elapsed_scanning_total=9.07s, time_elapsed_scanning_until_data=3.82s]

Cache: entries=24436, mem=2047MB, disk=0MB
  Hits: cache_hit=209, eval_predicate=36577
  Misses: cache_miss=12218
Time: 808ms
```

### EXPLAIN ANALYZE — Hot (Iteration 4, All Predicates)

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC NULLS LAST], fetch=10
    SortExec: TopK(fetch=10), expr=[to_timestamp_seconds(EventTime@1) ASC NULLS LAST]
      DataSourceExec: file_groups={16 groups: [...]}, projection=[SearchPhrase, EventTime],
        file_type=liquid_parquet,
        metrics=[output_rows=2.36 K, bytes_scanned=0,
          row_groups_pruned_statistics=226 total → 226 matched,
          pushdown_rows_matched=1.63 K, pushdown_rows_pruned=483,
          time_elapsed_opening=26.28ms, time_elapsed_processing=678.90ms,
          time_elapsed_scanning_total=653.46ms, time_elapsed_scanning_until_data=290.25ms]

Cache: entries=24436, mem=2047MB, disk=0MB
  Hits: cache_hit=189, eval_predicate=24357
  Misses: cache_miss=0
Time: 62ms
```

### EXPLAIN ANALYZE — Hot (Iteration 4, Numeric-Only)

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC NULLS LAST], fetch=10
    SortExec: TopK(fetch=10), expr=[to_timestamp_seconds(EventTime@1) ASC NULLS LAST]
      DataSourceExec: file_groups={16 groups: [...]}, projection=[SearchPhrase, EventTime],
        file_type=liquid_parquet,
        metrics=[output_rows=1.89 K, bytes_scanned=776.2 M,
          row_groups_pruned_statistics=226 total → 226 matched,
          pushdown_rows_matched=13.17 M, pushdown_rows_pruned=86.83 M,
          row_pushdown_eval_time=523.86ms,
          time_elapsed_opening=9.61ms, time_elapsed_processing=5.00s,
          time_elapsed_scanning_total=5.32s, time_elapsed_scanning_until_data=2.43s]

Cache: entries=12218, mem=768MB, disk=0MB
  Hits: cache_hit=102, eval_predicate=36577
  Misses: cache_miss=0
Time: 401ms
```

> **Critical difference:** Numeric-only still shows `bytes_scanned=776.2 M` on hot runs! SearchPhrase must be read from Parquet every iteration because it's not cached. The `row_pushdown_eval_time=524ms` dominates — this is the time spent decoding SearchPhrase from Parquet just to evaluate `SearchPhrase <> ''`. The All Predicates strategy eliminates this entirely (bytes_scanned=0).

### Key DataSourceExec Metrics — All Predicates

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|-------------|
| bytes_scanned | 776.2 M | **0** |
| pushdown_rows_matched | 38 | 1.63 K |
| pushdown_rows_pruned | 0 | 483 |
| row_groups_pruned | 226→226 matched | 226→226 matched |
| row_pushdown_eval_time | 6.11µs | 19.20µs |
| time_elapsed_scanning | 9.07s | 653.46ms |
| time_elapsed_opening | 178.99ms | 26.28ms |
| eval_predicate | 36,577 | 24,357 |
| cache_hit | 209 | 189 |
| cache_miss | 12,218 | 0 |

### Key DataSourceExec Metrics — Numeric-Only

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|-------------|
| bytes_scanned | 776.2 M | **776.2 M** |
| pushdown_rows_matched | 13.17 M | 13.17 M |
| pushdown_rows_pruned | 86.83 M | 86.83 M |
| row_groups_pruned | 226→226 matched | 226→226 matched |
| row_pushdown_eval_time | 531.88ms | 523.86ms |
| time_elapsed_scanning | 6.02s | 5.32s |
| time_elapsed_opening | 195.82ms | 9.61ms |
| eval_predicate | 36,577 | 36,577 |
| cache_hit | 96 | 102 |
| cache_miss | 0 | 0 |

> **Key difference:** All-Pred achieves `bytes_scanned=0` on hot (SearchPhrase served from cache). Numeric-Only reads 776.2 MB from Parquet on EVERY iteration because SearchPhrase is not cached. The `row_pushdown_eval_time` shows the cost: 19µs (all-pred) vs 524ms (numeric-only).

---

## Q25: String Sort (All Predicates Only)

### SQL

```sql
SELECT "SearchPhrase" FROM hits WHERE "SearchPhrase" <> '' ORDER BY "SearchPhrase" LIMIT 10;
```

### Cached Columns (All Predicates only)

| Column | Type | All Predicates |
|--------|------|---------------|
| SearchPhrase | Utf8 (string) | ✅ cached |

### Timing Results (ms)

| Iteration | No Pushdown | Pushdown | All-Pred LC |
|-----------|-------------|----------|-------------|
| 0 (cold)  | 346         | 438      | 425         |
| 1         | 308         | 389      | 92          |
| 2         | 307         | 386      | 84          |
| 3         | 302         | 377      | 87          |
| 4         | 307         | 395      | 83          |

### CacheStats — All Predicates (iter 4)

```
total_entries: 12218
memory_arrow_entries: 12218
memory_arrow_bytes: 1,710,487,620 (1,631 MB)
memory_liquid_entries: 0
memory_usage_bytes: 1,710,487,620
disk_usage_bytes: 0
max_memory_bytes: 2,147,483,648
```

### EXPLAIN ANALYZE — Cold (Iteration 0, All Predicates)

```
SortPreservingMergeExec: [SearchPhrase@0 ASC NULLS LAST], fetch=10
  SortExec: TopK(fetch=10), expr=[SearchPhrase@0 ASC NULLS LAST]
    DataSourceExec: file_groups={16 groups: [...]}, projection=[SearchPhrase],
      file_type=liquid_parquet,
      metrics=[output_rows=1.18 K, bytes_scanned=373.1 M,
        row_groups_pruned_statistics=226 total → 226 matched,
        pushdown_rows_matched=0, pushdown_rows_pruned=0,
        time_elapsed_opening=257.76ms, time_elapsed_processing=4.91s,
        time_elapsed_scanning_total=5.15s, time_elapsed_scanning_until_data=309.07ms]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=163, eval_predicate=36578
  Misses: cache_miss=12218
Time: 425ms
```

### EXPLAIN ANALYZE — Hot (Iteration 4, All Predicates)

```
SortPreservingMergeExec: [SearchPhrase@0 ASC NULLS LAST], fetch=10
  SortExec: TopK(fetch=10), expr=[SearchPhrase@0 ASC NULLS LAST]
    DataSourceExec: file_groups={16 groups: [...]}, projection=[SearchPhrase],
      file_type=liquid_parquet,
      metrics=[output_rows=1.09 K, bytes_scanned=0,
        row_groups_pruned_statistics=226 total → 226 matched,
        pushdown_rows_matched=0, pushdown_rows_pruned=0,
        time_elapsed_opening=27.12ms, time_elapsed_processing=980.59ms,
        time_elapsed_scanning_total=954.40ms, time_elapsed_scanning_until_data=79.73ms]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=145, eval_predicate=24360
  Misses: cache_miss=0
Time: 83ms
```

### Key DataSourceExec Metrics (All Predicates only)

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|-------------|
| bytes_scanned | 373.1 M | **0** |
| pushdown_rows_matched | 0 | 0 |
| row_groups_pruned | 226→226 matched | 226→226 matched |
| time_elapsed_scanning | 5.15s | 954.40ms |
| time_elapsed_opening | 257.76ms | 27.12ms |
| eval_predicate | 36,578 | 24,360 |
| cache_hit | 163 | 145 |
| cache_miss | 12,218 | 0 |

*Numeric-Only not tested for Q25 — SearchPhrase is the only column involved, so numeric-only would have nothing to cache.*

### Analysis

Q25 filters and sorts on SearchPhrase. No statistics pruning is possible (all 226 row groups match). The All Predicates strategy caches SearchPhrase in Arrow format (1,631 MB), providing a 4.6× speedup over pushdown (86 ms avg vs 387 ms). The benefit comes from avoiding Parquet string decoding on repeated queries. No numeric-only run was done for this query since the only column involved is a string — the numeric-only strategy would have nothing to cache and would perform identically to pushdown.

---

## Q26: String Filter with Dual Sort

### SQL

```sql
SELECT "SearchPhrase" FROM hits WHERE "SearchPhrase" <> '' ORDER BY to_timestamp_seconds("EventTime"), "SearchPhrase" LIMIT 10;
```

### Cached Columns

| Column | Type | All Predicates | Numeric-Only |
|--------|------|---------------|-------------|
| SearchPhrase | Utf8 (string) | ✅ cached | ❌ read from Parquet |
| EventTime | Int32 | ✅ cached | ✅ cached |

### Timing Results (ms)

| Iteration | No Pushdown | Pushdown | All-Pred LC | Numeric-Only LC |
|-----------|-------------|----------|-------------|-----------------|
| 0 (cold)  | 444         | 615      | 833         | 489             |
| 1         | 380         | 528      | 93          | 437             |
| 2         | 387         | 543      | 101         | 450             |
| 3         | 390         | 528      | 100         | 436             |
| 4         | 387         | 543      | 95          | 437             |

### CacheStats — All Predicates (iter 4)

```
total_entries: 24436
memory_arrow_entries: 18940
memory_liquid_entries: 5496
memory_arrow_bytes: 1,987,623,577
memory_liquid_bytes: 159,475,096
memory_usage_bytes: 2,147,098,673 (2,047 MB)
disk_usage_bytes: 0
max_memory_bytes: 2,147,483,648
```

### CacheStats — Numeric-Only (iter 4)

```
total_entries: 12218
memory_arrow_entries: 12218
memory_liquid_entries: 0
memory_arrow_bytes: 806,033,032 (768 MB)
memory_usage_bytes: 806,033,032
disk_usage_bytes: 0
max_memory_bytes: 2,147,483,648
```

### EXPLAIN ANALYZE — Cold (Iteration 0, All Predicates)

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC, SearchPhrase@0 ASC], fetch=10
    SortExec: TopK(fetch=10)
      DataSourceExec: file_groups={16 groups: [...]}, projection=[SearchPhrase, EventTime],
        file_type=liquid_parquet,
        metrics=[output_rows=3.05 K, bytes_scanned=776.2 M,
          row_groups_pruned_statistics=226 total → 226 matched,
          pushdown_rows_matched=3.05 K, pushdown_rows_pruned=13.17 M,
          time_elapsed_opening=266.03ms, time_elapsed_processing=8.89s,
          time_elapsed_scanning_total=9.39s, time_elapsed_scanning_until_data=3.76s]

Cache: entries=24436, mem=2047MB, disk=0MB
  Hits: cache_hit=24498, eval_predicate=24436
  Misses: cache_miss=12218
Time: 833ms
```

### EXPLAIN ANALYZE — Hot (Iteration 4, All Predicates)

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC, SearchPhrase@0 ASC], fetch=10
    SortExec: TopK(fetch=10)
      DataSourceExec: file_groups={16 groups: [...]}, projection=[SearchPhrase, EventTime],
        file_type=liquid_parquet,
        metrics=[output_rows=2.93 K, bytes_scanned=0,
          row_groups_pruned_statistics=226 total → 226 matched,
          pushdown_rows_matched=2.93 K, pushdown_rows_pruned=13.17 M,
          time_elapsed_opening=7.65ms, time_elapsed_processing=1.21s,
          time_elapsed_scanning_total=1.21s, time_elapsed_scanning_until_data=348.89ms]

Cache: entries=24436, mem=2047MB, disk=0MB
  Hits: cache_hit=24508, eval_predicate=12218
  Misses: cache_miss=0
Time: 95ms
```

### EXPLAIN ANALYZE — Hot (Iteration 4, Numeric-Only)

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC, SearchPhrase@0 ASC], fetch=10
    SortExec: TopK(fetch=10)
      DataSourceExec: file_groups={16 groups: [...]}, projection=[SearchPhrase, EventTime],
        file_type=liquid_parquet,
        metrics=[output_rows=1.63 K, bytes_scanned=776.2 M,
          row_groups_pruned_statistics=226 total → 226 matched,
          pushdown_rows_matched=13.17 M, pushdown_rows_pruned=100.00 M,
          row_pushdown_eval_time=659.38ms,
          time_elapsed_opening=9.92ms, time_elapsed_processing=5.55s,
          time_elapsed_scanning_total=5.89s, time_elapsed_scanning_until_data=2.66s]

Cache: entries=12218, mem=768MB, disk=0MB
  Hits: cache_hit=24391, eval_predicate=24436
  Misses: cache_miss=0
Time: 437ms
```

> **Critical difference:** Same pattern as Q24 — `bytes_scanned=776.2 M` on every hot iteration. However, note `pushdown_rows_pruned=100M` (vs 13.17M for all-predicates). The dynamic TopK filter prunes MORE rows in numeric-only because it can only use EventTime for the compound filter, not the cached SearchPhrase. Despite aggressive pruning, the 776MB Parquet decode dominates.

### Key DataSourceExec Metrics — All Predicates

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|-------------|
| bytes_scanned | 776.2 M | **0** |
| pushdown_rows_matched | 3.05 K | 2.93 K |
| pushdown_rows_pruned | 13.17 M | 13.17 M |
| row_groups_pruned | 226→226 matched | 226→226 matched |
| row_pushdown_eval_time | 193.41ms | 109.33ms |
| time_elapsed_scanning | 9.39s | 1.21s |
| time_elapsed_opening | 266.03ms | 7.65ms |
| eval_predicate | 24,436 | 12,218 |
| cache_hit | 24,498 | 24,508 |
| cache_miss | 12,218 | 0 |

### Key DataSourceExec Metrics — Numeric-Only

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|-------------|
| bytes_scanned | 776.2 M | **776.2 M** |
| pushdown_rows_matched | 13.17 M | 13.17 M |
| pushdown_rows_pruned | 100.00 M | 100.00 M |
| row_groups_pruned | 226→226 matched | 226→226 matched |
| row_pushdown_eval_time | 674.97ms | 659.38ms |
| time_elapsed_scanning | 6.45s | 5.89s |
| time_elapsed_opening | 186.49ms | 9.92ms |
| eval_predicate | 24,436 | 24,436 |
| cache_hit | 24,397 | 24,391 |
| cache_miss | 0 | 0 |

> **Key difference:** All-Pred achieves `bytes_scanned=0` on hot. Numeric-Only reads 776.2 MB every iteration. Note numeric-only prunes 100M rows (vs 13.17M for all-pred) — the dynamic filter works harder but still can't compensate for the Parquet decode cost (659ms `row_pushdown_eval_time`).

---

## Q37: Multi-Column Filter with String Predicate

### SQL

```sql
SELECT "Title", COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-01' AND "EventDate"::INT::DATE <= '2013-07-31' AND "DontCountHits" = 0 AND "IsRefresh" = 0 AND "Title" <> '' GROUP BY "Title" ORDER BY PageViews DESC LIMIT 10;
```

### Cached Columns

| Column | Type | All Predicates | Numeric-Only |
|--------|------|---------------|-------------|
| CounterID | Int32 | ✅ cached | ✅ cached |
| EventDate | Int32 | ✅ cached | ✅ cached |
| DontCountHits | Int16 | ✅ cached | ✅ cached |
| IsRefresh | Int16 | ✅ cached | ✅ cached |
| Title | Utf8 (string) | ✅ cached | ❌ read from Parquet |

### Timing Results (ms)

| Iteration | No Pushdown | Pushdown | All-Pred LC | Numeric-Only LC |
|-----------|-------------|----------|-------------|-----------------|
| 0 (cold)  | 130         | 118      | 145         | 124             |
| 1         | 120         | 104      | 33          | 79              |
| 2         | 102         | 94       | 31          | 79              |
| 3         | 99          | 93       | 32          | 80              |
| 4         | 100         | 93       | 31          | 79              |

### CacheStats — All Predicates (iter 4)

```
total_entries: 860
memory_arrow_entries: 860
memory_arrow_bytes: 137,895,479 (131 MB)
memory_liquid_entries: 0
memory_usage_bytes: 137,895,479
disk_usage_bytes: 0
max_memory_bytes: 2,147,483,648
```

### CacheStats — Numeric-Only (iter 4)

```
total_entries: 688
memory_arrow_entries: 688
memory_arrow_bytes: 14,134,028 (13 MB)
memory_liquid_entries: 0
memory_usage_bytes: 14,134,028
disk_usage_bytes: 0
max_memory_bytes: 2,147,483,648
```

### EXPLAIN ANALYZE — Cold (Iteration 0, All Predicates)

```
SortPreservingMergeExec: [pageviews@1 DESC], fetch=10
  SortExec: TopK(fetch=10), expr=[pageviews@1 DESC]
    ProjectionExec: expr=[Title@0 as Title, count(Int64(1))@1 as pageviews]
      AggregateExec: mode=FinalPartitioned, gby=[Title@0 as Title], aggr=[count(Int64(1))]
        RepartitionExec: partitioning=Hash([Title@0], 16)
          AggregateExec: mode=Partial, gby=[Title@0 as Title], aggr=[count(Int64(1))]
            DataSourceExec: file_groups={16 groups: [...]}, projection=[Title],
              file_type=liquid_parquet,
              metrics=[output_rows=660.3 K, bytes_scanned=17.54 M,
                row_groups_pruned_statistics=226 total → 3 matched,
                pushdown_rows_matched=0, pushdown_rows_pruned=0,
                time_elapsed_opening=184.67ms, time_elapsed_processing=222.97ms,
                time_elapsed_scanning_total=210.55ms, time_elapsed_scanning_until_data=40.73ms]

Cache: entries=860, mem=131MB, disk=0MB
  Hits: cache_hit=92, eval_predicate=804
  Misses: cache_miss=172
Time: 145ms
```

### EXPLAIN ANALYZE — Hot (Iteration 4, All Predicates)

```
SortPreservingMergeExec: [pageviews@1 DESC], fetch=10
  SortExec: TopK(fetch=10), expr=[pageviews@1 DESC]
    ProjectionExec: expr=[Title@0 as Title, count(Int64(1))@1 as pageviews]
      AggregateExec: mode=FinalPartitioned, gby=[Title@0 as Title], aggr=[count(Int64(1))]
        RepartitionExec: partitioning=Hash([Title@0], 16)
          AggregateExec: mode=Partial, gby=[Title@0 as Title], aggr=[count(Int64(1))]
            DataSourceExec: file_groups={16 groups: [...]}, projection=[Title],
              file_type=liquid_parquet,
              metrics=[output_rows=660.3 K, bytes_scanned=0,
                row_groups_pruned_statistics=226 total → 3 matched,
                pushdown_rows_matched=0, pushdown_rows_pruned=0,
                time_elapsed_opening=7.74ms, time_elapsed_processing=22.47ms,
                time_elapsed_scanning_total=31.64ms, time_elapsed_scanning_until_data=572.60µs]

Cache: entries=860, mem=131MB, disk=0MB
  Hits: cache_hit=92, eval_predicate=632
  Misses: cache_miss=0
Time: 31ms
```

### EXPLAIN ANALYZE — Hot (Iteration 4, Numeric-Only)

```
SortPreservingMergeExec: [pageviews@1 DESC], fetch=10
  SortExec: TopK(fetch=10), expr=[pageviews@1 DESC]
    ProjectionExec: expr=[Title@0 as Title, count(Int64(1))@1 as pageviews]
      AggregateExec: mode=FinalPartitioned, gby=[Title@0 as Title], aggr=[count(Int64(1))]
        RepartitionExec: partitioning=Hash([Title@0], 16)
          AggregateExec: mode=Partial, gby=[Title@0 as Title], aggr=[count(Int64(1))]
            DataSourceExec: file_groups={16 groups: [...]}, projection=[Title],
              file_type=liquid_parquet,
              metrics=[output_rows=660.3 K, bytes_scanned=17.54 M,
                row_groups_pruned_statistics=226 total → 3 matched,
                pushdown_rows_matched=660.3 K, pushdown_rows_pruned=11.18 K,
                row_pushdown_eval_time=764.39µs,
                time_elapsed_opening=6.90ms, time_elapsed_processing=73.56ms,
                time_elapsed_scanning_total=87.30ms, time_elapsed_scanning_until_data=9.90ms]

Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=724
  Misses: cache_miss=0
Time: 79ms
```

> **Key difference:** All-Predicates has `bytes_scanned=0` and `cache_hit=92` (Title served from cache). Numeric-Only has `bytes_scanned=17.54M` (Title read from Parquet every time) and `cache_hit=0`. The 79ms vs 31ms gap (2.5×) is the cost of re-reading Title from Parquet on each hot iteration. However, even Numeric-Only (79ms) beats Pushdown (94ms) because the 4 numeric predicates are evaluated from cache (688 entries, 13MB).

### Key DataSourceExec Metrics — All Predicates

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|-------------|
| bytes_scanned | 17.54 M | **0** |
| pushdown_rows_matched | 0 | 0 |
| pushdown_rows_pruned | 0 | 0 |
| row_groups_pruned | 226→3 matched | 226→3 matched |
| time_elapsed_scanning | 210.55ms | 31.64ms |
| time_elapsed_opening | 184.67ms | 7.74ms |
| eval_predicate | 804 | 632 |
| cache_hit | 92 | 92 |
| cache_miss | 172 | 0 |

### Key DataSourceExec Metrics — Numeric-Only

| Metric | Cold (iter 0) | Hot (iter 4) |
|--------|---------------|-------------|
| bytes_scanned | 17.54 M | **17.54 M** |
| pushdown_rows_matched | 660.3 K | 660.3 K |
| pushdown_rows_pruned | 11.18 K | 11.18 K |
| row_groups_pruned | 226→3 matched | 226→3 matched |
| row_pushdown_eval_time | 754.10µs | 764.39µs |
| time_elapsed_scanning | 164.63ms | 87.30ms |
| time_elapsed_opening | 270.20ms | 6.90ms |
| eval_predicate | 896 | 724 |
| cache_hit | 0 | 0 |
| cache_miss | 172 | 0 |

> **Key difference:** All-Pred reaches `bytes_scanned=0` and `cache_hit=92` (Title served from cache). Numeric-Only has `bytes_scanned=17.54M` every hot run and `cache_hit=0` (Title reads from Parquet). The 79ms vs 31ms gap is the Title decode cost.

### Analysis

Q37 has multiple numeric predicates (CounterID=62, EventDate range, DontCountHits=0, IsRefresh=0) plus a string predicate (`Title <> ''`). Statistics pruning is extremely effective here — only 3 of 226 row groups match, reducing the working set dramatically. The All Predicates strategy caches Title along with numeric columns (131 MB, 860 entries), achieving 32 ms hot latency (3× vs pushdown) with `bytes_scanned=0`. The Numeric-Only strategy caches only the 4 numeric predicate columns (13 MB, 688 entries — 90% less memory), but still reads Title from Parquet every time (`bytes_scanned=17.54M`), resulting in 79 ms. Even with numeric-only, the 4 cached numeric predicates provide a 1.2× speedup over pushdown (79ms vs 94ms).
