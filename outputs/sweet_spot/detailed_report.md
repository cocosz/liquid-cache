# Sweet Spot Analysis: Cache Memory Budget vs Query Performance

## Performance Model

The **sweet spot** is the minimum cache memory budget at which a query achieves full in-memory performance — no disk reads on hot iterations. Below this threshold, performance collapses sharply due to disk I/O for evicted cache entries.

### Working Set Formula

```
W_compressed = R × B × Σ(compressed_column_size_per_row_group)
```

Where:
- **R** = number of row groups that pass statistics pruning
- **B** = number of cached columns (predicate + projection columns)
- **Σ(compressed_column_size)** = sum of compressed column sizes across matched row groups

### Performance Zones

| Zone | Condition | Behavior |
|------|-----------|----------|
| 🟢 Green | Budget ≥ W_compressed | All predicate columns fit in memory; hot queries run at memory speed (0 disk reads) |
| 🔴 Red | Budget < W_compressed | Evicted entries must be read from disk on every query; latency dominated by I/O |

There is **no yellow zone** — the cliff is sharp. Once even a small fraction of the working set spills to disk, performance collapses because every hot iteration must re-read the spilled entries.

---

## Summary Overview

| Query | Predicate Columns | Sweet Spot | Cliff At | Pushdown (hot) | Sweet Spot (hot) | Cliff (hot) | Speedup vs Pushdown |
|-------|-------------------|-----------|----------|----------------|------------------|-------------|---------------------|
| Q19 | UserID (Int64) | **384 MB** | 256 MB | 85 ms | 33 ms | 660 ms | 2.6× |
| Q7 | AdvEngineID (Int16) | **32 MB** | 16 MB | 32 ms | 15 ms | 1,909 ms | 2.1× |
| Q40 | CounterID, EventDate, IsRefresh, TraficSourceID, RefererHash | **16 MB** | 8 MB | 38 ms | 20 ms | 87 ms | 1.9× |
| Q42 | CounterID, EventDate, IsRefresh, DontCountHits, EventTime | **8 MB** | ∞ (always fits) | 33 ms | 18 ms | N/A | 1.8× |

---

## Q19: Point Lookup on Numeric Column (UserID)

### SQL

```sql
SELECT "UserID" FROM hits WHERE "UserID" = 435090932899640449;
```

### Cached Columns

| Column | Type | Role | Cached |
|--------|------|------|--------|
| UserID | Int64 | Predicate + Projection | ✅ |

### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Hot Avg (1-4) | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------------|-----------------|------|
| 8 MB | 17,976 ms | 4,060 ms | 5,043 ms | 5,038 ms | 5,041 ms | 4,796 ms | 662 MB | 🔴 |
| 16 MB | 18,051 ms | 3,931 ms | 4,907 ms | 4,917 ms | 4,901 ms | 4,664 ms | 645 MB | 🔴 |
| 32 MB | 18,110 ms | 3,661 ms | 4,638 ms | 4,633 ms | 4,638 ms | 4,393 ms | 610 MB | 🔴 |
| 64 MB | 18,079 ms | 3,123 ms | 4,099 ms | 4,102 ms | 4,098 ms | 3,856 ms | 539 MB | 🔴 |
| 128 MB | 17,956 ms | 2,052 ms | 3,023 ms | 3,017 ms | 3,019 ms | 2,778 ms | 398 MB | 🔴 |
| 256 MB | 17,965 ms | 133 ms | 662 ms | 869 ms | 877 ms | 635 ms | 117 MB | 🔴 |
| **384 MB** | **13,777 ms** | **33 ms** | **33 ms** | **32 ms** | **33 ms** | **33 ms** | **0.1 MB** | 🟢 |
| 512 MB | 6,447 ms | 27 ms | 26 ms | 29 ms | 29 ms | 28 ms | 0 | 🟢 |
| 768 MB | 169 ms | 21 ms | 20 ms | 21 ms | 20 ms | 21 ms | 0 | 🟢 |
| 1024 MB | 166 ms | 21 ms | 21 ms | 22 ms | 22 ms | 22 ms | 0 | 🟢 |
| 2048 MB | 164 ms | 22 ms | 20 ms | 21 ms | 22 ms | 21 ms | 0 | 🟢 |
| Pushdown | 127 ms | 87 ms | 85 ms | 87 ms | 80 ms | 85 ms | — | — |

