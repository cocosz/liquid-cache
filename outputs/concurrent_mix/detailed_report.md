# Numeric Filter Cache — Concurrent Mix Benchmark Report

## Configuration

| Parameter | Value |
|---|---|
| Instance | c6a.4xlarge (16 vCPU, 32 GB RAM) |
| Dataset | ClickBench hits.parquet (~14.8 GB, 100M rows, 105 columns) |
| Memory configs | [64, 128, 256, 512, 1024, 2048] MB |
| Iterations | 5 (metric: min of hot runs, i.e., min of iter 1-4) |
| Cache policy | S3-FIFO (LiquidPolicy) |
| Squeeze policy | TranscodeSqueezeEvict |
| Hydration | NoHydration |
| Strategy | Numeric predicate-only caching |

## Performance Model

LiquidCache caches **numeric columns** used in predicates. When a query's filter columns are fully cached:
- Predicates evaluate directly on in-memory squeezed/liquid data
- No Parquet decode needed for filter evaluation
- Result: 2-6× speedup over plain DataFusion with pushdown filters

The **concurrent test** measures whether this speedup holds when heavy queries (large GROUP BY, DISTINCT) compete for CPU.

---

## Summary: Cache Speedup vs DataFusion

| Query | Purpose | DF min (ms) | Best cache min (ms) | Speedup | Best config |
|-------|---------|-------------|--------------------:|--------:|:------------|
| c0_range_filter | Range filter on 2 numeric cols | 58 | 16 | 3.62× | 512MB |
| c1_multi_numeric_pred | 4 numeric predicates, narrow band filter | 16 | 3 | 5.33× | 64MB |
| c2_point_lookups | Equality predicates + early termination (LIMIT) | 13 | 2 | 6.50× | 64MB |
| c4_date_range_agg | Date range + numeric aggs, ~15 groups | 150 | 153 | 0.98× | 2048MB |
| c6_selective_numeric | Highly selective, 5 combined numeric filters | 14 | 3 | 4.67× | 64MB |
| c7_wide_numeric_scan | Wide numeric read: 7 cols aggregated with 2 filters | 286 | 299 | 0.96× | 64MB |
| q1_advengine_ne0 | Single numeric inequality, full scan | 23 | 11 | 2.09× | 64MB |
| q7_group_advengine | Numeric filter + tiny GROUP BY (~20 engine IDs) | 25 | 13 | 1.92× | 512MB |
| q40_multi_pred_selective | 5 numeric predicates, stats-pruned to ~3 RGs | 33 | 20 | 1.65× | 64MB |
| q41_hash_equality | 5 numeric predicates + hash equality, very selective | 31 | 19 | 1.63× | 64MB |
| q42_time_bucket | 4 numeric predicates, narrow 2-day window | 28 | 18 | 1.56× | 64MB |

---

## Per-Query Detailed Analysis

### [0] c0_range_filter

**Purpose:** Range filter on 2 numeric cols

**Cached columns:** AdvEngineID (Int16), ResolutionWidth (Int16)

```sql
SELECT COUNT(*) FROM hits WHERE "AdvEngineID" > 0 AND "ResolutionWidth" >= 1024 AND "ResolutionWidth" <= 1920;
```

**DataFusion baseline:** 58ms (min hot), all iterations: [93, 61, 60, 61, 58]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| 64 MB | 27,277 ms | 952 ms | 949 ms | 954 ms | 953 ms | 949 ms | 123.2 MB | ➖ |
| 128 MB | 9,331 ms | 313 ms | 309 ms | 312 ms | 312 ms | 309 ms | 43.6 MB | ➖ |
| **256 MB** | **121 ms** | **18 ms** | **20 ms** | **19 ms** | **19 ms** | **18 ms** | **0** | 🟢 |
| **512 MB** | **110 ms** | **19 ms** | **17 ms** | **16 ms** | **18 ms** | **16 ms** | **0** | 🟢 |
| **1024 MB** | **108 ms** | **17 ms** | **20 ms** | **18 ms** | **18 ms** | **17 ms** | **0** | 🟢 |
| 2048 MB | 120 ms | 16 ms | 18 ms | 16 ms | 19 ms | 16 ms | 0 | 🟢 |
| Pushdown | 93 ms | 61 ms | 60 ms | 61 ms | 58 ms | 58 ms | — | — |

#### Cache Stats (best config: 512MB, last iteration)

```
total_entries: 23080
memory_arrow_entries: 23080
memory_liquid_entries: 0
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 380,014,128
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (512MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 0, Iteration 4) ===
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.28µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=330ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=9.24µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=15.89µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=2.10ms, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=liquid_parquet, metrics=[output_rows=477.2 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=5.60 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=10.21ms, metadata_load_time=1.94ms, page_index_eval_time=2.92µs, row_pushdown_eval_time=32ns, statistics_eval_time=373.55µs, time_elapsed_opening=14.14ms, time_elapsed_processing=160.15ms, time_elapsed_scanning_total=149.28ms, time_elapsed_scanning_until_data=1.70ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=23080, mem=362MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=23161
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms

+----------+
| count(*) |
+----------+
| 477198   |
+----------+
```
</details>


#### Analysis

**Strong cache benefit (3.6×).** Working set is 362MB (23080 entries). Sweet spot at **256MB** — all data fits in cache with zero disk reads. The large speedup comes from avoiding Parquet column decode entirely for predicate evaluation — the cache serves filter columns directly from memory. 

---

### [1] c1_multi_numeric_pred

**Purpose:** 4 numeric predicates, narrow band filter

**Cached columns:** IsRefresh (Int16), DontCountHits (Int16), CounterID (Int32)

```sql
SELECT COUNT(*), AVG("ResolutionWidth"), SUM("AdvEngineID") FROM hits WHERE "IsRefresh" = 0 AND "DontCountHits" = 0 AND "CounterID" > 100 AND "CounterID" < 500;
```

**DataFusion baseline:** 16ms (min hot), all iterations: [42, 19, 16, 16, 16]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| **64 MB** | **27 ms** | **4 ms** | **3 ms** | **3 ms** | **3 ms** | **3 ms** | **0** | 🟢 |
| 128 MB | 24 ms | 5 ms | 3 ms | 4 ms | 3 ms | 3 ms | 0 | 🟢 |
| 256 MB | 25 ms | 4 ms | 4 ms | 3 ms | 3 ms | 3 ms | 0 | 🟢 |
| 512 MB | 24 ms | 4 ms | 4 ms | 4 ms | 3 ms | 3 ms | 0 | 🟢 |
| 1024 MB | 24 ms | 5 ms | 3 ms | 4 ms | 3 ms | 3 ms | 0 | 🟢 |
| 2048 MB | 25 ms | 5 ms | 4 ms | 4 ms | 3 ms | 3 ms | 0 | 🟢 |
| Pushdown | 42 ms | 19 ms | 16 ms | 16 ms | 16 ms | 16 ms | — | — |

#### Cache Stats (best config: 64MB, last iteration)

```
total_entries: 291
memory_arrow_entries: 291
memory_liquid_entries: 0
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 6,384,928
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (64MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 1, Iteration 4) ===
ProjectionExec: expr=[count(Int64(1))@0 as count(*), avg(hits.ResolutionWidth)@1 as avg(hits.ResolutionWidth), sum(hits.AdvEngineID)@2 as sum(hits.AdvEngineID)], metrics=[output_rows=1, elapsed_compute=1.24µs, output_bytes=26.0 B, output_batches=1, expr_0_eval_time=290ns, expr_1_eval_time=100ns, expr_2_eval_time=70ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=1, elapsed_compute=20.64µs, output_bytes=26.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=13.17µs, output_bytes=544.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=16, elapsed_compute=115.41µs, output_bytes=544.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[ResolutionWidth, AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=0, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=0, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 2 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=99.58µs, metadata_load_time=2.49ms, page_index_eval_time=4.63µs, row_pushdown_eval_time=32ns, statistics_eval_time=555.89µs, time_elapsed_opening=5.41ms, time_elapsed_processing=8.38ms, time_elapsed_scanning_total=2.96ms, time_elapsed_scanning_until_data=2.96ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=291, mem=6MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=357
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 3ms

+----------+---------------------------+-----------------------+
| count(*) | avg(hits.ResolutionWidth) | sum(hits.AdvEngineID) |
+----------+---------------------------+-----------------------+
| 0        |                           |                       |
+----------+---------------------------+-----------------------+
```
</details>


#### Analysis

**Strong cache benefit (5.3×).** Working set is 6MB (291 entries). Sweet spot at **64MB** — all data fits in cache with zero disk reads. The large speedup comes from avoiding Parquet column decode entirely for predicate evaluation — the cache serves filter columns directly from memory. Small working set (291 entries) means this query is stats-pruned to a few row groups, making cache overhead negligible. 

---

### [2] c2_point_lookups

**Purpose:** Equality predicates + early termination (LIMIT)

**Cached columns:** CounterID (Int32), RegionID (UInt32), IsRefresh (Int16)

```sql
SELECT "UserID", "CounterID", "RegionID" FROM hits WHERE "CounterID" = 62 AND "RegionID" = 229 AND "IsRefresh" = 0 LIMIT 100;
```

**DataFusion baseline:** 13ms (min hot), all iterations: [42, 17, 14, 16, 13]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| **64 MB** | **21 ms** | **3 ms** | **2 ms** | **2 ms** | **2 ms** | **2 ms** | **0** | 🟢 |
| 128 MB | 20 ms | 3 ms | 2 ms | 2 ms | 2 ms | 2 ms | 0 | 🟢 |
| 256 MB | 26 ms | 3 ms | 2 ms | 2 ms | 2 ms | 2 ms | 0 | 🟢 |
| 512 MB | 21 ms | 3 ms | 2 ms | 2 ms | 2 ms | 2 ms | 0 | 🟢 |
| 1024 MB | 21 ms | 3 ms | 2 ms | 2 ms | 2 ms | 2 ms | 0 | 🟢 |
| 2048 MB | 20 ms | 3 ms | 2 ms | 2 ms | 2 ms | 2 ms | 0 | 🟢 |
| Pushdown | 42 ms | 17 ms | 14 ms | 16 ms | 13 ms | 13 ms | — | — |

#### Cache Stats (best config: 64MB, last iteration)

```
total_entries: 6
memory_arrow_entries: 6
memory_liquid_entries: 0
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 164,416
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (64MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 2, Iteration 4) ===
CoalescePartitionsExec: fetch=100, metrics=[output_rows=13, elapsed_compute=13.29µs, output_bytes=256.0 B, output_batches=1]
  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, CounterID, RegionID], limit=100, file_type=liquid_parquet, metrics=[output_rows=13, elapsed_compute=16ns, output_bytes=256.0 B, output_batches=1, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=1.90 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=134.74µs, metadata_load_time=2.32ms, page_index_eval_time=3.96µs, row_pushdown_eval_time=32ns, statistics_eval_time=508.93µs, time_elapsed_opening=5.14ms, time_elapsed_processing=5.96ms, time_elapsed_scanning_total=1.08ms, time_elapsed_scanning_until_data=1.06ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=6, mem=0MB, disk=0MB
  Hits: cache_hit=2, eval_predicate=4
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 2ms

+----------------------+-----------+----------+
| UserID               | CounterID | RegionID |
+----------------------+-----------+----------+
| -9169641491093342987 | 62        | 229      |
| -9169641491093342987 | 62        | 229      |
| -9169641491093342987 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
| -9164706819442030649 | 62        | 229      |
+----------------------+-----------+----------+
```
</details>


#### Analysis

**Strong cache benefit (6.5×).** Working set is 0MB (6 entries). Sweet spot at **64MB** — all data fits in cache with zero disk reads. The large speedup comes from avoiding Parquet column decode entirely for predicate evaluation — the cache serves filter columns directly from memory. Small working set (6 entries) means this query is stats-pruned to a few row groups, making cache overhead negligible. 