### CacheStats — Sweet Spot (384 MB, iter 4)

```
total_entries: 10668
memory_arrow_entries: 2
memory_liquid_entries: 2579
memory_squeezed_liquid_entries: 8086
disk_liquid_entries: 1
memory_arrow_bytes: 131,264
memory_liquid_bytes: 156,854,323
memory_squeezed_liquid_bytes: 245,585,984
memory_usage_bytes: 402,571,571 (383 MB)
disk_usage_bytes: 493,498,648 (470 MB)
max_memory_bytes: 402,653,184 (384 MB)
```

### CacheStats — Cliff (256 MB, iter 4)

```
total_entries: 10668
memory_arrow_entries: 2
memory_liquid_entries: 2
memory_squeezed_liquid_entries: 8809
disk_liquid_entries: 1855
memory_arrow_bytes: 131,264
memory_liquid_bytes: 114,882
memory_squeezed_liquid_bytes: 268,063,328
memory_usage_bytes: 268,309,474 (255 MB)
disk_usage_bytes: 650,094,272 (619 MB)
max_memory_bytes: 268,435,456 (256 MB)
```

### EXPLAIN ANALYZE — Sweet Spot (384 MB)

**Cold (Iteration 0):**
```
DataSourceExec: file_groups={16 groups: [...]}, projection=[UserID], file_type=liquid_parquet,
  metrics=[output_rows=4, bytes_scanned=231.7 M,
    row_groups_pruned_statistics=226 total → 202 matched,
    pushdown_rows_matched=0, pushdown_rows_pruned=0,
    time_elapsed_opening=175.67ms, time_elapsed_processing=2.65s,
    time_elapsed_scanning_total=153.01s, time_elapsed_scanning_until_data=143.36s]

Cache: entries=10668, mem=383MB, disk=470MB
  Hits: cache_hit=1, eval_predicate=21336
  Misses: cache_miss=10668
  IO: read=0, write=8087
Time: 13777ms
```

**Hot (Iteration 4):**
```
DataSourceExec: file_groups={16 groups: [...]}, projection=[UserID], file_type=liquid_parquet,
  metrics=[output_rows=4, bytes_scanned=0,
    row_groups_pruned_statistics=226 total → 202 matched,
    pushdown_rows_matched=0, pushdown_rows_pruned=0,
    time_elapsed_opening=4.75ms, time_elapsed_processing=350.90ms,
    time_elapsed_scanning_total=348.12ms, time_elapsed_scanning_until_data=339.55ms]

Cache: entries=10668, mem=383MB, disk=470MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=3, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=2
Time: 33ms
```

### EXPLAIN ANALYZE — Cliff (256 MB, Iteration 4)

```
DataSourceExec: file_groups={16 groups: [...]}, projection=[UserID], file_type=liquid_parquet,
  metrics=[output_rows=4, bytes_scanned=0,
    row_groups_pruned_statistics=226 total → 202 matched,
    pushdown_rows_matched=0, pushdown_rows_pruned=0,
    time_elapsed_opening=5.87ms, time_elapsed_processing=280.17ms,
    time_elapsed_scanning_total=11.95s, time_elapsed_scanning_until_data=11.94s]

Cache: entries=10668, mem=255MB, disk=619MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=1857, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=2
Time: 877ms
```

### Key DataSourceExec Metrics

| Metric | 384 MB (hot) | 256 MB (hot) |
|--------|-------------|-------------|
| bytes_scanned | 0 | 0 |
| time_elapsed_scanning_total | 348 ms | 11.95 s |
| time_elapsed_scanning_until_data | 340 ms | 11.94 s |
| Cache IO reads | 3 | 1,857 |
| disk_bytes_read | 127 KB | 117 MB |

### Analysis

Q19 scans the single column `UserID` (Int64, 8 bytes/value) across 202 matched row groups × 16 file partitions. The compressed working set is the squeezed representation of ~10,668 column chunks of UserID data. At 384 MB the cache holds 2,579 liquid entries + 8,086 squeezed entries entirely in memory (383 MB used). At 256 MB, 1,855 entries spill to disk (619 MB on disk), requiring 117 MB of disk reads per hot iteration — pushing latency from 33 ms to 877 ms (26× slower). The cliff is sharp because the squeezed UserID column for all 202 row groups is approximately 380 MB compressed; any budget below this forces every query to perform sequential disk I/O to hydrate evicted chunks.