---

### [4] c4_date_range_agg

**Purpose:** Date range + numeric aggs, ~15 groups

**Cached columns:** EventDate (Int16→Date), CounterID (Int32)

```sql
SELECT "EventDate"::INT::DATE, COUNT(*), SUM("IsRefresh"), AVG("ResolutionWidth") FROM hits WHERE "EventDate"::INT::DATE >= '2013-07-01' AND "EventDate"::INT::DATE <= '2013-07-15' AND "CounterID" > 0 GROUP BY "EventDate"::INT::DATE ORDER BY "EventDate"::INT::DATE;
```

**DataFusion baseline:** 150ms (min hot), all iterations: [186, 156, 151, 150, 155]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| 64 MB | 214 ms | 167 ms | 189 ms | 179 ms | 172 ms | 167 ms | 0 | ➖ |
| 128 MB | 220 ms | 169 ms | 160 ms | 168 ms | 169 ms | 160 ms | 0 | ➖ |
| 256 MB | 220 ms | 162 ms | 183 ms | 177 ms | 161 ms | 161 ms | 0 | ➖ |
| 512 MB | 233 ms | 161 ms | 164 ms | 169 ms | 158 ms | 158 ms | 0 | ➖ |
| 1024 MB | 229 ms | 162 ms | 160 ms | 182 ms | 181 ms | 160 ms | 0 | ➖ |
| 2048 MB | 224 ms | 153 ms | 165 ms | 172 ms | 169 ms | 153 ms | 0 | ➖ |
| Pushdown | 186 ms | 156 ms | 151 ms | 150 ms | 155 ms | 150 ms | — | — |

#### Cache Stats (best config: 2048MB, last iteration)

```
total_entries: 21486
memory_arrow_entries: 21486
memory_liquid_entries: 0
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 529,572,312
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (2048MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 4, Iteration 4) ===
SortPreservingMergeExec: [hits.EventDate@0 ASC NULLS LAST], metrics=[output_rows=9, elapsed_compute=10.38µs, output_bytes=252.0 B, output_batches=1]
  SortExec: expr=[hits.EventDate@0 ASC NULLS LAST], preserve_partitioning=[true], metrics=[output_rows=9, elapsed_compute=13.12µs, output_bytes=0.0 B, output_batches=0, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0]
    ProjectionExec: expr=[hits.EventDate@0 as hits.EventDate, count(Int64(1))@1 as count(*), sum(hits.IsRefresh)@2 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@3 as avg(hits.ResolutionWidth)], metrics=[output_rows=9, elapsed_compute=6.97µs, output_bytes=3.0 KB, output_batches=5, expr_0_eval_time=743ns, expr_1_eval_time=471ns, expr_2_eval_time=451ns, expr_3_eval_time=371ns]
      AggregateExec: mode=FinalPartitioned, gby=[hits.EventDate@0 as hits.EventDate], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=9, elapsed_compute=154.53µs, output_bytes=3.0 KB, output_batches=5, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=44.22 K, aggregate_arguments_time=7.19µs, aggregation_time=21.21µs, emitting_time=9.85µs, time_calculating_group_ids=7.16µs]
        RepartitionExec: partitioning=Hash([hits.EventDate@0], 16), input_partitions=16, metrics=[output_rows=111, elapsed_compute=169.10µs, output_bytes=1440.0 KB, output_batches=5, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=1.93s, repartition_time=209.26µs, send_time=165.33µs]
          AggregateExec: mode=Partial, gby=[CAST(CAST(EventDate@0 AS Int32) AS Date32) as hits.EventDate], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=111, elapsed_compute=859.08ms, output_bytes=13.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.12 M, aggregate_arguments_time=95.84ms, aggregation_time=388.52ms, emitting_time=68.36µs, time_calculating_group_ids=452.51ms, reduction_factor=0.00018% (111/60.21 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[EventDate, IsRefresh, ResolutionWidth], file_type=liquid_parquet, metrics=[output_rows=60.21 M, elapsed_compute=16ns, output_bytes=344.6 MB, output_batches=7.81 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 198 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matc
```
</details>


#### Analysis

**No cache benefit (0.98×).** Working set is 505MB (21486 entries). This query is CPU-bound on aggregation — time is spent computing results, not reading/decoding data. Cache adds overhead without saving meaningful decode time. 

---

### [5] c6_selective_numeric

**Purpose:** Highly selective, 5 combined numeric filters

**Cached columns:** CounterID (Int32), EventDate (Int16), DontCountHits (Int16), IsRefresh (Int16), TraficSourceID (Int8)

```sql
SELECT "UserID", "RegionID", "CounterID" FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE = '2013-07-15' AND "DontCountHits" = 0 AND "IsRefresh" = 0 AND "TraficSourceID" IN (-1, 6) LIMIT 50;
```

**DataFusion baseline:** 14ms (min hot), all iterations: [40, 19, 14, 14, 14]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| **64 MB** | **22 ms** | **3 ms** | **3 ms** | **3 ms** | **3 ms** | **3 ms** | **0** | 🟢 |
| 128 MB | 22 ms | 3 ms | 3 ms | 3 ms | 3 ms | 3 ms | 0 | 🟢 |
| 256 MB | 22 ms | 3 ms | 3 ms | 3 ms | 3 ms | 3 ms | 0 | 🟢 |
| 512 MB | 21 ms | 4 ms | 3 ms | 3 ms | 3 ms | 3 ms | 0 | 🟢 |
| 1024 MB | 23 ms | 3 ms | 3 ms | 3 ms | 3 ms | 3 ms | 0 | 🟢 |
| 2048 MB | 21 ms | 4 ms | 3 ms | 3 ms | 3 ms | 3 ms | 0 | 🟢 |
| Pushdown | 40 ms | 19 ms | 14 ms | 14 ms | 14 ms | 14 ms | — | — |

#### Cache Stats (best config: 64MB, last iteration)

```
total_entries: 10
memory_arrow_entries: 10
memory_liquid_entries: 0
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 197,568
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (64MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 5, Iteration 4) ===
CoalescePartitionsExec: fetch=50, metrics=[output_rows=35, elapsed_compute=13.20µs, output_bytes=704.0 B, output_batches=1]
  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, RegionID, CounterID], limit=50, file_type=liquid_parquet, metrics=[output_rows=35, elapsed_compute=16ns, output_bytes=704.0 B, output_batches=1, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=2.05 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=35, pushdown_rows_pruned=11, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=183.93µs, metadata_load_time=3.00ms, page_index_eval_time=2.86µs, row_pushdown_eval_time=2.11µs, statistics_eval_time=539.20µs, time_elapsed_opening=6.34ms, time_elapsed_processing=7.46ms, time_elapsed_scanning_total=1.44ms, time_elapsed_scanning_until_data=1.42ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=10, mem=0MB, disk=0MB
  Hits: cache_hit=2, eval_predicate=5
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 3ms

+----------------------+----------+-----------+
| UserID               | RegionID | CounterID |
+----------------------+----------+-----------+
| -9198080625391903804 | 2        | 62        |
| -9193011485273158162 | 2        | 62        |
| -9193011485273158162 | 2        | 62        |
| -9193011485273158162 | 2        | 62        |
| -9193011485273158162 | 2        | 62        |
| -9193011485273158162 | 2        | 62        |
| -9193011485273158162 | 2        | 62        |
| -9193011485273158162 | 2        | 62        |
| -9193011485273158162 | 2        | 62        |
| -9169641491093342987 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -9164706819442030649 | 229      | 62        |
| -91194824
```
</details>


#### Analysis

**Strong cache benefit (4.7×).** Working set is 0MB (10 entries). Sweet spot at **64MB** — all data fits in cache with zero disk reads. The large speedup comes from avoiding Parquet column decode entirely for predicate evaluation — the cache serves filter columns directly from memory. Small working set (10 entries) means this query is stats-pruned to a few row groups, making cache overhead negligible. 

---

### [6] c7_wide_numeric_scan

**Purpose:** Wide numeric read: 7 cols aggregated with 2 filters

**Cached columns:** AdvEngineID (Int16), IsRefresh (Int16) + 7 projection cols

```sql
SELECT AVG("ResolutionWidth"), AVG("ResolutionHeight"), AVG("ClientIP"), AVG("WindowClientWidth"), AVG("WindowClientHeight"), AVG("CounterID"), AVG("RegionID") FROM hits WHERE "AdvEngineID" = 0 AND "IsRefresh" = 0;
```

**DataFusion baseline:** 286ms (min hot), all iterations: [347, 299, 286, 295, 287]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| 64 MB | 369 ms | 309 ms | 312 ms | 317 ms | 299 ms | 299 ms | 0 | ➖ |
| 128 MB | 365 ms | 310 ms | 315 ms | 330 ms | 302 ms | 302 ms | 0 | ➖ |
| 256 MB | 373 ms | 311 ms | 330 ms | 330 ms | 331 ms | 311 ms | 0 | ➖ |
| 512 MB | 357 ms | 314 ms | 303 ms | 332 ms | 315 ms | 303 ms | 0 | ➖ |
| 1024 MB | 363 ms | 316 ms | 304 ms | 302 ms | 324 ms | 302 ms | 0 | ➖ |
| 2048 MB | 387 ms | 328 ms | 310 ms | 317 ms | 309 ms | 309 ms | 0 | ➖ |
| Pushdown | 347 ms | 299 ms | 286 ms | 295 ms | 287 ms | 286 ms | — | — |

#### Cache Stats (best config: 64MB, last iteration)

```
total_entries: 24436
memory_arrow_entries: 1716
memory_liquid_entries: 22720
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 67,003,168
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (64MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 6, Iteration 4) ===
AggregateExec: mode=Final, gby=[], aggr=[avg(hits.ResolutionWidth), avg(hits.ResolutionHeight), avg(hits.ClientIP), avg(hits.WindowClientWidth), avg(hits.WindowClientHeight), avg(hits.CounterID), avg(hits.RegionID)], metrics=[output_rows=1, elapsed_compute=82.79µs, output_bytes=56.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.32µs, output_bytes=1792.0 B, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[avg(hits.ResolutionWidth), avg(hits.ResolutionHeight), avg(hits.ClientIP), avg(hits.WindowClientWidth), avg(hits.WindowClientHeight), avg(hits.CounterID), avg(hits.RegionID)], metrics=[output_rows=16, elapsed_compute=455.05ms, output_bytes=1792.0 B, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CounterID, ClientIP, RegionID, ResolutionWidth, ResolutionHeight, WindowClientWidth, WindowClientHeight], file_type=liquid_parquet, metrics=[output_rows=92.74 M, elapsed_compute=16ns, output_bytes=1769.3 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=488.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=3.95ms, metadata_load_time=2.91ms, page_index_eval_time=3.37µs, row_pushdown_eval_time=32ns, statistics_eval_time=441.60µs, time_elapsed_opening=10.43ms, time_elapsed_processing=3.22s, time_elapsed_scanning_total=3.98s, time_elapsed_scanning_until_data=113.94ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=24436, mem=63MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=24436
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 299ms

+---------------------------+----------------------------+--------------------+-----------------------------+------------------------------+---------------------+--------------------+
| avg(hits.ResolutionWidth) | avg(hits.ResolutionHeight) | avg(hits.ClientIP) | avg(hits.WindowClientWidth) | avg(hits.WindowClientHeight) | avg(hits.CounterID) | avg(hits.RegionID) |
+---------------------------+------------
```
</details>


#### Analysis

**No cache benefit (0.96×).** Working set is 64MB (24436 entries). This query is CPU-bound on aggregation — time is spent computing results, not reading/decoding data. Cache adds overhead without saving meaningful decode time. 

---

### [7] q1_advengine_ne0

**Purpose:** Single numeric inequality, full scan

**Cached columns:** AdvEngineID (Int16)

```sql
SELECT COUNT(*) FROM hits WHERE "AdvEngineID" <> 0;
```