---

## Q7: Filter + Aggregate on Small Numeric Column (AdvEngineID)

### SQL

```sql
SELECT "AdvEngineID", COUNT(*) FROM hits WHERE "AdvEngineID" <> 0 GROUP BY "AdvEngineID" ORDER BY COUNT(*) DESC;
```

### Cached Columns

| Column | Type | Role | Cached |
|--------|------|------|--------|
| AdvEngineID | Int16 | Predicate + Projection | ✅ |

### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Hot Avg (1-4) | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------------|-----------------|------|
| 8 MB | 9,307 ms | 2,979 ms | 3,962 ms | 3,961 ms | 3,965 ms | 3,717 ms | 67 MB | 🔴 |
| 16 MB | 4,954 ms | 1,289 ms | 2,114 ms | 2,119 ms | 2,114 ms | 1,909 ms | 37 MB | 🔴 |
| **32 MB** | **56 ms** | **15 ms** | **16 ms** | **16 ms** | **15 ms** | **16 ms** | **0** | 🟢 |
| 64 MB | 60 ms | 15 ms | 16 ms | 15 ms | 16 ms | 16 ms | 0 | 🟢 |
| 128 MB | 65 ms | 14 ms | 17 ms | 15 ms | 17 ms | 16 ms | 0 | 🟢 |
| 256 MB | 62 ms | 14 ms | 15 ms | 15 ms | 15 ms | 15 ms | 0 | 🟢 |
| 512 MB | 61 ms | 15 ms | 15 ms | 16 ms | 15 ms | 15 ms | 0 | 🟢 |
| 768 MB | 63 ms | 16 ms | 15 ms | 15 ms | 18 ms | 16 ms | 0 | 🟢 |
| 1024 MB | 63 ms | 15 ms | 14 ms | 15 ms | 18 ms | 16 ms | 0 | 🟢 |
| 2048 MB | 67 ms | 16 ms | 15 ms | 16 ms | 16 ms | 16 ms | 0 | 🟢 |
| Pushdown | 66 ms | 35 ms | 32 ms | 31 ms | 31 ms | 32 ms | — | — |

### CacheStats — Sweet Spot (32 MB, iter 4)

```
total_entries: 11540
memory_arrow_entries: 460
memory_liquid_entries: 11080
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_arrow_bytes: 7,580,800
memory_liquid_bytes: 25,904,920
memory_usage_bytes: 33,485,720 (31 MB)
disk_usage_bytes: 0
max_memory_bytes: 33,554,432 (32 MB)
```

### CacheStats — Cliff (16 MB, iter 4)

```
total_entries: 11540
memory_arrow_entries: 4
memory_liquid_entries: 7368
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 4168
memory_arrow_bytes: 65,920
memory_liquid_bytes: 16,692,120
memory_usage_bytes: 16,758,040 (15 MB)
disk_usage_bytes: 10,580,800 (10 MB)
max_memory_bytes: 16,777,216 (16 MB)
```

### EXPLAIN ANALYZE — Sweet Spot (32 MB)

**Cold (Iteration 0):**
```
DataSourceExec: file_groups={16 groups: [...]}, projection=[AdvEngineID], file_type=liquid_parquet,
  metrics=[output_rows=630.5 K, bytes_scanned=941.5 K,
    row_groups_pruned_statistics=226 total → 212 matched,
    time_elapsed_opening=163.14ms, time_elapsed_processing=480.42ms,
    time_elapsed_scanning_total=527.42ms, time_elapsed_scanning_until_data=63.82ms]

Cache: entries=11540, mem=31MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=23080
  Misses: cache_miss=11540
  IO: read=0, write=0
Time: 56ms
```

**Hot (Iteration 4):**
```
DataSourceExec: file_groups={16 groups: [...]}, projection=[AdvEngineID], file_type=liquid_parquet,
  metrics=[output_rows=630.5 K, bytes_scanned=0,
    row_groups_pruned_statistics=226 total → 212 matched,
    time_elapsed_opening=5.65ms, time_elapsed_processing=135.04ms,
    time_elapsed_scanning_total=149.23ms, time_elapsed_scanning_until_data=1.73ms]

Cache: entries=11540, mem=31MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
Time: 15ms
```