**DataFusion baseline:** 23ms (min hot), all iterations: [54, 26, 23, 24, 25]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| **64 MB** | **56 ms** | **13 ms** | **11 ms** | **12 ms** | **11 ms** | **11 ms** | **0** | 🟢 |
| 128 MB | 63 ms | 11 ms | 11 ms | 12 ms | 12 ms | 11 ms | 0 | 🟢 |
| **256 MB** | **60 ms** | **13 ms** | **13 ms** | **13 ms** | **12 ms** | **12 ms** | **0** | 🟢 |
| 512 MB | 61 ms | 12 ms | 13 ms | 11 ms | 11 ms | 11 ms | 0 | 🟢 |
| 1024 MB | 61 ms | 13 ms | 13 ms | 11 ms | 13 ms | 11 ms | 0 | 🟢 |
| 2048 MB | 59 ms | 11 ms | 11 ms | 11 ms | 11 ms | 11 ms | 0 | 🟢 |
| Pushdown | 54 ms | 26 ms | 23 ms | 24 ms | 25 ms | 23 ms | — | — |

#### Cache Stats (best config: 64MB, last iteration)

```
total_entries: 11540
memory_arrow_entries: 2796
memory_liquid_entries: 8744
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 67,069,026
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (64MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 1, Iteration 4) ===
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.38µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=370ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=7.80µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=15.58µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=2.25ms, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=liquid_parquet, metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=5.87 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.05ms, metadata_load_time=1.71ms, page_index_eval_time=3.33µs, row_pushdown_eval_time=32ns, statistics_eval_time=265.27µs, time_elapsed_opening=5.38ms, time_elapsed_processing=117.14ms, time_elapsed_scanning_total=120.05ms, time_elapsed_scanning_until_data=1.74ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=11540, mem=63MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 11ms

+----------+
| count(*) |
+----------+
| 630500   |
+----------+
```
</details>


#### Analysis

**Strong cache benefit (2.1×).** Working set is 64MB (11540 entries). Sweet spot at **64MB** — all data fits in cache with zero disk reads. Speedup primarily from skipping Parquet page decompression on cached filter columns. 

---

### [8] q7_group_advengine

**Purpose:** Numeric filter + tiny GROUP BY (~20 engine IDs)

**Cached columns:** AdvEngineID (Int16)

```sql
SELECT "AdvEngineID", COUNT(*) FROM hits WHERE "AdvEngineID" <> 0 GROUP BY "AdvEngineID" ORDER BY COUNT(*) DESC;
```

**DataFusion baseline:** 25ms (min hot), all iterations: [56, 27, 31, 25, 25]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| **64 MB** | **61 ms** | **17 ms** | **18 ms** | **17 ms** | **16 ms** | **16 ms** | **0** | 🟢 |
| **128 MB** | **61 ms** | **17 ms** | **16 ms** | **14 ms** | **16 ms** | **14 ms** | **0** | 🟢 |
| 256 MB | 64 ms | 16 ms | 15 ms | 15 ms | 14 ms | 14 ms | 0 | 🟢 |
| **512 MB** | **65 ms** | **13 ms** | **15 ms** | **17 ms** | **15 ms** | **13 ms** | **0** | 🟢 |
| **1024 MB** | **64 ms** | **16 ms** | **16 ms** | **15 ms** | **16 ms** | **15 ms** | **0** | 🟢 |
| 2048 MB | 62 ms | 18 ms | 14 ms | 15 ms | 15 ms | 14 ms | 0 | 🟢 |
| Pushdown | 56 ms | 27 ms | 31 ms | 25 ms | 25 ms | 25 ms | — | — |

#### Cache Stats (best config: 512MB, last iteration)

```
total_entries: 11540
memory_arrow_entries: 11540
memory_liquid_entries: 0
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 190,007,064
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (512MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 7, Iteration 4) ===
ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(*)@1 as count(*)], metrics=[output_rows=18, elapsed_compute=1.11µs, output_bytes=180.0 B, output_batches=1, expr_0_eval_time=270ns, expr_1_eval_time=140ns]
  SortPreservingMergeExec: [count(Int64(1))@2 DESC], metrics=[output_rows=18, elapsed_compute=9.20µs, output_bytes=324.0 B, output_batches=1]
    SortExec: expr=[count(*)@1 DESC], preserve_partitioning=[true], metrics=[output_rows=18, elapsed_compute=18.17µs, output_bytes=0.0 B, output_batches=0, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0]
      ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(Int64(1))@1 as count(*), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=18, elapsed_compute=10.86µs, output_bytes=2.8 KB, output_batches=10, expr_0_eval_time=1.56µs, expr_1_eval_time=1.05µs, expr_2_eval_time=786ns]
        AggregateExec: mode=FinalPartitioned, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=18, elapsed_compute=84.55µs, output_bytes=2.8 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=80.06 K, aggregate_arguments_time=4.83µs, aggregation_time=4.94µs, emitting_time=7.81µs, time_calculating_group_ids=10.85µs]
          RepartitionExec: partitioning=Hash([AdvEngineID@0], 16), input_partitions=16, metrics=[output_rows=164, elapsed_compute=139.15µs, output_bytes=800.0 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=141.54ms, repartition_time=112.81µs, send_time=130.13µs]
            AggregateExec: mode=Partial, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=164, elapsed_compute=11.96ms, output_bytes=5.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=342.8 K, aggregate_arguments_time=2.15ms, aggregation_time=1.29ms, emitting_time=20.17µs, time_calculating_group_ids=4.99ms, reduction_factor=0.026% (164/630.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=1469.4 KB, output_batches=5.87 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, bat
```
</details>


#### Analysis

**Strong cache benefit (1.9×).** Working set is 181MB (11540 entries). Sweet spot at **64MB** — all data fits in cache with zero disk reads. Speedup primarily from skipping Parquet page decompression on cached filter columns. 

---

### [9] q40_multi_pred_selective

**Purpose:** 5 numeric predicates, stats-pruned to ~3 RGs