### EXPLAIN ANALYZE — Cliff (16 MB, Iteration 4)

```
DataSourceExec: file_groups={16 groups: [...]}, projection=[AdvEngineID], file_type=liquid_parquet,
  metrics=[output_rows=630.5 K, bytes_scanned=0,
    row_groups_pruned_statistics=226 total → 212 matched,
    time_elapsed_opening=6.87ms, time_elapsed_processing=133.89ms,
    time_elapsed_scanning_total=31.10s, time_elapsed_scanning_until_data=437.79ms]

Cache: entries=11540, mem=15MB, disk=10MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=6373, write=0
Time: 2114ms
```

### Key DataSourceExec Metrics

| Metric | 32 MB (hot) | 16 MB (hot) |
|--------|------------|------------|
| bytes_scanned | 0 | 0 |
| time_elapsed_scanning_total | 149 ms | 31.10 s |
| time_elapsed_scanning_until_data | 1.73 ms | 438 ms |
| Cache IO reads | 0 | 6,373 |
| disk_bytes_read | 0 | 37 MB |

### Analysis

Q7 scans AdvEngineID (Int16, 2 bytes/value) across 212 matched row groups. AdvEngineID is an extremely small column — the entire compressed working set fits in just ~32 MB (11,540 entries × ~2.3 KB average). At 32 MB everything stays in memory with 0 disk reads. At 16 MB, 4,168 entries (36%) spill to disk requiring 6,373 disk I/O operations and 37 MB reads per iteration, pushing time from 15 ms to 2,114 ms (141× slower). The cliff is particularly dramatic here because AdvEngineID is so small: a full scan touches every row group, so even partial eviction requires reading most of the spilled data back on each query.

---

## Q40: Multi-Predicate Filter with Row Pushdown

### SQL

```sql
SELECT "URLHash", "EventDate"::INT::DATE, COUNT(*) AS PageViews
FROM hits
WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-01'
  AND "EventDate"::INT::DATE <= '2013-07-31' AND "IsRefresh" = 0
  AND "TraficSourceID" IN (-1, 6) AND "RefererHash" = 3594120000172545465
GROUP BY "URLHash", "EventDate"::INT::DATE
ORDER BY PageViews DESC LIMIT 10 OFFSET 100;
```

### Cached Columns

| Column | Type | Role | Cached |
|--------|------|------|--------|
| CounterID | Int32 | Predicate | ✅ |
| EventDate | UInt16 | Predicate | ✅ |
| IsRefresh | UInt8 | Predicate | ✅ |
| TraficSourceID | Int16 | Predicate | ✅ |
| RefererHash | UInt64 | Predicate | ✅ |

### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Hot Avg (1-4) | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------------|-----------------|------|
| 8 MB | 940 ms | 82 ms | 77 ms | 92 ms | 95 ms | 87 ms | 5 MB | 🔴 |
| **16 MB** | **51 ms** | **21 ms** | **20 ms** | **20 ms** | **20 ms** | **20 ms** | **0** | 🟢 |
| 32 MB | 51 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 64 MB | 51 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 128 MB | 51 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 256 MB | 51 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 384 MB | 51 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 512 MB | 51 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 768 MB | 51 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 1024 MB | 51 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 2048 MB | 51 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| Pushdown | 65 ms | 39 ms | 37 ms | 38 ms | 38 ms | 38 ms | — | — |

### CacheStats — Sweet Spot (16 MB, iter 4)

```
total_entries: 860
memory_arrow_entries: 276
memory_liquid_entries: 584
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_arrow_bytes: 8,162,044
memory_liquid_bytes: 8,599,354
memory_usage_bytes: 16,761,398 (15 MB)
disk_usage_bytes: 0
max_memory_bytes: 16,777,216 (16 MB)
```

### CacheStats — Cliff (8 MB, iter 4)