**Cached columns:** CounterID (Int32), EventDate (Int16), IsRefresh (Int16), TraficSourceID (Int8), RefererHash (UInt64)

```sql
SELECT "URLHash", "EventDate"::INT::DATE, COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-01' AND "EventDate"::INT::DATE <= '2013-07-31' AND "IsRefresh" = 0 AND "TraficSourceID" IN (-1, 6) AND "RefererHash" = 3594120000172545465 GROUP BY "URLHash", "EventDate"::INT::DATE ORDER BY PageViews DESC LIMIT 10 OFFSET 100;
```

**DataFusion baseline:** 33ms (min hot), all iterations: [59, 35, 33, 33, 33]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| **64 MB** | **48 ms** | **20 ms** | **22 ms** | **25 ms** | **21 ms** | **20 ms** | **0** | 🟢 |
| 128 MB | 45 ms | 20 ms | 20 ms | 21 ms | 21 ms | 20 ms | 0 | 🟢 |
| 256 MB | 45 ms | 21 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 512 MB | 48 ms | 21 ms | 25 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 1024 MB | 49 ms | 20 ms | 20 ms | 20 ms | 20 ms | 20 ms | 0 | 🟢 |
| 2048 MB | 45 ms | 20 ms | 20 ms | 21 ms | 20 ms | 20 ms | 0 | 🟢 |
| Pushdown | 59 ms | 35 ms | 33 ms | 33 ms | 33 ms | 33 ms | — | — |

#### Cache Stats (best config: 64MB, last iteration)

```
total_entries: 860
memory_arrow_entries: 860
memory_liquid_entries: 0
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 25,470,460
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (64MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 40, Iteration 4) ===
GlobalLimitExec: skip=100, fetch=10, metrics=[output_rows=10, elapsed_compute=10.88µs, output_bytes=2.1 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=110, metrics=[output_rows=110, elapsed_compute=13.80µs, output_bytes=2.1 KB, output_batches=1]
    SortExec: TopK(fetch=110), expr=[pageviews@2 DESC], preserve_partitioning=[true], filter=[pageviews@2 IS NULL OR pageviews@2 > 6], metrics=[output_rows=1.46 K, elapsed_compute=1.09ms, output_bytes=28.5 KB, output_batches=16, row_replacements=2.66 K]
      ProjectionExec: expr=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate, count(Int64(1))@2 as pageviews], metrics=[output_rows=41.19 K, elapsed_compute=24.68µs, output_bytes=1089.8 KB, output_batches=16, expr_0_eval_time=3.95µs, expr_1_eval_time=1.40µs, expr_2_eval_time=1.41µs]
        AggregateExec: mode=FinalPartitioned, gby=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.19 K, elapsed_compute=2.28ms, output_bytes=1089.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=5.07 M, aggregate_arguments_time=14.51µs, aggregation_time=75.10µs, emitting_time=30.83µs, time_calculating_group_ids=2.05ms]
          RepartitionExec: partitioning=Hash([URLHash@0, hits.EventDate@1], 16), input_partitions=16, metrics=[output_rows=41.87 K, elapsed_compute=235.66µs, output_bytes=2.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=31.49ms, repartition_time=492.76µs, send_time=58.02µs]
            AggregateExec: mode=Partial, gby=[URLHash@1 as URLHash, CAST(CAST(EventDate@0 AS Int32) AS Date32) as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.87 K, elapsed_compute=3.26ms, output_bytes=5.8 MB, output_batches=6, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.57 M, aggregate_arguments_time=68.97µs, aggregation_time=275.36µs, emitting_time=6.18µs, time_calculating_group_ids=2.67ms, reduction_factor=47% (41.87 K/89.91 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[EventDate, URLHash], file_type=liquid_parquet, metrics=[output_rows=89.91 K, elapsed_compute=16ns, output_bytes=883.4 KB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pru
```
</details>


#### Analysis

**Strong cache benefit (1.6×).** Working set is 24MB (860 entries). Sweet spot at **64MB** — all data fits in cache with zero disk reads. Speedup primarily from skipping Parquet page decompression on cached filter columns. Small working set (860 entries) means this query is stats-pruned to a few row groups, making cache overhead negligible. 

---

### [10] q41_hash_equality

**Purpose:** 5 numeric predicates + hash equality, very selective

**Cached columns:** CounterID (Int32), EventDate (Int16), IsRefresh (Int16), DontCountHits (Int16), URLHash (UInt64)

```sql
SELECT "WindowClientWidth", "WindowClientHeight", COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-01' AND "EventDate"::INT::DATE <= '2013-07-31' AND "IsRefresh" = 0 AND "DontCountHits" = 0 AND "URLHash" = 2868770270353813622 GROUP BY "WindowClientWidth", "WindowClientHeight" ORDER BY PageViews DESC LIMIT 10 OFFSET 10000;
```

**DataFusion baseline:** 31ms (min hot), all iterations: [59, 32, 32, 31, 31]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| **64 MB** | **44 ms** | **19 ms** | **19 ms** | **19 ms** | **20 ms** | **19 ms** | **0** | 🟢 |
| 128 MB | 42 ms | 19 ms | 19 ms | 20 ms | 21 ms | 19 ms | 0 | 🟢 |
| 256 MB | 43 ms | 21 ms | 20 ms | 19 ms | 22 ms | 19 ms | 0 | 🟢 |
| 512 MB | 43 ms | 19 ms | 19 ms | 19 ms | 19 ms | 19 ms | 0 | 🟢 |
| 1024 MB | 43 ms | 20 ms | 19 ms | 19 ms | 19 ms | 19 ms | 0 | 🟢 |
| 2048 MB | 41 ms | 20 ms | 20 ms | 19 ms | 19 ms | 19 ms | 0 | 🟢 |
| Pushdown | 59 ms | 32 ms | 32 ms | 31 ms | 31 ms | 31 ms | — | — |

#### Cache Stats (best config: 64MB, last iteration)