```
total_entries: 860
memory_arrow_entries: 1
memory_liquid_entries: 334
memory_squeezed_liquid_entries: 109
disk_liquid_entries: 416
memory_arrow_bytes: 65,632
memory_liquid_bytes: 4,785,612
memory_squeezed_liquid_bytes: 3,470,544
memory_usage_bytes: 8,321,788 (7 MB)
disk_usage_bytes: 7,767,560 (7 MB)
max_memory_bytes: 8,388,608 (8 MB)
```

### EXPLAIN ANALYZE — Sweet Spot (16 MB)

**Cold (Iteration 0):**
```
DataSourceExec: file_groups={16 groups: [...]}, projection=[EventDate, URLHash], file_type=liquid_parquet,
  metrics=[output_rows=89.91 K, bytes_scanned=15.65 M,
    row_groups_pruned_statistics=226 total → 3 matched,
    pushdown_rows_matched=89.91 K, pushdown_rows_pruned=6.82 K,
    time_elapsed_opening=255.11ms, time_elapsed_processing=67.75ms,
    time_elapsed_scanning_total=36.24ms, time_elapsed_scanning_until_data=8.84ms]

Cache: entries=860, mem=15MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=712
  Misses: cache_miss=172
  IO: read=0, write=0
Time: 51ms
```

**Hot (Iteration 4):**
```
DataSourceExec: file_groups={16 groups: [...]}, projection=[EventDate, URLHash], file_type=liquid_parquet,
  metrics=[output_rows=89.91 K, bytes_scanned=15.65 M,
    row_groups_pruned_statistics=226 total → 3 matched,
    pushdown_rows_matched=89.91 K, pushdown_rows_pruned=6.82 K,
    time_elapsed_opening=8.36ms, time_elapsed_processing=23.31ms,
    time_elapsed_scanning_total=20.35ms, time_elapsed_scanning_until_data=5.14ms]

Cache: entries=860, mem=15MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
Time: 20ms
```

### EXPLAIN ANALYZE — Cliff (8 MB, Iteration 4)

```
DataSourceExec: file_groups={16 groups: [...]}, projection=[EventDate, URLHash], file_type=liquid_parquet,
  metrics=[output_rows=89.91 K, bytes_scanned=15.65 M,
    row_groups_pruned_statistics=226 total → 3 matched,
    pushdown_rows_matched=89.91 K, pushdown_rows_pruned=6.82 K,
    time_elapsed_opening=9.59ms, time_elapsed_processing=31.66ms,
    time_elapsed_scanning_total=151.41ms, time_elapsed_scanning_until_data=17.31ms]

Cache: entries=860, mem=7MB, disk=7MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=402, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=51
Time: 95ms
```

### Key DataSourceExec Metrics

| Metric | 16 MB (hot) | 8 MB (hot) |
|--------|------------|------------|
| bytes_scanned | 15.65 M | 15.65 M |
| time_elapsed_scanning_total | 20 ms | 151 ms |
| time_elapsed_scanning_until_data | 5 ms | 17 ms |
| Cache IO reads | 0 | 402 |
| disk_bytes_read | 0 | 5 MB |

### Analysis

Q40 benefits from aggressive statistics pruning (226 → 3 row groups) and row-level pushdown, which dramatically reduces the working set. Only 860 cache entries are needed for 5 predicate columns across 3 row groups. The entire compressed working set fits in ~16 MB. At 8 MB, 416 entries (48%) spill to disk, adding 402 disk reads per iteration — pushing latency from 20 ms to 95 ms (4.75× slower). The cliff is gentler than Q19/Q7 because the working set is small and disk reads are correspondingly small (5 MB), but still measurable.

---

## Q42: Multi-Predicate with Narrow Date Range (Always Fits)

### SQL

```sql
SELECT DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) AS M, COUNT(*) AS PageViews
FROM hits
WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-14'
  AND "EventDate"::INT::DATE <= '2013-07-15' AND "IsRefresh" = 0
  AND "DontCountHits" = 0
GROUP BY DATE_TRUNC('minute', to_timestamp_seconds("EventTime"))
ORDER BY DATE_TRUNC('minute', M) LIMIT 10 OFFSET 1000;
```

### Cached Columns

| Column | Type | Role | Cached |
|--------|------|------|--------|
| CounterID | Int32 | Predicate | ✅ |
| EventDate | UInt16 | Predicate | ✅ |
| IsRefresh | UInt8 | Predicate | ✅ |
| DontCountHits | UInt8 | Predicate | ✅ |

### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Hot Avg (1-4) | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------------|-----------------|------|
| **8 MB** | **39 ms** | **25 ms** | **18 ms** | **18 ms** | **18 ms** | **20 ms** | **0** | 🟢 |
| 16 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| 32 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| 64 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| 128 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| 256 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| 384 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| 512 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| 768 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| 1024 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| 2048 MB | 39 ms | 25 ms | 18 ms | 18 ms | 18 ms | 20 ms | 0 | 🟢 |
| Pushdown | 56 ms | 37 ms | 30 ms | 31 ms | 33 ms | 33 ms | — | — |

### CacheStats — 8 MB (iter 4)

```
total_entries: 688
memory_arrow_entries: 384
memory_liquid_entries: 304
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_arrow_bytes: 7,878,924
memory_liquid_bytes: 430,248
memory_usage_bytes: 8,309,172 (7.9 MB)
disk_usage_bytes: 0
max_memory_bytes: 8,388,608 (8 MB)
```

### EXPLAIN ANALYZE — 8 MB (Always Green)

**Cold (Iteration 0):**
```
DataSourceExec: file_groups={16 groups: [...]}, projection=[EventTime], file_type=liquid_parquet,
  metrics=[output_rows=671.5 K, bytes_scanned=4.78 M,
    row_groups_pruned_statistics=226 total → 3 matched,
    pushdown_rows_matched=0, pushdown_rows_pruned=0,
    time_elapsed_opening=182.97ms, time_elapsed_processing=55.03ms,
    time_elapsed_scanning_total=26.36ms, time_elapsed_scanning_until_data=5.45ms]

Cache: entries=688, mem=7MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=712
  Misses: cache_miss=172
  IO: read=0, write=0
Time: 39ms
```

**Hot (Iteration 4):**
```
DataSourceExec: file_groups={16 groups: [...]}, projection=[EventTime], file_type=liquid_parquet,
  metrics=[output_rows=671.5 K, bytes_scanned=4.78 M,
    row_groups_pruned_statistics=226 total → 3 matched,
    pushdown_rows_matched=0, pushdown_rows_pruned=0,
    time_elapsed_opening=7.03ms, time_elapsed_processing=19.14ms,
    time_elapsed_scanning_total=18.52ms, time_elapsed_scanning_until_data=3.07ms]

Cache: entries=688, mem=7MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
Time: 18ms
```

### Key DataSourceExec Metrics

| Metric | 8 MB (hot) |
|--------|-----------|
| bytes_scanned | 4.78 M |
| time_elapsed_scanning_total | 18.52 ms |
| time_elapsed_scanning_until_data | 3.07 ms |
| Cache IO reads | 0 |
| disk_bytes_read | 0 |

### Analysis

Q42 has the smallest working set of any query tested. Statistics pruning reduces 226 row groups to just 3, and the predicate columns (CounterID, EventDate, IsRefresh, DontCountHits) are all tiny types (UInt8, UInt16, Int32). The entire 688 cache entries fit in just 7.9 MB — well within the minimum 8 MB budget. This query **always** operates in the green zone with no cliff edge, demonstrating that queries with high selectivity on narrow date ranges + small predicate types need minimal cache memory to achieve full performance.

---

## Conclusions

1. **The cliff is binary**: There is no gradual degradation. Either the compressed working set fits in memory (green) or it doesn't (red). The performance difference is 4-141×.

2. **Working set size varies dramatically by query**: From 8 MB (Q42) to 384 MB (Q19), spanning ~50× range for the same dataset.

3. **Key determinants of working set size**:
   - Number of row groups that pass statistics pruning (226 for Q19 vs 3 for Q40/Q42)
   - Column type width (Int64 for UserID vs Int16 for AdvEngineID)
   - Number of predicate columns cached

4. **Statistics pruning is the biggest lever**: Q40 and Q42 both have 5+ predicate columns but only need 16 MB and 8 MB respectively because CounterID statistics eliminate 223/226 row groups before any cache access.

5. **The sweet spot is predictable**: Given the compressed column sizes in the Parquet metadata and the number of matched row groups, the sweet spot can be computed ahead of time as: `sweet_spot ≈ matched_row_groups × columns × avg_compressed_chunk_size`.