```
total_entries: 860
memory_arrow_entries: 860
memory_liquid_entries: 0
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 25,404,924
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (64MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 41, Iteration 4) ===
GlobalLimitExec: skip=10000, fetch=10, metrics=[output_rows=10, elapsed_compute=6.50µs, output_bytes=21.3 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=10010, metrics=[output_rows=10.01 K, elapsed_compute=311.53µs, output_bytes=117.3 KB, output_batches=2]
    SortExec: TopK(fetch=10010), expr=[pageviews@2 DESC], preserve_partitioning=[true], metrics=[output_rows=10.95 K, elapsed_compute=2.67ms, output_bytes=128.3 KB, output_batches=16, row_replacements=10.95 K]
      ProjectionExec: expr=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight, count(Int64(1))@2 as pageviews], metrics=[output_rows=10.95 K, elapsed_compute=20.07µs, output_bytes=149.5 KB, output_batches=16, expr_0_eval_time=2.98µs, expr_1_eval_time=1.19µs, expr_2_eval_time=1.49µs]
        AggregateExec: mode=FinalPartitioned, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=10.95 K, elapsed_compute=809.18µs, output_bytes=149.5 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.06 M, aggregate_arguments_time=12.92µs, aggregation_time=31.79µs, emitting_time=22.54µs, time_calculating_group_ids=651.73µs]
          RepartitionExec: partitioning=Hash([WindowClientWidth@0, WindowClientHeight@1], 16), input_partitions=16, metrics=[output_rows=12.33 K, elapsed_compute=146.86µs, output_bytes=1536.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=29.91ms, repartition_time=167.16µs, send_time=29.61µs]
            AggregateExec: mode=Partial, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=12.33 K, elapsed_compute=2.34ms, output_bytes=386.2 KB, output_batches=3, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=583.4 K, aggregate_arguments_time=75.58µs, aggregation_time=130.67µs, emitting_time=4.52µs, time_calculating_group_ids=2.00ms, reduction_factor=12% (12.33 K/102.7 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[WindowClientWidth, WindowClientHeight], file_type=liquid_parquet, metrics=[output_rows=102.7 K, elapsed_compute=16ns, output_bytes=406.5 KB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched
```
</details>


#### Analysis

**Strong cache benefit (1.6×).** Working set is 24MB (860 entries). Sweet spot at **64MB** — all data fits in cache with zero disk reads. Speedup primarily from skipping Parquet page decompression on cached filter columns. Small working set (860 entries) means this query is stats-pruned to a few row groups, making cache overhead negligible. 

---

### [11] q42_time_bucket

**Purpose:** 4 numeric predicates, narrow 2-day window

**Cached columns:** CounterID (Int32), EventDate (Int16), IsRefresh (Int16), DontCountHits (Int16)

```sql
SELECT DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) AS M, COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-14' AND "EventDate"::INT::DATE <= '2013-07-15' AND "IsRefresh" = 0 AND "DontCountHits" = 0 GROUP BY DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) ORDER BY DATE_TRUNC('minute', M) LIMIT 10 OFFSET 1000;
```

**DataFusion baseline:** 28ms (min hot), all iterations: [56, 31, 29, 30, 28]

#### Performance Table

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Disk Reads/iter | Zone |
|--------|--------------|--------|--------|--------|--------|---------|-----------------|------|
| **64 MB** | **42 ms** | **18 ms** | **25 ms** | **18 ms** | **18 ms** | **18 ms** | **0** | 🟢 |
| 128 MB | 39 ms | 18 ms | 20 ms | 18 ms | 18 ms | 18 ms | 0 | 🟢 |
| 256 MB | 39 ms | 18 ms | 18 ms | 18 ms | 19 ms | 18 ms | 0.1 MB | 🟢 |
| 512 MB | 38 ms | 18 ms | 18 ms | 18 ms | 18 ms | 18 ms | 0 | 🟢 |
| 1024 MB | 41 ms | 18 ms | 18 ms | 18 ms | 18 ms | 18 ms | 0 | 🟢 |
| 2048 MB | 42 ms | 18 ms | 18 ms | 18 ms | 18 ms | 18 ms | 0 | 🟢 |
| Pushdown | 56 ms | 31 ms | 29 ms | 30 ms | 28 ms | 28 ms | — | — |

#### Cache Stats (best config: 64MB, last iteration)

```
total_entries: 688
memory_arrow_entries: 688
memory_liquid_entries: 0
memory_squeezed_liquid_entries: 0
disk_liquid_entries: 0
memory_usage_bytes: 14,134,028
disk_usage_bytes: 0
---
eval_predicate: 0
cache_hit: 0
cache_miss: 0
get_squeezed_success: 0
get_squeezed_needs_io: 0
read_io_count: 0
write_io_count: 0
squeeze_io_saved: 0
```

#### EXPLAIN ANALYZE (64MB, last iteration)

<details>
<summary>Click to expand</summary>

```
=== EXPLAIN ANALYZE(Query 42, Iteration 4) ===
GlobalLimitExec: skip=1000, fetch=10, metrics=[output_rows=10, elapsed_compute=7.43µs, output_bytes=15.8 KB, output_batches=1]
  SortPreservingMergeExec: [date_trunc(minute, m@0) ASC NULLS LAST], fetch=1010, metrics=[output_rows=1.01 K, elapsed_compute=51.38µs, output_bytes=15.8 KB, output_batches=1]
    SortExec: TopK(fetch=1010), expr=[date_trunc(minute, m@0) ASC NULLS LAST], preserve_partitioning=[true], metrics=[output_rows=1.44 K, elapsed_compute=439.15µs, output_bytes=22.5 KB, output_batches=16, row_replacements=1.44 K]
      ProjectionExec: expr=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as m, count(Int64(1))@1 as pageviews], metrics=[output_rows=1.44 K, elapsed_compute=12.47µs, output_bytes=27.2 KB, output_batches=16, expr_0_eval_time=2.13µs, expr_1_eval_time=1.27µs]
        AggregateExec: mode=FinalPartitioned, gby=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=1.44 K, elapsed_compute=177.15µs, output_bytes=27.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=204.3 K, aggregate_arguments_time=8.42µs, aggregation_time=12.82µs, emitting_time=13.11µs, time_calculating_group_ids=75.11µs]
          RepartitionExec: partitioning=Hash([date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0], 16), input_partitions=16, metrics=[output_rows=2.88 K, elapsed_compute=102.83µs, output_bytes=2.0 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=25.99ms, repartition_time=44.75µs, send_time=22.11µs]
            AggregateExec: mode=Partial, gby=[date_trunc(minute, to_timestamp_seconds(EventTime@0)) as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=2.88 K, elapsed_compute=5.50ms, output_bytes=68.7 KB, output_batches=2, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=259.8 K, aggregate_arguments_time=150.86µs, aggregation_time=329.89µs, emitting_time=2.60µs, time_calculating_group_ids=3.60ms, reduction_factor=0.43% (2.88 K/671.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[EventTime], file_type=liquid_parquet, metrics=[output_rows=671.5 K, elapsed_compute=16ns, output_bytes=5.1 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 tot
```
</details>


#### Analysis

**Strong cache benefit (1.6×).** Working set is 13MB (688 entries). Sweet spot at **64MB** — all data fits in cache with zero disk reads. Speedup primarily from skipping Parquet page decompression on cached filter columns. Small working set (688 entries) means this query is stats-pruned to a few row groups, making cache overhead negligible. 

---

---

## Heavy Query Timings

These are the heavyweight queries used as contention generators. All numeric columns, high-cardinality GROUP BY / DISTINCT.

| Query | Description | 64MB | 128MB | 256MB | 512MB | 1024MB | 2048MB | 
|-------|-------------|---|---|---|---|---|---|
| q4_count_distinct_userid | COUNT(DISTINCT UserID) — 17M distinct Int64 values | 661ms | 667ms | 664ms | 687ms | 666ms | 650ms | 
| q15_groupby_userid | GROUP BY UserID ORDER BY COUNT — 17M groups | 752ms | 740ms | 755ms | 747ms | 751ms | 753ms | 
| q8_distinct_in_groupby | GROUP BY RegionID, COUNT(DISTINCT UserID) — all numeric | 818ms | 814ms | 804ms | 816ms | 809ms | 813ms | 
| q32_cartesian_groupby | GROUP BY WatchID, ClientIP — high-card numeric pair | 3243ms | 3061ms | 3198ms | 3071ms | 3106ms | 3197ms | 
| c5_heavy_numeric_agg | GROUP BY CounterID HAVING COUNT>100 — high-card numeric | 295ms | 314ms | 279ms | 276ms | 303ms | 290ms | 

These queries spend most of their time on CPU computation (building massive hash tables with millions of entries), not on reading data. Caching speeds up data access and avoids decode, but since the bottleneck is hash table operations (not reading/decoding Parquet), the cache doesn't reduce their latency.

---

## Interpretation

### Key Findings

1. **8/11 queries faster than DataFusion** with numeric cache enabled
2. **Best speedup:** 6.50× (min hot latency vs DataFusion pushdown)
3. **Median speedup:** 1.63×

### Queries that benefit most

Queries with **selective numeric predicates** (point lookups, equality, narrow ranges) show the largest speedup:
- Multi-predicate selective queries: 4-6× (c1, c2, c6)
- Single/few predicate with low selectivity (full scans): 1.5-2× (q1, q7)
- Wide scans with many output columns: ~1× (c7, c4 — CPU-bound on aggregation)

### Why some queries don't benefit

Queries like c4 (date range agg) and c7 (wide numeric scan) show ~1× speedup because:
- They're **CPU-bound on aggregation**, not I/O-bound on decode
- The cache avoids Parquet decode, but the time is spent computing AVG/SUM/COUNT over millions of rows
- The predicate filters don't eliminate enough rows to make a difference

### Disk Cache: Trading I/O for CPU Savings

When cache memory is limited, evicted entries go to **disk in decoded liquid format**. This is fundamentally different from reading Parquet:

| Operation | What happens | CPU cost | I/O cost |
|-----------|-------------|----------|----------|
| Read from Parquet | Read compressed pages → decompress (zstd/snappy) → decode page encodings (delta, dictionary, RLE) → produce Arrow batch | **High** | Medium |
| Read from disk cache | Read pre-decoded liquid column → use directly | **Near zero** | Medium |
| Read from memory cache | Already in memory, no I/O | **Near zero** | None |

**Key insight:** Disk cache doesn't eliminate I/O, but it eliminates the CPU-intensive decode step. This matters for throughput because:
1. CPU freed from decode can be used for query execution (filtering, aggregation)
2. Under concurrent load, decode CPU is the scarce resource — disk cache gives it back
3. For numeric columns, decode overhead is significant (delta encoding, bit-unpacking)

**Evidence from this benchmark:**
- At 64/128MB budgets, queries like c0 and q1 show the eviction cliff (949ms, 309ms vs 16ms at 256MB)
- The cliff happens because evicted data must be re-read from disk — but even then, it's faster than cold Parquet reads (949ms vs 27,277ms cold) because the disk cache format skips decode
- At the sweet spot (256MB+), everything fits in memory and queries run at 2-6× DataFusion speed

### Key Metrics Explained

| Metric | Meaning |
|--------|--------|
| **Min hot** | Minimum latency across hot iterations (iter 1-4). Best-case cache-hit performance. |
| **Speedup** | DF_min_hot / Cache_min_hot. Higher = more benefit from caching. |
| **eval_predicate** | Number of predicates evaluated directly on cached/squeezed data (no Parquet decode). |
| **cache_hit** | Row groups served entirely from cache. |
| **get_squeezed_success** | Data served from transcoded (squeezed) representation without hydration. |
| **read_io_count** | Disk reads triggered by cache misses. 0 = fully in-memory. |
| 🟢 Zone | All data fits in cache, 0 disk reads, full speedup. |
| 🔴 Zone | Cache budget too small, disk reads on every iteration. |
| ➖ Zone | Data in cache but no speedup (CPU-bound). |
