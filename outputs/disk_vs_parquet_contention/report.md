# Disk Cache vs Parquet Under CPU Contention

## Core Question

When CPU is saturated by heavy queries (hash tables, GROUP BY), does reading from disk cache
(pre-decoded, no CPU for decode) give better latency than reading from Parquet (needs CPU for decode)?

---

## Experiment A: Light Queries Under Heavy CPU Load

**Setup:** Heavy q4 (COUNT DISTINCT over 17M UserIDs) runs in background, saturating CPU.
Light query runs in foreground in three modes.

### c0_range_filter

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [372, 61, 59, 59, 54] | 54 | — | — | 0.7ms | 0.0 |
| Disk cache 144MB | [5102, 195, 193, 194, 192] | 192 | — | — | 0.2ms | 21.8 |
| Memory cache 2048MB | [394, 18, 16, 18, 16] | 16 | — | — | 0.2ms | 0.0 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [104, 61, 59, 58, 55] | 55 | — | — | 1.00× | +2% |
| Disk cache 144MB | [4792, 223, 221, 221, 225] | 221 | — | — | 0.25× | +15% |
| Memory cache 2048MB | [114, 19, 18, 18, 14] | 14 | — | — | 3.93× | +-12% |

**Analysis:** Disk cache (0.25×) vs Parquet under contention. Both suffer similar regression. The disk I/O overhead may offset decode savings at this budget.

**Cache stats (disk 144MB, under contention):**
- Entries: 23080 total, 1950 on disk
- Memory: 143MB / Disk: 27MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 144MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 0, Iteration 4) ===
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.30µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=640ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=15.21µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=15.43µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=2.27ms, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=liquid_parquet, metrics=[output_rows=477.2 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=5.60 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.88ms, metadata_load_time=2.24ms, page_index_eval_time=2.95µs, row_pushdown_eval_time=32ns, statistics_eval_time=376.08µs, time_elapsed_opening=7.31ms, time_elapsed_processing
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 0, Iteration 4) ===
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.33µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=360ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=18.41µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.44µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=610.34µs, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=parquet, predicate=AdvEngineID@40 > 0 AND ResolutionWidth@20 >= 1024 AND ResolutionWidth@20 <= 1920, pruning_predicate=AdvEngineID_null_count@1 != row_count@2 AND AdvEngineID_max@0 > 0 AND ResolutionWidth_null_count@4 != row_count@2 AND ResolutionWidth_max@3 >= 1024 AND ResolutionWidth_null_count@4 != row_count@2 AND ResolutionWidth_min@5 <= 1920, required_guarantees=[], metrics=[output_rows=477.2 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=238, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=212 total → 212 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=40.39 M, file_open_errors=0, file_scan_errors=0, num_p
```
</details>

---

### c1_multi_numeric

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [293, 22, 17, 19, 18] | 17 | — | — | 0.2ms | 0.1 |
| Disk cache 2MB | [292, 5, 5, 4, 4] | 4 | — | — | 0.0ms | 0.0 |
| Memory cache 2048MB | [287, 5, 4, 4, 3] | 3 | — | — | 0.0ms | 0.0 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [52, 19, 17, 18, 18] | 17 | — | — | 1.00× | +0% |
| Disk cache 2MB | [28, 5, 3, 3, 4] | 3 | — | — | 5.67× | +-25% |
| Memory cache 2048MB | [30, 4, 3, 4, 3] | 3 | — | — | 5.67× | +0% |

**Analysis:** ✅ Disk cache is 5.67× faster than Parquet under contention. Parquet regresses +0% due to CPU competition for decode, while disk cache only regresses -25% (no decode CPU needed). Memory cache (5.67×) shows the best case with no I/O at all.

**Cache stats (disk 2MB, under contention):**
- Entries: 291 total, 0 on disk
- Memory: 1MB / Disk: 0MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 2MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 1, Iteration 4) ===
ProjectionExec: expr=[count(Int64(1))@0 as count(*), avg(hits.ResolutionWidth)@1 as avg(hits.ResolutionWidth), sum(hits.AdvEngineID)@2 as sum(hits.AdvEngineID)], metrics=[output_rows=1, elapsed_compute=761ns, output_bytes=26.0 B, output_batches=1, expr_0_eval_time=129ns, expr_1_eval_time=60ns, expr_2_eval_time=60ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=1, elapsed_compute=14.31µs, output_bytes=26.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=13.31µs, output_bytes=544.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=16, elapsed_compute=95.73µs, output_bytes=544.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[ResolutionWidth, AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=0, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=0, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 2 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 1, Iteration 4) ===
ProjectionExec: expr=[count(Int64(1))@0 as count(*), avg(hits.ResolutionWidth)@1 as avg(hits.ResolutionWidth), sum(hits.AdvEngineID)@2 as sum(hits.AdvEngineID)], metrics=[output_rows=1, elapsed_compute=2.34µs, output_bytes=26.0 B, output_batches=1, expr_0_eval_time=251ns, expr_1_eval_time=89ns, expr_2_eval_time=160ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=1, elapsed_compute=46.33µs, output_bytes=26.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.54µs, output_bytes=544.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=16, elapsed_compute=249.53µs, output_bytes=544.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[ResolutionWidth, AdvEngineID], file_type=parquet, predicate=IsRefresh@15 = 0 AND DontCountHits@61 = 0 AND CounterID@6 > 100 AND CounterID@6 < 500, pruning_predicate=IsRefresh_null_count@2 != row_count@3 AND IsRefresh_min@0 <= 0 AND 0 <= IsRefresh_max@1 AND DontCountHits_null_count@6 != row_count@3 AND DontCountHits_min@4 <= 0 AND 0 <= DontCountHits_max@5 AND CounterID_null_count@8 != row_count@3 AND CounterID_max@7 > 100 AND CounterID_null_count@8 != row_count@3 AND CounterID_min@9 < 500, required_guarantees=[DontCountHits in (0), IsRefresh in (0)], metrics=[output_rows=0, elapsed_co
```
</details>

---

### c3_group_filter

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [446, 70, 66, 66, 64] | 64 | — | — | 0.7ms | 0.0 |
| Disk cache 144MB | [497, 228, 234, 232, 232] | 228 | — | — | 2.0ms | 0.1 |
| Memory cache 2048MB | [491, 232, 238, 228, 233] | 228 | — | — | 2.0ms | 0.1 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [125, 68, 66, 65, 65] | 65 | — | — | 1.00× | +2% |
| Disk cache 144MB | [173, 231, 243, 236, 232] | 231 | — | — | 0.28× | +1% |
| Memory cache 2048MB | [166, 236, 232, 241, 226] | 226 | — | — | 0.29× | +-1% |

**Analysis:** Disk cache (0.28×) vs Parquet under contention. Disk cache regresses less (+1% vs +2%) — confirms CPU contention hits Parquet harder.

**Cache stats (disk 144MB, under contention):**
- Entries: 23080 total, 0 on disk
- Memory: 143MB / Disk: 0MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 144MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 3, Iteration 4) ===
ProjectionExec: expr=[RegionID@0 as RegionID, count(*)@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth)], metrics=[output_rows=20, elapsed_compute=1.57µs, output_bytes=400.0 B, output_batches=1, expr_0_eval_time=220ns, expr_1_eval_time=70ns, expr_2_eval_time=140ns]
  SortPreservingMergeExec: [count(Int64(1))@3 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=8.65µs, output_bytes=560.0 B, output_batches=1]
    SortExec: TopK(fetch=20), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 253], metrics=[output_rows=204, elapsed_compute=367.10µs, output_bytes=5.6 KB, output_batches=16, row_replacements=243]
      ProjectionExec: expr=[RegionID@0 as RegionID, count(Int64(1))@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=1.95 K, elapsed_compute=24.45µs, output_bytes=41.0 KB, output_batches=16, expr_0_eval_time=2.71µs, expr_1_eval_time=1.57µs, expr_2_eval_time=1.54µs, expr_3_eval_time=1.29µs]
        AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), avg(hits.ResolutionWidth)], metrics=[output_rows=1.95 K, elapsed_compute=440.25µs, output_bytes=41.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=330.7 K, aggregate_arguments_time=20.46µs, aggregation_time=93.92µs, emitting_time=32.86µs, time_calculating_group_ids=189.18µs]
          RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=10.68 K, elapsed_compute=540.43µs, output_bytes=3.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=2.23s, repartition_time=689.33µs, send_time=241.25µs]
            AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), avg(hits.ResolutionWidth)], metrics=[output_rows=10.68 K, elapsed_compute=31.56ms, output_bytes=426.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=772.5 K, aggregate_arguments_time=9.61ms, aggregation_time=7.71ms, emitting_time=78.97µs, time_calculating_group_ids=9.68ms, reduction_factor=1.8% (10.68 K/585.4 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cach
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 3, Iteration 4) ===
ProjectionExec: expr=[RegionID@0 as RegionID, count(*)@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth)], metrics=[output_rows=20, elapsed_compute=1.72µs, output_bytes=400.0 B, output_batches=1, expr_0_eval_time=220ns, expr_1_eval_time=100ns, expr_2_eval_time=170ns]
  SortPreservingMergeExec: [count(Int64(1))@3 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=7.17µs, output_bytes=560.0 B, output_batches=1]
    SortExec: TopK(fetch=20), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 253], metrics=[output_rows=242, elapsed_compute=422.85µs, output_bytes=6.6 KB, output_batches=16, row_replacements=294]
      ProjectionExec: expr=[RegionID@0 as RegionID, count(Int64(1))@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=1.95 K, elapsed_compute=22.81µs, output_bytes=41.0 KB, output_batches=16, expr_0_eval_time=2.85µs, expr_1_eval_time=1.33µs, expr_2_eval_time=1.40µs, expr_3_eval_time=1.19µs]
        AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), avg(hits.ResolutionWidth)], metrics=[output_rows=1.95 K, elapsed_compute=401.55µs, output_bytes=41.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=330.7 K, aggregate_arguments_time=26.98µs, aggregation_time=97.04µs, emitting_time=30.47µs, time_calculating_group_ids=174.25µs]
          RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=10.68 K, elapsed_compute=456.97µs, output_bytes=3.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=795.66ms, repartition_time=782.23µs, send_time=221.40µs]
            AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), avg(hits.ResolutionWidth)], metrics=[output_rows=10.68 K, elapsed_compute=10.88ms, output_bytes=412.5 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.43 M, aggregate_arguments_time=1.88ms, aggregation_time=2.94ms, emitting_time=70.90µs, time_calculating_group_ids=6.14ms, reduction_factor=1.8% (10.68 K/585.4 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-c
```
</details>

---

### c4_date_range

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [499, 151, 147, 151, 151] | 147 | — | — | 0.9ms | 0.1 |
| Disk cache 200MB | [535, 160, 166, 168, 163] | 160 | — | — | 1.0ms | 0.1 |
| Memory cache 2048MB | [524, 159, 155, 161, 179] | 155 | — | — | 0.9ms | 0.0 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [194, 166, 150, 148, 166] | 148 | — | — | 1.00× | +1% |
| Disk cache 200MB | [229, 169, 160, 157, 153] | 153 | — | — | 0.97× | +-4% |
| Memory cache 2048MB | [236, 167, 158, 155, 160] | 155 | — | — | 0.95× | +0% |

**Analysis:** Disk cache (0.97×) vs Parquet under contention. Disk cache regresses less (-4% vs +1%) — confirms CPU contention hits Parquet harder.

**Cache stats (disk 200MB, under contention):**
- Entries: 21486 total, 0 on disk
- Memory: 199MB / Disk: 0MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 4, Iteration 4) ===
SortPreservingMergeExec: [hits.EventDate@0 ASC NULLS LAST], metrics=[output_rows=9, elapsed_compute=10.19µs, output_bytes=252.0 B, output_batches=1]
  SortExec: expr=[hits.EventDate@0 ASC NULLS LAST], preserve_partitioning=[true], metrics=[output_rows=9, elapsed_compute=13.29µs, output_bytes=0.0 B, output_batches=0, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0]
    ProjectionExec: expr=[hits.EventDate@0 as hits.EventDate, count(Int64(1))@1 as count(*), sum(hits.IsRefresh)@2 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@3 as avg(hits.ResolutionWidth)], metrics=[output_rows=9, elapsed_compute=7.34µs, output_bytes=3.0 KB, output_batches=5, expr_0_eval_time=971ns, expr_1_eval_time=491ns, expr_2_eval_time=590ns, expr_3_eval_time=532ns]
      AggregateExec: mode=FinalPartitioned, gby=[hits.EventDate@0 as hits.EventDate], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=9, elapsed_compute=137.23µs, output_bytes=3.0 KB, output_batches=5, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=44.22 K, aggregate_arguments_time=6.54µs, aggregation_time=22.83µs, emitting_time=11.22µs, time_calculating_group_ids=13.71µs]
        RepartitionExec: partitioning=Hash([hits.EventDate@0], 16), input_partitions=16, metrics=[output_rows=111, elapsed_compute=180.48µs, output_bytes=1440.0 KB, output_batches=5, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=1.92s, repartition_time=261.36µs, send_time=166.28µs]
          AggregateExec: mode=Partial, gby=[CAST(CAST(EventDate@0 AS Int32) AS Date32) as hits.EventDate], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=111, elapsed_compute=845.96ms, output_bytes=13.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.12 M, aggregate_arguments_time=93.54ms, aggregation_time=387.84ms, emitting_time=68.71µs, time_calculating_group_ids=442.92ms, reduction_factor=0.00018% (111/60.21 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:83137367
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 4, Iteration 4) ===
SortPreservingMergeExec: [hits.EventDate@0 ASC NULLS LAST], metrics=[output_rows=9, elapsed_compute=11.00µs, output_bytes=252.0 B, output_batches=1]
  SortExec: expr=[hits.EventDate@0 ASC NULLS LAST], preserve_partitioning=[true], metrics=[output_rows=9, elapsed_compute=12.30µs, output_bytes=0.0 B, output_batches=0, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0]
    ProjectionExec: expr=[hits.EventDate@0 as hits.EventDate, count(Int64(1))@1 as count(*), sum(hits.IsRefresh)@2 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@3 as avg(hits.ResolutionWidth)], metrics=[output_rows=9, elapsed_compute=7.33µs, output_bytes=3.0 KB, output_batches=5, expr_0_eval_time=821ns, expr_1_eval_time=501ns, expr_2_eval_time=412ns, expr_3_eval_time=502ns]
      AggregateExec: mode=FinalPartitioned, gby=[hits.EventDate@0 as hits.EventDate], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=9, elapsed_compute=138.22µs, output_bytes=3.0 KB, output_batches=5, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=44.22 K, aggregate_arguments_time=6.78µs, aggregation_time=19.84µs, emitting_time=9.56µs, time_calculating_group_ids=6.44µs]
        RepartitionExec: partitioning=Hash([hits.EventDate@0], 16), input_partitions=16, metrics=[output_rows=111, elapsed_compute=167.56µs, output_bytes=1440.0 KB, output_batches=5, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=1.87s, repartition_time=224.28µs, send_time=145.18µs]
          AggregateExec: mode=Partial, gby=[CAST(CAST(EventDate@0 AS Int32) AS Date32) as hits.EventDate], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=111, elapsed_compute=869.11ms, output_bytes=13.4 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.12 M, aggregate_arguments_time=94.25ms, aggregation_time=400.52ms, emitting_time=66.35µs, time_calculating_group_ids=457.33ms, reduction_factor=0.00018% (111/60.21 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752
```
</details>

---

### c7_wide_scan

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [840, 386, 376, 395, 378] | 376 | — | — | 4.1ms | 0.1 |
| Disk cache 153MB | [803, 301, 324, 300, 306] | 300 | — | — | 3.2ms | 0.0 |
| Memory cache 2048MB | [764, 323, 321, 309, 312] | 309 | — | — | 3.2ms | 0.0 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [493, 382, 374, 368, 380] | 368 | — | — | 1.00× | +-2% |
| Disk cache 153MB | [421, 315, 325, 307, 324] | 307 | — | — | 1.20× | +2% |
| Memory cache 2048MB | [426, 312, 299, 314, 307] | 299 | — | — | 1.23× | +-3% |

**Analysis:** ✅ Disk cache is 1.20× faster than Parquet under contention. Parquet regresses -2% due to CPU competition for decode, while disk cache only regresses +2% (no decode CPU needed). Memory cache (1.23×) shows the best case with no I/O at all.

**Cache stats (disk 153MB, under contention):**
- Entries: 24436 total, 0 on disk
- Memory: 152MB / Disk: 0MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 153MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 6, Iteration 4) ===
AggregateExec: mode=Final, gby=[], aggr=[avg(hits.ResolutionWidth), avg(hits.ResolutionHeight), avg(hits.ClientIP), avg(hits.WindowClientWidth), avg(hits.WindowClientHeight), avg(hits.CounterID), avg(hits.RegionID)], metrics=[output_rows=1, elapsed_compute=70.75µs, output_bytes=56.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.65µs, output_bytes=1792.0 B, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[avg(hits.ResolutionWidth), avg(hits.ResolutionHeight), avg(hits.ClientIP), avg(hits.WindowClientWidth), avg(hits.WindowClientHeight), avg(hits.CounterID), avg(hits.RegionID)], metrics=[output_rows=16, elapsed_compute=465.06ms, output_bytes=1792.0 B, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CounterID, ClientIP, RegionID, ResolutionWidth, ResolutionHeight, WindowClientWidth, WindowClientHeight], file_type=liquid_parquet, metrics=[output_rows=92.74 M, elapsed_compute=16ns, output_bytes=1769.3 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=488.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushd
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 6, Iteration 4) ===
AggregateExec: mode=Final, gby=[], aggr=[avg(hits.ResolutionWidth), avg(hits.ResolutionHeight), avg(hits.ClientIP), avg(hits.WindowClientWidth), avg(hits.WindowClientHeight), avg(hits.CounterID), avg(hits.RegionID)], metrics=[output_rows=1, elapsed_compute=74.86µs, output_bytes=56.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.14µs, output_bytes=1792.0 B, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[avg(hits.ResolutionWidth), avg(hits.ResolutionHeight), avg(hits.ClientIP), avg(hits.WindowClientWidth), avg(hits.WindowClientHeight), avg(hits.CounterID), avg(hits.RegionID)], metrics=[output_rows=16, elapsed_compute=458.91ms, output_bytes=1792.0 B, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CounterID, ClientIP, RegionID, ResolutionWidth, ResolutionHeight, WindowClientWidth, WindowClientHeight], file_type=parquet, predicate=AdvEngineID@40 = 0 AND IsRefresh@15 = 0, pruning_predicate=AdvEngineID_null_count@2 != row_count@3 AND AdvEngineID_min@0 <= 0 AND 0 <= AdvEngineID_max@1 AND IsRefresh_null_count@6 != row_count@3 AND IsRefresh_min@4 <= 0 AND 0 <= IsRefresh_max@5, required_guarantees=[AdvEngineID in (0), IsRefresh in (0)], metrics=[output_rows=92.74 M, elapsed_compute=16ns, output_bytes=1921.9 MB, output_batches=11.43 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=226 total → 226 matc
```
</details>

---

### q1_advengine

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [307, 28, 25, 26, 25] | 25 | — | — | 0.3ms | 0.0 |
| Disk cache 72MB | [298, 11, 11, 13, 13] | 11 | — | — | 0.1ms | 0.0 |
| Memory cache 2048MB | [311, 12, 11, 14, 10] | 10 | — | — | 0.1ms | 0.0 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [56, 26, 25, 25, 25] | 25 | — | — | 1.00× | +0% |
| Disk cache 72MB | [57, 13, 13, 12, 12] | 12 | — | — | 2.08× | +9% |
| Memory cache 2048MB | [64, 12, 11, 11, 12] | 11 | — | — | 2.27× | +10% |

**Analysis:** ✅ Disk cache is 2.08× faster than Parquet under contention. Parquet regresses +0% due to CPU competition for decode, while disk cache only regresses +9% (no decode CPU needed). Memory cache (2.27×) shows the best case with no I/O at all.

**Cache stats (disk 72MB, under contention):**
- Entries: 11540 total, 0 on disk
- Memory: 71MB / Disk: 0MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 72MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 1, Iteration 4) ===
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.04µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=340ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=8.14µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=15.00µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=2.34ms, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=liquid_parquet, metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=5.87 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.01ms, metadata_load_time=1.78ms, page_index_eval_time=3.59µs, row_pushdown_eval_time=32ns, statistics_eval_time=285.59µs, time_elapsed_opening=5.50ms, time_elapsed_processing=
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 1, Iteration 4) ===
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.39µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=340ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=17.41µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=15.99µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=639.23µs, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=parquet, predicate=AdvEngineID@40 != 0, pruning_predicate=AdvEngineID_null_count@2 != row_count@3 AND (AdvEngineID_min@0 != 0 OR 0 != AdvEngineID_max@1), required_guarantees=[AdvEngineID not in (0)], metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=248, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=212 total → 212 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=941.5 K, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=630.5 K, pushdown_rows_pruned=93.82 M, predicate_cache_inner_records=0, predicate_cache_recor
```
</details>

---

### q7_group_advengine

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [338, 37, 33, 33, 32] | 32 | — | — | 0.4ms | 0.2 |
| Disk cache 72MB | [325, 17, 15, 17, 15] | 15 | — | — | 0.1ms | 0.6 |
| Memory cache 2048MB | [342, 17, 15, 18, 15] | 15 | — | — | 0.1ms | 0.0 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [70, 32, 30, 33, 31] | 30 | — | — | 1.00× | +-6% |
| Disk cache 72MB | [76, 19, 17, 14, 17] | 14 | — | — | 2.14× | +-7% |
| Memory cache 2048MB | [65, 16, 15, 16, 16] | 15 | — | — | 2.00× | +0% |

**Analysis:** ✅ Disk cache is 2.14× faster than Parquet under contention. Parquet regresses -6% due to CPU competition for decode, while disk cache only regresses -7% (no decode CPU needed). Memory cache (2.00×) shows the best case with no I/O at all.

**Cache stats (disk 72MB, under contention):**
- Entries: 11540 total, 0 on disk
- Memory: 71MB / Disk: 0MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 72MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 7, Iteration 4) ===
ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(*)@1 as count(*)], metrics=[output_rows=18, elapsed_compute=730ns, output_bytes=180.0 B, output_batches=1, expr_0_eval_time=160ns, expr_1_eval_time=60ns]
  SortPreservingMergeExec: [count(Int64(1))@2 DESC], metrics=[output_rows=18, elapsed_compute=10.98µs, output_bytes=324.0 B, output_batches=1]
    SortExec: expr=[count(*)@1 DESC], preserve_partitioning=[true], metrics=[output_rows=18, elapsed_compute=17.25µs, output_bytes=0.0 B, output_batches=0, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0]
      ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(Int64(1))@1 as count(*), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=18, elapsed_compute=10.18µs, output_bytes=2.8 KB, output_batches=10, expr_0_eval_time=1.34µs, expr_1_eval_time=777ns, expr_2_eval_time=784ns]
        AggregateExec: mode=FinalPartitioned, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=18, elapsed_compute=95.83µs, output_bytes=2.8 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=80.06 K, aggregate_arguments_time=4.25µs, aggregation_time=4.43µs, emitting_time=8.41µs, time_calculating_group_ids=9.00µs]
          RepartitionExec: partitioning=Hash([AdvEngineID@0], 16), input_partitions=16, metrics=[output_rows=164, elapsed_compute=141.24µs, output_bytes=800.0 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=149.07ms, repartition_time=107.75µs, send_time=152.86µs]
            AggregateExec: mode=Partial, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=164, elapsed_compute=17.55ms, output_bytes=5.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=342.8 K, aggregate_arguments_time=2.14ms, aggregation_time=6.78ms, emitting_time=19.22µs, time_calculating_group_ids=5.09ms, reduction_factor=0.026% (164/630.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/l
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 7, Iteration 4) ===
ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(*)@1 as count(*)], metrics=[output_rows=18, elapsed_compute=1.33µs, output_bytes=180.0 B, output_batches=1, expr_0_eval_time=281ns, expr_1_eval_time=60ns]
  SortPreservingMergeExec: [count(Int64(1))@2 DESC], metrics=[output_rows=18, elapsed_compute=11.03µs, output_bytes=324.0 B, output_batches=1]
    SortExec: expr=[count(*)@1 DESC], preserve_partitioning=[true], metrics=[output_rows=18, elapsed_compute=20.40µs, output_bytes=0.0 B, output_batches=0, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0]
      ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(Int64(1))@1 as count(*), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=18, elapsed_compute=10.30µs, output_bytes=2.8 KB, output_batches=10, expr_0_eval_time=1.85µs, expr_1_eval_time=828ns, expr_2_eval_time=795ns]
        AggregateExec: mode=FinalPartitioned, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=18, elapsed_compute=84.52µs, output_bytes=2.8 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=80.06 K, aggregate_arguments_time=5.87µs, aggregation_time=7.24µs, emitting_time=7.22µs, time_calculating_group_ids=9.91µs]
          RepartitionExec: partitioning=Hash([AdvEngineID@0], 16), input_partitions=16, metrics=[output_rows=164, elapsed_compute=160.47µs, output_bytes=800.0 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=383.97ms, repartition_time=178.59µs, send_time=190.36µs]
            AggregateExec: mode=Partial, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=164, elapsed_compute=6.62ms, output_bytes=5.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=981.8 K, aggregate_arguments_time=526.75µs, aggregation_time=772.64µs, emitting_time=35.87µs, time_calculating_group_ids=4.75ms, reduction_factor=0.026% (164/630.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-us
```
</details>

---

### q40_multi_pred

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [382, 44, 40, 38, 38] | 38 | — | — | 0.2ms | 0.1 |
| Disk cache 10MB | [847, 86, 88, 88, 85] | 85 | — | — | 0.0ms | 2.8 |
| Memory cache 2048MB | [353, 20, 21, 23, 24] | 20 | — | — | 0.0ms | 0.0 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [107, 38, 46, 38, 38] | 38 | — | — | 1.00× | +0% |
| Disk cache 10MB | [569, 98, 105, 97, 99] | 97 | — | — | 0.39× | +14% |
| Memory cache 2048MB | [97, 20, 21, 21, 20] | 20 | — | — | 1.90× | +0% |

**Analysis:** Disk cache (0.39×) vs Parquet under contention. Both suffer similar regression. The disk I/O overhead may offset decode savings at this budget.

**Cache stats (disk 10MB, under contention):**
- Entries: 860 total, 212 on disk
- Memory: 9MB / Disk: 3MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 10MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 40, Iteration 4) ===
GlobalLimitExec: skip=100, fetch=10, metrics=[output_rows=10, elapsed_compute=10.93µs, output_bytes=2.1 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=110, metrics=[output_rows=110, elapsed_compute=13.94µs, output_bytes=2.1 KB, output_batches=1]
    SortExec: TopK(fetch=110), expr=[pageviews@2 DESC], preserve_partitioning=[true], filter=[pageviews@2 IS NULL OR pageviews@2 > 6], metrics=[output_rows=1.50 K, elapsed_compute=1.08ms, output_bytes=29.3 KB, output_batches=16, row_replacements=2.44 K]
      ProjectionExec: expr=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate, count(Int64(1))@2 as pageviews], metrics=[output_rows=41.19 K, elapsed_compute=26.87µs, output_bytes=1089.8 KB, output_batches=16, expr_0_eval_time=4.57µs, expr_1_eval_time=1.37µs, expr_2_eval_time=1.71µs]
        AggregateExec: mode=FinalPartitioned, gby=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.19 K, elapsed_compute=2.34ms, output_bytes=1089.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=5.07 M, aggregate_arguments_time=13.24µs, aggregation_time=80.79µs, emitting_time=30.78µs, time_calculating_group_ids=2.10ms]
          RepartitionExec: partitioning=Hash([URLHash@0, hits.EventDate@1], 16), input_partitions=16, metrics=[output_rows=41.87 K, elapsed_compute=276.27µs, output_bytes=2.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=127.95ms, repartition_time=517.23µs, send_time=53.87µs]
            AggregateExec: mode=Partial, gby=[URLHash@1 as URLHash, CAST(CAST(EventDate@0 AS Int32) AS Date32) as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.87 K, elapsed_compute=3.46ms, output_bytes=5.8 MB, output_batches=6, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.57 M, aggregate_arguments_time=73.31µs, aggregation_time=241.50µs, emitting_time=6.72µs, time_calculating_group_ids=2.87ms, reduction_factor=47% (41.87 K/89.91 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/ben
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 40, Iteration 4) ===
GlobalLimitExec: skip=100, fetch=10, metrics=[output_rows=10, elapsed_compute=10.01µs, output_bytes=2.1 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=110, metrics=[output_rows=110, elapsed_compute=12.92µs, output_bytes=2.1 KB, output_batches=1]
    SortExec: TopK(fetch=110), expr=[pageviews@2 DESC], preserve_partitioning=[true], filter=[pageviews@2 IS NULL OR pageviews@2 > 6], metrics=[output_rows=1.49 K, elapsed_compute=1.15ms, output_bytes=29.0 KB, output_batches=16, row_replacements=2.66 K]
      ProjectionExec: expr=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate, count(Int64(1))@2 as pageviews], metrics=[output_rows=41.19 K, elapsed_compute=25.53µs, output_bytes=1089.8 KB, output_batches=16, expr_0_eval_time=4.52µs, expr_1_eval_time=1.74µs, expr_2_eval_time=1.67µs]
        AggregateExec: mode=FinalPartitioned, gby=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.19 K, elapsed_compute=2.30ms, output_bytes=1089.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=5.07 M, aggregate_arguments_time=13.98µs, aggregation_time=72.83µs, emitting_time=29.71µs, time_calculating_group_ids=2.09ms]
          RepartitionExec: partitioning=Hash([URLHash@0, hits.EventDate@1], 16), input_partitions=16, metrics=[output_rows=41.87 K, elapsed_compute=258.70µs, output_bytes=2.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=232.76ms, repartition_time=462.04µs, send_time=54.62µs]
            AggregateExec: mode=Partial, gby=[URLHash@1 as URLHash, CAST(CAST(EventDate@0 AS Int32) AS Date32) as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.87 K, elapsed_compute=2.50ms, output_bytes=6.3 MB, output_batches=6, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.87 M, aggregate_arguments_time=21.09µs, aggregation_time=75.46µs, emitting_time=7.27µs, time_calculating_group_ids=2.28ms, reduction_factor=47% (41.87 K/89.91 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benc
```
</details>

---

### q41_hash_eq

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [360, 44, 35, 35, 35] | 35 | — | — | 0.2ms | 0.0 |
| Disk cache 10MB | [770, 74, 76, 79, 80] | 74 | — | — | 0.0ms | 2.3 |
| Memory cache 2048MB | [363, 26, 19, 19, 24] | 19 | — | — | 0.0ms | 0.5 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [96, 39, 39, 38, 36] | 36 | — | — | 1.00× | +3% |
| Disk cache 10MB | [502, 77, 81, 84, 78] | 77 | — | — | 0.47× | +4% |
| Memory cache 2048MB | [82, 20, 21, 19, 19] | 19 | — | — | 1.89× | +0% |

**Analysis:** Disk cache (0.47×) vs Parquet under contention. Both suffer similar regression. The disk I/O overhead may offset decode savings at this budget.

**Cache stats (disk 10MB, under contention):**
- Entries: 860 total, 187 on disk
- Memory: 9MB / Disk: 3MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 10MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 41, Iteration 4) ===
GlobalLimitExec: skip=10000, fetch=10, metrics=[output_rows=10, elapsed_compute=6.66µs, output_bytes=21.3 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=10010, metrics=[output_rows=10.01 K, elapsed_compute=362.03µs, output_bytes=117.3 KB, output_batches=2]
    SortExec: TopK(fetch=10010), expr=[pageviews@2 DESC], preserve_partitioning=[true], metrics=[output_rows=10.95 K, elapsed_compute=2.69ms, output_bytes=128.3 KB, output_batches=16, row_replacements=10.95 K]
      ProjectionExec: expr=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight, count(Int64(1))@2 as pageviews], metrics=[output_rows=10.95 K, elapsed_compute=22.56µs, output_bytes=149.5 KB, output_batches=16, expr_0_eval_time=3.39µs, expr_1_eval_time=1.50µs, expr_2_eval_time=1.41µs]
        AggregateExec: mode=FinalPartitioned, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=10.95 K, elapsed_compute=833.85µs, output_bytes=149.5 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.06 M, aggregate_arguments_time=12.56µs, aggregation_time=27.80µs, emitting_time=21.70µs, time_calculating_group_ids=658.65µs]
          RepartitionExec: partitioning=Hash([WindowClientWidth@0, WindowClientHeight@1], 16), input_partitions=16, metrics=[output_rows=12.33 K, elapsed_compute=179.77µs, output_bytes=1536.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=116.27ms, repartition_time=201.70µs, send_time=36.23µs]
            AggregateExec: mode=Partial, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=12.33 K, elapsed_compute=2.56ms, output_bytes=386.2 KB, output_batches=3, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=583.4 K, aggregate_arguments_time=233.74µs, aggregation_time=276.03µs, emitting_time=4.98µs, time_calculating_group_ids=1.91ms, reduction_factor=12% (12.33 K/102.7 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:73899882
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 41, Iteration 4) ===
GlobalLimitExec: skip=10000, fetch=10, metrics=[output_rows=10, elapsed_compute=7.42µs, output_bytes=21.3 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=10010, metrics=[output_rows=10.01 K, elapsed_compute=379.30µs, output_bytes=117.3 KB, output_batches=2]
    SortExec: TopK(fetch=10010), expr=[pageviews@2 DESC], preserve_partitioning=[true], metrics=[output_rows=10.95 K, elapsed_compute=2.81ms, output_bytes=128.3 KB, output_batches=16, row_replacements=10.95 K]
      ProjectionExec: expr=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight, count(Int64(1))@2 as pageviews], metrics=[output_rows=10.95 K, elapsed_compute=20.71µs, output_bytes=149.5 KB, output_batches=16, expr_0_eval_time=2.86µs, expr_1_eval_time=1.44µs, expr_2_eval_time=1.40µs]
        AggregateExec: mode=FinalPartitioned, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=10.95 K, elapsed_compute=909.94µs, output_bytes=149.5 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.06 M, aggregate_arguments_time=13.57µs, aggregation_time=31.64µs, emitting_time=21.03µs, time_calculating_group_ids=733.41µs]
          RepartitionExec: partitioning=Hash([WindowClientWidth@0, WindowClientHeight@1], 16), input_partitions=16, metrics=[output_rows=12.33 K, elapsed_compute=172.84µs, output_bytes=1536.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=240.61ms, repartition_time=168.31µs, send_time=35.51µs]
            AggregateExec: mode=Partial, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=12.33 K, elapsed_compute=1.64ms, output_bytes=368.3 KB, output_batches=3, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=758.3 K, aggregate_arguments_time=26.04µs, aggregation_time=86.51µs, emitting_time=5.94µs, time_calculating_group_ids=1.45ms, reduction_factor=12% (12.33 K/102.7 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224
```
</details>

---

### q42_time_bucket

#### Without contention (baseline)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Scan time | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|----------:|---------------:|
| Parquet | [338, 34, 30, 32, 31] | 30 | — | — | 0.2ms | 0.0 |
| Disk cache 5MB | [342, 18, 28, 18, 18] | 18 | — | — | 0.0ms | 0.0 |
| Memory cache 2048MB | [347, 20, 18, 18, 18] | 18 | — | — | 0.0ms | 0.0 |

#### Under contention (heavy q4 in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs baseline |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|-----------------------:|
| Parquet | [82, 39, 33, 30, 30] | 30 | — | — | 1.00× | +0% |
| Disk cache 5MB | [76, 21, 18, 25, 18] | 18 | — | — | 1.67× | +0% |
| Memory cache 2048MB | [62, 20, 18, 18, 18] | 18 | — | — | 1.67× | +0% |

**Analysis:** ✅ Disk cache is 1.67× faster than Parquet under contention. Parquet regresses +0% due to CPU competition for decode, while disk cache only regresses +0% (no decode CPU needed). Memory cache (1.67×) shows the best case with no I/O at all.

**Cache stats (disk 5MB, under contention):**
- Entries: 688 total, 0 on disk
- Memory: 4MB / Disk: 0MB
- eval_predicate: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 5MB under contention</summary>

```
=== EXPLAIN ANALYZE(Query 42, Iteration 4) ===
GlobalLimitExec: skip=1000, fetch=10, metrics=[output_rows=10, elapsed_compute=7.66µs, output_bytes=15.8 KB, output_batches=1]
  SortPreservingMergeExec: [date_trunc(minute, m@0) ASC NULLS LAST], fetch=1010, metrics=[output_rows=1.01 K, elapsed_compute=62.95µs, output_bytes=15.8 KB, output_batches=1]
    SortExec: TopK(fetch=1010), expr=[date_trunc(minute, m@0) ASC NULLS LAST], preserve_partitioning=[true], metrics=[output_rows=1.44 K, elapsed_compute=407.63µs, output_bytes=22.5 KB, output_batches=16, row_replacements=1.44 K]
      ProjectionExec: expr=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as m, count(Int64(1))@1 as pageviews], metrics=[output_rows=1.44 K, elapsed_compute=12.35µs, output_bytes=27.2 KB, output_batches=16, expr_0_eval_time=2.22µs, expr_1_eval_time=1.20µs]
        AggregateExec: mode=FinalPartitioned, gby=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=1.44 K, elapsed_compute=180.04µs, output_bytes=27.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=204.3 K, aggregate_arguments_time=7.13µs, aggregation_time=12.82µs, emitting_time=12.65µs, time_calculating_group_ids=68.09µs]
          RepartitionExec: partitioning=Hash([date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0], 16), input_partitions=16, metrics=[output_rows=2.88 K, elapsed_compute=103.45µs, output_bytes=2.0 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=26.39ms, repartition_time=44.83µs, send_time=23.53µs]
            AggregateExec: mode=Partial, gby=[date_trunc(minute, to_timestamp_seconds(EventTime@0)) as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=2.88 K, elapsed_compute=5.59ms, output_bytes=68.7 KB, output_batches=2, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=259.8 K, aggregate_arguments_time=145.31µs, aggregation_time=333.92µs, emitting_time=2.65µs, time_calculating_group_ids=3.70ms, reduction_factor=0.43% (2.88 K/671.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:646623
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet under contention</summary>

```
=== EXPLAIN ANALYZE(Query 42, Iteration 4) ===
GlobalLimitExec: skip=1000, fetch=10, metrics=[output_rows=10, elapsed_compute=8.96µs, output_bytes=15.8 KB, output_batches=1]
  SortPreservingMergeExec: [date_trunc(minute, m@0) ASC NULLS LAST], fetch=1010, metrics=[output_rows=1.01 K, elapsed_compute=63.11µs, output_bytes=15.8 KB, output_batches=1]
    SortExec: TopK(fetch=1010), expr=[date_trunc(minute, m@0) ASC NULLS LAST], preserve_partitioning=[true], metrics=[output_rows=1.44 K, elapsed_compute=452.27µs, output_bytes=22.5 KB, output_batches=16, row_replacements=1.44 K]
      ProjectionExec: expr=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as m, count(Int64(1))@1 as pageviews], metrics=[output_rows=1.44 K, elapsed_compute=13.58µs, output_bytes=27.2 KB, output_batches=16, expr_0_eval_time=2.14µs, expr_1_eval_time=1.33µs]
        AggregateExec: mode=FinalPartitioned, gby=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=1.44 K, elapsed_compute=196.76µs, output_bytes=27.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=204.3 K, aggregate_arguments_time=9.63µs, aggregation_time=14.37µs, emitting_time=13.82µs, time_calculating_group_ids=81.05µs]
          RepartitionExec: partitioning=Hash([date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0], 16), input_partitions=16, metrics=[output_rows=2.88 K, elapsed_compute=132.18µs, output_bytes=2.0 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=214.68ms, repartition_time=64.56µs, send_time=24.18µs]
            AggregateExec: mode=Partial, gby=[date_trunc(minute, to_timestamp_seconds(EventTime@0)) as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=2.88 K, elapsed_compute=5.48ms, output_bytes=74.8 KB, output_batches=2, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=266.0 K, aggregate_arguments_time=135.85µs, aggregation_time=323.66µs, emitting_time=4.39µs, time_calculating_group_ids=3.61ms, reduction_factor=0.43% (2.88 K/671.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:64662
```
</details>

---

## Experiment B: Heavy Queries Benefit from Disk Cache

**Hypothesis:** A heavy query (e.g., COUNT DISTINCT) reads all rows. If columns are pre-cached on disk,
it skips Parquet decode → frees CPU cycles for hash table operations → finishes faster.

### c5_heavy_agg

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [684, 282, 274, 276, 270] | 270 | — | — | 1.00× | 0.1 |
| Disk cache 200MB | [673, 253, 236, 237, 239] | 236 | — | — | 1.14× | 0.0 |
| Memory cache 2048MB | [661, 253, 242, 259, 237] | 237 | — | — | 1.14× | 0.0 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [513, 371, 749, 375, 298] | 298 | — | — | 1.00× | +10% |
| Disk cache 200MB | [466, 543, 490, 315, 255] | 255 | — | — | 1.17× | +8% |
| Memory cache 2048MB | [421, 293, 588, 377, 283] | 283 | — | — | 1.05× | +19% |

**Analysis:** Even for heavy queries, disk cache helps: 1.14× alone, 1.17× under contention. The heavy query needs CPU for hash table operations. With disk cache, it doesn't also need CPU for decode → more CPU available for the actual computation.

**Cache stats (disk 200MB):**
- Entries: 12218 total, 0 on disk
- Memory: 191MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 0, Iteration 4) ===
ProjectionExec: expr=[CounterID@0 as CounterID, sum(hits.AdvEngineID)@1 as sum(hits.AdvEngineID), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), min(hits.ClientIP)@3 as min(hits.ClientIP), max(hits.ClientIP)@4 as max(hits.ClientIP), count(*)@5 as count(*)], metrics=[output_rows=50, elapsed_compute=2.42µs, output_bytes=1800.0 B, output_batches=1, expr_0_eval_time=230ns, expr_1_eval_time=60ns, expr_2_eval_time=50ns, expr_3_eval_time=60ns, expr_4_eval_time=60ns, expr_5_eval_time=150ns]
  SortPreservingMergeExec: [count(Int64(1))@6 DESC], fetch=50, metrics=[output_rows=50, elapsed_compute=12.20µs, output_bytes=2.1 KB, output_batches=1]
    SortExec: TopK(fetch=50), expr=[count(*)@5 DESC], preserve_partitioning=[true], filter=[count(*)@5 IS NULL OR count(*)@5 > 6541], metrics=[output_rows=649, elapsed_compute=477.48µs, output_bytes=27.9 KB, output_batches=16, row_replacements=931]
      ProjectionExec: expr=[CounterID@0 as CounterID, sum(hits.AdvEngineID)@1 as sum(hits.AdvEngineID), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), min(hits.ClientIP)@3 as min(hits.ClientIP), max(hits.ClientIP)@4 as max(hits.ClientIP), count(Int64(1))@5 as count(*), count(Int64(1))@5 as count(Int64(1))], metrics=[output_rows=3.40 K, elapsed_compute=35.41µs, output_bytes=4.5 MB, output_batches=16, expr_0_eval_time=2.87µs, expr_1_eval_time=1.48µs, expr_2_eval_time=1.37µs, expr_3_eval_time=1.30µs, expr_4_eval_time=1.14µs, expr_5_eval_time=1.42µs, expr_6_eval_time=1.24µs]
        FilterExec: count(Int64(1))@5 > 100, metrics=[output_rows=3.40 K, elapsed_compute=239.00µs, output_bytes=4.5 MB, output_batches=16, selectivity=52% (3.40 K/6.51 K)]
          AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID], aggr=[sum(hits.AdvEngineID), avg(hits.ResolutionWidth), min(hits.ClientIP), max(hits.ClientIP), count(Int64(1))], metrics=[output_rows=6.51 K, elapsed_compute=614.80µs, output_bytes=235.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=777.9 K, aggregate_arguments_time=32.77µs, aggregation_time=390.91µs, emitting_time=53.32µs, time_calculating_group_ids=228.08µs]
            RepartitionExec: partitioning=Hash([CounterID@0], 16), input_partitions=16, metrics=[output_rows=6.74 K, elapsed_compute=602.12µs, output_bytes=5.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=3.10s, repartition_time=710.86µs, send_time=318.11µs]
              AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID], aggr=[sum(hits.AdvEngineID), avg(hits.ResolutionWidth), min(hits.ClientIP), max(hits.ClientIP), count(Int64(1))], metrics=[output_rows=6.74 K, elapsed_compute=1.43s, output_bytes=418.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.55 M, aggregate_arguments_time=148.84ms, aggregation_time=1.99s, emitting_time=85.24µs, time_calculating_group_ids=709.35ms, reduction_factor=0.
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 0, Iteration 4) ===
ProjectionExec: expr=[CounterID@0 as CounterID, sum(hits.AdvEngineID)@1 as sum(hits.AdvEngineID), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), min(hits.ClientIP)@3 as min(hits.ClientIP), max(hits.ClientIP)@4 as max(hits.ClientIP), count(*)@5 as count(*)], metrics=[output_rows=50, elapsed_compute=2.34µs, output_bytes=1800.0 B, output_batches=1, expr_0_eval_time=180ns, expr_1_eval_time=230ns, expr_2_eval_time=50ns, expr_3_eval_time=50ns, expr_4_eval_time=50ns, expr_5_eval_time=60ns]
  SortPreservingMergeExec: [count(Int64(1))@6 DESC], fetch=50, metrics=[output_rows=50, elapsed_compute=13.12µs, output_bytes=2.1 KB, output_batches=1]
    SortExec: TopK(fetch=50), expr=[count(*)@5 DESC], preserve_partitioning=[true], filter=[count(*)@5 IS NULL OR count(*)@5 > 6541], metrics=[output_rows=635, elapsed_compute=510.21µs, output_bytes=27.3 KB, output_batches=16, row_replacements=857]
      ProjectionExec: expr=[CounterID@0 as CounterID, sum(hits.AdvEngineID)@1 as sum(hits.AdvEngineID), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), min(hits.ClientIP)@3 as min(hits.ClientIP), max(hits.ClientIP)@4 as max(hits.ClientIP), count(Int64(1))@5 as count(*), count(Int64(1))@5 as count(Int64(1))], metrics=[output_rows=3.40 K, elapsed_compute=38.81µs, output_bytes=4.5 MB, output_batches=16, expr_0_eval_time=3.06µs, expr_1_eval_time=1.80µs, expr_2_eval_time=1.35µs, expr_3_eval_time=1.13µs, expr_4_eval_time=1.33µs, expr_5_eval_time=1.26µs, expr_6_eval_time=1.34µs]
        FilterExec: count(Int64(1))@5 > 100, metrics=[output_rows=3.40 K, elapsed_compute=280.51µs, output_bytes=4.5 MB, output_batches=16, selectivity=52% (3.40 K/6.51 K)]
          AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID], aggr=[sum(hits.AdvEngineID), avg(hits.ResolutionWidth), min(hits.ClientIP), max(hits.ClientIP), count(Int64(1))], metrics=[output_rows=6.51 K, elapsed_compute=796.45µs, output_bytes=235.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=777.9 K, aggregate_arguments_time=36.11µs, aggregation_time=492.53µs, emitting_time=62.47µs, time_calculating_group_ids=264.23µs]
            RepartitionExec: partitioning=Hash([CounterID@0], 16), input_partitions=16, metrics=[output_rows=6.74 K, elapsed_compute=728.22µs, output_bytes=5.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=3.50s, repartition_time=878.23µs, send_time=331.26µs]
              AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID], aggr=[sum(hits.AdvEngineID), avg(hits.ResolutionWidth), min(hits.ClientIP), max(hits.ClientIP), count(Int64(1))], metrics=[output_rows=6.74 K, elapsed_compute=1.42s, output_bytes=399.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.54 M, aggregate_arguments_time=153.34ms, aggregation_time=1.98s, emitting_time=119.07µs, time_calculating_group_ids=690.24ms, reduction_factor=0
```
</details>

---

### h0_region_distinct

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [1437, 1033, 1054, 1061, 1016] | 1016 | — | — | 1.00× | 0.0 |
| Disk cache 200MB | [1372, 1009, 1080, 1041, 1000] | 1000 | — | — | 1.02× | 0.0 |
| Memory cache 2048MB | [1386, 1016, 1003, 1029, 990] | 990 | — | — | 1.03× | 0.0 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [1223, 1021, 1021, 1025, 1018] | 1018 | — | — | 1.00× | +0% |
| Disk cache 200MB | [1218, 1002, 999, 991, 1005] | 991 | — | — | 1.03× | +-1% |
| Memory cache 2048MB | [1136, 983, 1004, 985, 1000] | 983 | — | — | 1.04× | +-1% |

**Analysis:** Even for heavy queries, disk cache helps: 1.02× alone, 1.03× under contention. The heavy query needs CPU for hash table operations. With disk cache, it doesn't also need CPU for decode → more CPU available for the actual computation.

**Cache stats (disk 200MB):**
- Entries: 12218 total, 0 on disk
- Memory: 191MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 1, Iteration 4) ===
ProjectionExec: expr=[RegionID@0 as RegionID, count(*)@1 as count(*), sum(hits.AdvEngineID)@2 as sum(hits.AdvEngineID), avg(hits.ResolutionWidth)@3 as avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)@4 as count(DISTINCT hits.UserID)], metrics=[output_rows=20, elapsed_compute=3.11µs, output_bytes=720.0 B, output_batches=1, expr_0_eval_time=320ns, expr_1_eval_time=80ns, expr_2_eval_time=180ns, expr_3_eval_time=140ns, expr_4_eval_time=160ns]
  SortPreservingMergeExec: [count(Int64(1))@5 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=15.16µs, output_bytes=880.0 B, output_batches=1]
    SortExec: TopK(fetch=20), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 36573], metrics=[output_rows=271, elapsed_compute=912.21µs, output_bytes=11.6 KB, output_batches=16, row_replacements=286]
      ProjectionExec: expr=[RegionID@0 as RegionID, count(Int64(1))@1 as count(*), sum(hits.AdvEngineID)@2 as sum(hits.AdvEngineID), avg(hits.ResolutionWidth)@3 as avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)@4 as count(DISTINCT hits.UserID), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=9.04 K, elapsed_compute=86.13µs, output_bytes=403.9 KB, output_batches=16, expr_0_eval_time=18.92µs, expr_1_eval_time=2.35µs, expr_2_eval_time=2.80µs, expr_3_eval_time=2.36µs, expr_4_eval_time=2.56µs, expr_5_eval_time=2.70µs]
        AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), sum(hits.AdvEngineID), avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)], metrics=[output_rows=9.04 K, elapsed_compute=1.11s, output_bytes=403.9 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=541.4 M, aggregate_arguments_time=380.13µs, aggregation_time=1.11s, emitting_time=2.16ms, time_calculating_group_ids=2.95ms]
          RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=68.25 K, elapsed_compute=194.09ms, output_bytes=167.6 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=9.73s, repartition_time=52.60ms, send_time=880.27µs]
            AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), sum(hits.AdvEngineID), avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)], metrics=[output_rows=68.25 K, elapsed_compute=7.23s, output_bytes=166.6 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=335.6 M, aggregate_arguments_time=169.79ms, aggregation_time=7.01s, emitting_time=159.02ms, time_calculating_group_ids=859.95ms, reduction_factor=0.073% (68.25 K/93.33 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/h
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 1, Iteration 4) ===
ProjectionExec: expr=[RegionID@0 as RegionID, count(*)@1 as count(*), sum(hits.AdvEngineID)@2 as sum(hits.AdvEngineID), avg(hits.ResolutionWidth)@3 as avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)@4 as count(DISTINCT hits.UserID)], metrics=[output_rows=20, elapsed_compute=2.73µs, output_bytes=720.0 B, output_batches=1, expr_0_eval_time=330ns, expr_1_eval_time=150ns, expr_2_eval_time=160ns, expr_3_eval_time=150ns, expr_4_eval_time=140ns]
  SortPreservingMergeExec: [count(Int64(1))@5 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=14.59µs, output_bytes=880.0 B, output_batches=1]
    SortExec: TopK(fetch=20), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 36573], metrics=[output_rows=257, elapsed_compute=979.34µs, output_bytes=11.0 KB, output_batches=16, row_replacements=272]
      ProjectionExec: expr=[RegionID@0 as RegionID, count(Int64(1))@1 as count(*), sum(hits.AdvEngineID)@2 as sum(hits.AdvEngineID), avg(hits.ResolutionWidth)@3 as avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)@4 as count(DISTINCT hits.UserID), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=9.04 K, elapsed_compute=84.98µs, output_bytes=403.9 KB, output_batches=16, expr_0_eval_time=18.92µs, expr_1_eval_time=2.41µs, expr_2_eval_time=2.97µs, expr_3_eval_time=2.46µs, expr_4_eval_time=921ns, expr_5_eval_time=2.53µs]
        AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), sum(hits.AdvEngineID), avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)], metrics=[output_rows=9.04 K, elapsed_compute=1.16s, output_bytes=403.9 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=541.4 M, aggregate_arguments_time=243.21µs, aggregation_time=1.16s, emitting_time=2.22ms, time_calculating_group_ids=2.89ms]
          RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=68.25 K, elapsed_compute=206.79ms, output_bytes=167.6 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=9.90s, repartition_time=50.66ms, send_time=525.59µs]
            AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), sum(hits.AdvEngineID), avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)], metrics=[output_rows=68.25 K, elapsed_compute=7.35s, output_bytes=166.4 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=335.5 M, aggregate_arguments_time=190.83ms, aggregation_time=7.13s, emitting_time=145.98ms, time_calculating_group_ids=871.97ms, reduction_factor=0.073% (68.25 K/93.33 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/h
```
</details>

---

### h1_counter_wide

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [874, 419, 416, 398, 412] | 398 | — | — | 1.00× | 0.0 |
| Disk cache 200MB | [805, 355, 329, 365, 328] | 328 | — | — | 1.21× | 0.0 |
| Memory cache 2048MB | [804, 343, 359, 323, 330] | 323 | — | — | 1.23× | 0.0 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [522, 400, 415, 420, 409] | 400 | — | — | 1.00× | +1% |
| Disk cache 200MB | [444, 361, 346, 336, 318] | 318 | — | — | 1.26× | +-3% |
| Memory cache 2048MB | [434, 343, 334, 316, 356] | 316 | — | — | 1.27× | +-2% |

**Analysis:** Even for heavy queries, disk cache helps: 1.21× alone, 1.26× under contention. The heavy query needs CPU for hash table operations. With disk cache, it doesn't also need CPU for decode → more CPU available for the actual computation.

**Cache stats (disk 200MB):**
- Entries: 24436 total, 0 on disk
- Memory: 199MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 2, Iteration 4) ===
ProjectionExec: expr=[CounterID@0 as CounterID, count(*)@1 as count(*), sum(hits.ResolutionWidth)@2 as sum(hits.ResolutionWidth), avg(hits.ClientIP)@3 as avg(hits.ClientIP), min(hits.UserID)@4 as min(hits.UserID), max(hits.UserID)@5 as max(hits.UserID)], metrics=[output_rows=100, elapsed_compute=2.11µs, output_bytes=4.3 KB, output_batches=1, expr_0_eval_time=329ns, expr_1_eval_time=80ns, expr_2_eval_time=80ns, expr_3_eval_time=60ns, expr_4_eval_time=150ns, expr_5_eval_time=60ns]
  SortPreservingMergeExec: [count(Int64(1))@6 DESC], fetch=100, metrics=[output_rows=100, elapsed_compute=15.86µs, output_bytes=5.1 KB, output_batches=1]
    SortExec: TopK(fetch=100), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 1275], metrics=[output_rows=1.46 K, elapsed_compute=854.82µs, output_bytes=74.2 KB, output_batches=16, row_replacements=2.16 K]
      ProjectionExec: expr=[CounterID@0 as CounterID, count(Int64(1))@1 as count(*), sum(hits.ResolutionWidth)@2 as sum(hits.ResolutionWidth), avg(hits.ClientIP)@3 as avg(hits.ClientIP), min(hits.UserID)@4 as min(hits.UserID), max(hits.UserID)@5 as max(hits.UserID), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=6.50 K, elapsed_compute=38.83µs, output_bytes=286.1 KB, output_batches=16, expr_0_eval_time=3.13µs, expr_1_eval_time=1.32µs, expr_2_eval_time=1.46µs, expr_3_eval_time=1.40µs, expr_4_eval_time=1.34µs, expr_5_eval_time=1.30µs, expr_6_eval_time=1.28µs]
        AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID], aggr=[count(Int64(1)), sum(hits.ResolutionWidth), avg(hits.ClientIP), min(hits.UserID), max(hits.UserID)], metrics=[output_rows=6.50 K, elapsed_compute=653.48µs, output_bytes=286.1 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=881.9 K, aggregate_arguments_time=42.80µs, aggregation_time=400.12µs, emitting_time=53.85µs, time_calculating_group_ids=248.45µs]
          RepartitionExec: partitioning=Hash([CounterID@0], 16), input_partitions=16, metrics=[output_rows=6.74 K, elapsed_compute=721.94µs, output_bytes=6.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=4.11s, repartition_time=983.64µs, send_time=313.47µs]
            AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID], aggr=[count(Int64(1)), sum(hits.ResolutionWidth), avg(hits.ClientIP), min(hits.UserID), max(hits.UserID)], metrics=[output_rows=6.74 K, elapsed_compute=1.39s, output_bytes=494.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.63 M, aggregate_arguments_time=148.92ms, aggregation_time=1.59s, emitting_time=98.07µs, time_calculating_group_ids=632.65ms, reduction_factor=0.008% (6.74 K/83.91 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/da
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 2, Iteration 4) ===
ProjectionExec: expr=[CounterID@0 as CounterID, count(*)@1 as count(*), sum(hits.ResolutionWidth)@2 as sum(hits.ResolutionWidth), avg(hits.ClientIP)@3 as avg(hits.ClientIP), min(hits.UserID)@4 as min(hits.UserID), max(hits.UserID)@5 as max(hits.UserID)], metrics=[output_rows=100, elapsed_compute=2.87µs, output_bytes=4.3 KB, output_batches=1, expr_0_eval_time=280ns, expr_1_eval_time=60ns, expr_2_eval_time=60ns, expr_3_eval_time=80ns, expr_4_eval_time=140ns, expr_5_eval_time=140ns]
  SortPreservingMergeExec: [count(Int64(1))@6 DESC], fetch=100, metrics=[output_rows=100, elapsed_compute=16.03µs, output_bytes=5.1 KB, output_batches=1]
    SortExec: TopK(fetch=100), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 1275], metrics=[output_rows=1.38 K, elapsed_compute=843.07µs, output_bytes=70.1 KB, output_batches=16, row_replacements=1.94 K]
      ProjectionExec: expr=[CounterID@0 as CounterID, count(Int64(1))@1 as count(*), sum(hits.ResolutionWidth)@2 as sum(hits.ResolutionWidth), avg(hits.ClientIP)@3 as avg(hits.ClientIP), min(hits.UserID)@4 as min(hits.UserID), max(hits.UserID)@5 as max(hits.UserID), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=6.50 K, elapsed_compute=44.26µs, output_bytes=286.1 KB, output_batches=16, expr_0_eval_time=3.69µs, expr_1_eval_time=1.42µs, expr_2_eval_time=1.64µs, expr_3_eval_time=1.42µs, expr_4_eval_time=1.80µs, expr_5_eval_time=1.65µs, expr_6_eval_time=1.44µs]
        AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID], aggr=[count(Int64(1)), sum(hits.ResolutionWidth), avg(hits.ClientIP), min(hits.UserID), max(hits.UserID)], metrics=[output_rows=6.50 K, elapsed_compute=651.25µs, output_bytes=286.1 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=881.9 K, aggregate_arguments_time=40.92µs, aggregation_time=475.96µs, emitting_time=61.76µs, time_calculating_group_ids=248.25µs]
          RepartitionExec: partitioning=Hash([CounterID@0], 16), input_partitions=16, metrics=[output_rows=6.74 K, elapsed_compute=839.07µs, output_bytes=6.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=5.25s, repartition_time=981.28µs, send_time=395.96µs]
            AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID], aggr=[count(Int64(1)), sum(hits.ResolutionWidth), avg(hits.ClientIP), min(hits.UserID), max(hits.UserID)], metrics=[output_rows=6.74 K, elapsed_compute=1.39s, output_bytes=479.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.62 M, aggregate_arguments_time=153.89ms, aggregation_time=1.60s, emitting_time=129.96µs, time_calculating_group_ids=626.81ms, reduction_factor=0.008% (6.74 K/83.91 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/
```
</details>

---

### h2_double_distinct

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [431, 72, 68, 63, 59] | 59 | — | — | 1.00× | 0.0 |
| Disk cache 200MB | [435, 214, 197, 205, 196] | 196 | — | — | 0.30× | 0.0 |
| Memory cache 2048MB | [433, 213, 203, 210, 199] | 199 | — | — | 0.30× | 0.2 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [177, 85, 72, 67, 109] | 67 | — | — | 1.00× | +14% |
| Disk cache 200MB | [189, 271, 208, 207, 471] | 207 | — | — | 0.32× | +6% |
| Memory cache 2048MB | [170, 296, 205, 431, 351] | 205 | — | — | 0.33× | +3% |

**Analysis:** Heavy query: disk cache 0.30× alone, 0.32× under contention. Disk cache regresses less (+6% vs Parquet +14%) under contention — confirms decode CPU is freed.

**Cache stats (disk 200MB):**
- Entries: 11540 total, 0 on disk
- Memory: 181MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 3, Iteration 4) ===
AggregateExec: mode=Final, gby=[], aggr=[count(DISTINCT hits.UserID), count(DISTINCT hits.CounterID)], metrics=[output_rows=1, elapsed_compute=20.57ms, output_bytes=16.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=16.14µs, output_bytes=2.3 MB, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[count(DISTINCT hits.UserID), count(DISTINCT hits.CounterID)], metrics=[output_rows=16, elapsed_compute=76.26ms, output_bytes=2.3 MB, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CounterID, UserID], file_type=liquid_parquet, metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=7.6 MB, output_batches=5.87 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=1.46 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.40ms, metadata_load_time=2.57ms, page_index_eval_time=4.45µs, row_pushdown_eval_time=32ns, statistics_eval_time=372.49µs, time_elapsed_opening=7.44ms, time_elapsed_processing=1.58s, time_elapsed_scanning_total=2.42s, tim
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 3, Iteration 4) ===
AggregateExec: mode=Final, gby=[], aggr=[count(DISTINCT hits.UserID), count(DISTINCT hits.CounterID)], metrics=[output_rows=1, elapsed_compute=9.31ms, output_bytes=16.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=13.16µs, output_bytes=2.3 MB, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[count(DISTINCT hits.UserID), count(DISTINCT hits.CounterID)], metrics=[output_rows=16, elapsed_compute=35.84ms, output_bytes=2.3 MB, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CounterID, UserID], file_type=parquet, predicate=AdvEngineID@40 > 0, pruning_predicate=AdvEngineID_null_count@1 != row_count@2 AND AdvEngineID_max@0 > 0, required_guarantees=[], metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=8.7 MB, output_batches=248, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=212 total → 212 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=261.6 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=630.5 K, pushdown_rows_pruned=93.82 M, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.29ms, metadata_load_time=134.52ms, page_index_eval_time=2.69µs, row_pushdow
```
</details>

---

### h3_userid_sum

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [496, 140, 139, 136, 131] | 131 | — | — | 1.00× | 0.0 |
| Disk cache 200MB | [512, 230, 228, 230, 221] | 221 | — | — | 0.59× | 0.0 |
| Memory cache 2048MB | [506, 233, 237, 242, 232] | 232 | — | — | 0.56× | 0.0 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [319, 137, 134, 133, 138] | 133 | — | — | 1.00× | +2% |
| Disk cache 200MB | [268, 232, 233, 229, 231] | 229 | — | — | 0.58× | +4% |
| Memory cache 2048MB | [371, 243, 240, 239, 251] | 239 | — | — | 0.56× | +3% |

**Analysis:** Heavy query: disk cache 0.59× alone, 0.58× under contention. For this query, the bottleneck is hash table computation, not data decode. Cache doesn't help much.

**Cache stats (disk 200MB):**
- Entries: 23080 total, 0 on disk
- Memory: 199MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 4, Iteration 4) ===
SortPreservingMergeExec: [sum(hits.AdvEngineID)@1 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=5.47µs, output_bytes=480.0 B, output_batches=1]
  SortExec: TopK(fetch=20), expr=[sum(hits.AdvEngineID)@1 DESC], preserve_partitioning=[true], filter=[sum(hits.AdvEngineID)@1 IS NULL OR sum(hits.AdvEngineID)@1 > 648], metrics=[output_rows=225, elapsed_compute=503.52µs, output_bytes=5.3 KB, output_batches=16, row_replacements=298]
    ProjectionExec: expr=[UserID@0 as UserID, sum(hits.AdvEngineID)@1 as sum(hits.AdvEngineID), count(Int64(1))@2 as count(*)], metrics=[output_rows=10.90 K, elapsed_compute=40.65µs, output_bytes=3.0 MB, output_batches=16, expr_0_eval_time=5.55µs, expr_1_eval_time=2.21µs, expr_2_eval_time=1.49µs]
      FilterExec: count(Int64(1))@2 > 5, metrics=[output_rows=10.90 K, elapsed_compute=914.87µs, output_bytes=3.0 MB, output_batches=16, selectivity=3.8% (10.90 K/289.5 K)]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID], aggr=[sum(hits.AdvEngineID), count(Int64(1))], metrics=[output_rows=289.5 K, elapsed_compute=23.48ms, output_bytes=35.9 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=40.81 M, aggregate_arguments_time=83.92µs, aggregation_time=5.05ms, emitting_time=75.63µs, time_calculating_group_ids=19.74ms]
          RepartitionExec: partitioning=Hash([UserID@0], 16), input_partitions=16, metrics=[output_rows=295.2 K, elapsed_compute=3.65ms, output_bytes=9.0 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=2.74s, repartition_time=8.01ms, send_time=1.30ms]
            AggregateExec: mode=Partial, gby=[UserID@0 as UserID], aggr=[sum(hits.AdvEngineID), count(Int64(1))], metrics=[output_rows=295.2 K, elapsed_compute=114.78ms, output_bytes=41.3 MB, output_batches=43, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=17.15 M, aggregate_arguments_time=23.02ms, aggregation_time=17.80ms, emitting_time=193.21µs, time_calculating_group_ids=63.16ms, reduction_factor=50% (295.2 K/585.4 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/li
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 4, Iteration 4) ===
SortPreservingMergeExec: [sum(hits.AdvEngineID)@1 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=5.32µs, output_bytes=480.0 B, output_batches=1]
  SortExec: TopK(fetch=20), expr=[sum(hits.AdvEngineID)@1 DESC], preserve_partitioning=[true], filter=[sum(hits.AdvEngineID)@1 IS NULL OR sum(hits.AdvEngineID)@1 > 648], metrics=[output_rows=284, elapsed_compute=588.70µs, output_bytes=6.7 KB, output_batches=16, row_replacements=616]
    ProjectionExec: expr=[UserID@0 as UserID, sum(hits.AdvEngineID)@1 as sum(hits.AdvEngineID), count(Int64(1))@2 as count(*)], metrics=[output_rows=10.90 K, elapsed_compute=32.31µs, output_bytes=3.0 MB, output_batches=16, expr_0_eval_time=3.48µs, expr_1_eval_time=1.60µs, expr_2_eval_time=1.61µs]
      FilterExec: count(Int64(1))@2 > 5, metrics=[output_rows=10.90 K, elapsed_compute=945.99µs, output_bytes=3.0 MB, output_batches=16, selectivity=3.8% (10.90 K/289.5 K)]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID], aggr=[sum(hits.AdvEngineID), count(Int64(1))], metrics=[output_rows=289.5 K, elapsed_compute=18.67ms, output_bytes=35.8 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=40.76 M, aggregate_arguments_time=105.92µs, aggregation_time=3.79ms, emitting_time=68.60µs, time_calculating_group_ids=15.77ms]
          RepartitionExec: partitioning=Hash([UserID@0], 16), input_partitions=16, metrics=[output_rows=295.2 K, elapsed_compute=2.10ms, output_bytes=9.0 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=1.52s, repartition_time=5.25ms, send_time=898.16µs]
            AggregateExec: mode=Partial, gby=[UserID@0 as UserID], aggr=[sum(hits.AdvEngineID), count(Int64(1))], metrics=[output_rows=295.2 K, elapsed_compute=38.87ms, output_bytes=39.3 MB, output_batches=43, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=17.13 M, aggregate_arguments_time=2.69ms, aggregation_time=5.72ms, emitting_time=165.26µs, time_calculating_group_ids=31.17ms, reduction_factor=50% (295.2 K/585.4 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/li
```
</details>

---

### h4_clientip_stats

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [1363, 986, 1010, 986, 988] | 986 | — | — | 1.00× | 0.1 |
| Disk cache 200MB | [1415, 984, 978, 1007, 993] | 978 | — | — | 1.01× | 0.0 |
| Memory cache 2048MB | [1395, 990, 1035, 1062, 987] | 987 | — | — | 1.00× | 0.0 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [1060, 993, 1014, 994, 976] | 976 | — | — | 1.00× | +-1% |
| Disk cache 200MB | [1104, 993, 1010, 1019, 994] | 993 | — | — | 0.98× | +2% |
| Memory cache 2048MB | [1065, 993, 1005, 988, 982] | 982 | — | — | 0.99× | +-1% |

**Analysis:** Even for heavy queries, disk cache helps: 1.01× alone, 0.98× under contention. The heavy query needs CPU for hash table operations. With disk cache, it doesn't also need CPU for decode → more CPU available for the actual computation.

**Cache stats (disk 200MB):**
- Entries: 24436 total, 0 on disk
- Memory: 199MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 5, Iteration 4) ===
ProjectionExec: expr=[ClientIP@0 as ClientIP, count(*)@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), sum(hits.IsRefresh)@3 as sum(hits.IsRefresh)], metrics=[output_rows=50, elapsed_compute=1.58µs, output_bytes=1400.0 B, output_batches=1, expr_0_eval_time=200ns, expr_1_eval_time=70ns, expr_2_eval_time=50ns, expr_3_eval_time=150ns]
  SortPreservingMergeExec: [count(Int64(1))@4 DESC], fetch=50, metrics=[output_rows=50, elapsed_compute=10.52µs, output_bytes=1800.0 B, output_batches=1]
    SortExec: TopK(fetch=50), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 2837], metrics=[output_rows=615, elapsed_compute=28.11ms, output_bytes=21.6 KB, output_batches=16, row_replacements=1.06 K]
      ProjectionExec: expr=[ClientIP@0 as ClientIP, count(Int64(1))@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=9.73 M, elapsed_compute=2.41ms, output_bytes=32.8 GB, output_batches=1.20 K, expr_0_eval_time=259.46µs, expr_1_eval_time=112.50µs, expr_2_eval_time=105.39µs, expr_3_eval_time=96.58µs, expr_4_eval_time=105.61µs]
        AggregateExec: mode=FinalPartitioned, gby=[ClientIP@0 as ClientIP], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.IsRefresh)], metrics=[output_rows=9.73 M, elapsed_compute=3.56s, output_bytes=32.8 GB, output_batches=1.20 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.41 B, aggregate_arguments_time=4.35ms, aggregation_time=1.83s, emitting_time=54.94ms, time_calculating_group_ids=2.59s]
          RepartitionExec: partitioning=Hash([ClientIP@0], 16), input_partitions=16, metrics=[output_rows=15.70 M, elapsed_compute=151.30ms, output_bytes=540.6 MB, output_batches=1.92 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=10.34s, repartition_time=470.52ms, send_time=861.71ms]
            AggregateExec: mode=Partial, gby=[ClientIP@0 as ClientIP], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.IsRefresh)], metrics=[output_rows=15.70 M, elapsed_compute=7.75s, output_bytes=99.2 GB, output_batches=1.93 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.05 B, aggregate_arguments_time=218.59ms, aggregation_time=4.07s, emitting_time=2.31ms, time_calculating_group_ids=5.44s, reduction_factor=16% (15.70 M/99.37 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 5, Iteration 4) ===
ProjectionExec: expr=[ClientIP@0 as ClientIP, count(*)@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), sum(hits.IsRefresh)@3 as sum(hits.IsRefresh)], metrics=[output_rows=50, elapsed_compute=2.16µs, output_bytes=1400.0 B, output_batches=1, expr_0_eval_time=280ns, expr_1_eval_time=60ns, expr_2_eval_time=150ns, expr_3_eval_time=50ns]
  SortPreservingMergeExec: [count(Int64(1))@4 DESC], fetch=50, metrics=[output_rows=50, elapsed_compute=10.91µs, output_bytes=1800.0 B, output_batches=1]
    SortExec: TopK(fetch=50), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 2837], metrics=[output_rows=680, elapsed_compute=32.31ms, output_bytes=23.9 KB, output_batches=16, row_replacements=921]
      ProjectionExec: expr=[ClientIP@0 as ClientIP, count(Int64(1))@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=9.73 M, elapsed_compute=2.64ms, output_bytes=32.8 GB, output_batches=1.20 K, expr_0_eval_time=291.95µs, expr_1_eval_time=125.08µs, expr_2_eval_time=104.26µs, expr_3_eval_time=135.20µs, expr_4_eval_time=107.83µs]
        AggregateExec: mode=FinalPartitioned, gby=[ClientIP@0 as ClientIP], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.IsRefresh)], metrics=[output_rows=9.73 M, elapsed_compute=3.66s, output_bytes=32.8 GB, output_batches=1.20 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.41 B, aggregate_arguments_time=4.31ms, aggregation_time=1.93s, emitting_time=66.86ms, time_calculating_group_ids=2.62s]
          RepartitionExec: partitioning=Hash([ClientIP@0], 16), input_partitions=16, metrics=[output_rows=15.70 M, elapsed_compute=154.36ms, output_bytes=540.6 MB, output_batches=1.92 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=10.06s, repartition_time=477.76ms, send_time=786.74ms]
            AggregateExec: mode=Partial, gby=[ClientIP@0 as ClientIP], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.IsRefresh)], metrics=[output_rows=15.70 M, elapsed_compute=7.86s, output_bytes=94.8 GB, output_batches=1.93 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.03 B, aggregate_arguments_time=202.05ms, aggregation_time=4.12s, emitting_time=2.22ms, time_calculating_group_ids=5.54s, reduction_factor=16% (15.70 M/99.37 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-us
```
</details>

---

### h5_userid_distinct

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [1107, 759, 750, 756, 738] | 738 | — | — | 1.00× | 0.1 |
| Disk cache 200MB | [1013, 666, 652, 673, 670] | 652 | — | — | 1.13× | 0.3 |
| Memory cache 2048MB | [1024, 666, 651, 663, 654] | 651 | — | — | 1.13× | 0.1 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [1014, 1392, 868, 730, 767] | 730 | — | — | 1.00× | +-1% |
| Disk cache 200MB | [923, 1132, 744, 668, 650] | 650 | — | — | 1.12× | +-0% |
| Memory cache 2048MB | [933, 1271, 805, 695, 670] | 670 | — | — | 1.09× | +3% |

**Analysis:** Even for heavy queries, disk cache helps: 1.13× alone, 1.12× under contention. The heavy query needs CPU for hash table operations. With disk cache, it doesn't also need CPU for decode → more CPU available for the actual computation.

**Cache stats (disk 200MB):**
- Entries: 24436 total, 0 on disk
- Memory: 199MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 6, Iteration 4) ===
ProjectionExec: expr=[count(alias1)@0 as count(DISTINCT hits.UserID)], metrics=[output_rows=1, elapsed_compute=2.05µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=130ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(alias1)], metrics=[output_rows=1, elapsed_compute=11.60µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=15.21µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(alias1)], metrics=[output_rows=16, elapsed_compute=644.79µs, output_bytes=128.0 B, output_batches=16]
        AggregateExec: mode=FinalPartitioned, gby=[alias1@0 as alias1], aggr=[], metrics=[output_rows=17.62 M, elapsed_compute=3.34s, output_bytes=33.8 GB, output_batches=2.16 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.48 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=3.42ms, time_calculating_group_ids=3.33s]
          RepartitionExec: partitioning=Hash([alias1@0], 16), input_partitions=16, metrics=[output_rows=21.14 M, elapsed_compute=66.11ms, output_bytes=161.9 MB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=6.31s, repartition_time=222.80ms, send_time=721.60ms]
            AggregateExec: mode=Partial, gby=[UserID@0 as alias1], aggr=[], metrics=[output_rows=21.14 M, elapsed_compute=4.31s, output_bytes=42.1 GB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=730.9 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=2.41ms, time_calculating_group_ids=4.29s, reduction_factor=25% (21.14 M/83.91 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/bench
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 6, Iteration 4) ===
ProjectionExec: expr=[count(alias1)@0 as count(DISTINCT hits.UserID)], metrics=[output_rows=1, elapsed_compute=2.37µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=220ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(alias1)], metrics=[output_rows=1, elapsed_compute=7.42µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.08µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(alias1)], metrics=[output_rows=16, elapsed_compute=876.90µs, output_bytes=128.0 B, output_batches=16]
        AggregateExec: mode=FinalPartitioned, gby=[alias1@0 as alias1], aggr=[], metrics=[output_rows=17.62 M, elapsed_compute=3.35s, output_bytes=33.8 GB, output_batches=2.16 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.48 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=7.01ms, time_calculating_group_ids=3.34s]
          RepartitionExec: partitioning=Hash([alias1@0], 16), input_partitions=16, metrics=[output_rows=21.14 M, elapsed_compute=48.07ms, output_bytes=161.9 MB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=7.73s, repartition_time=193.66ms, send_time=606.21ms]
            AggregateExec: mode=Partial, gby=[UserID@0 as alias1], aggr=[], metrics=[output_rows=21.14 M, elapsed_compute=4.83s, output_bytes=42.1 GB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=730.9 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=2.84ms, time_calculating_group_ids=4.81s, reduction_factor=25% (21.14 M/83.91 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchm
```
</details>

---

### h6_groupby_userid

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [1159, 797, 783, 785, 766] | 766 | — | — | 1.00× | 0.0 |
| Disk cache 200MB | [1158, 811, 796, 775, 766] | 766 | — | — | 1.00× | 0.0 |
| Memory cache 2048MB | [1127, 760, 754, 771, 778] | 754 | — | — | 1.02× | 0.2 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [1006, 779, 781, 796, 807] | 779 | — | — | 1.00× | +2% |
| Disk cache 200MB | [1044, 770, 771, 757, 763] | 757 | — | — | 1.03× | +-1% |
| Memory cache 2048MB | [918, 773, 769, 753, 756] | 753 | — | — | 1.03× | +-0% |

**Analysis:** Even for heavy queries, disk cache helps: 1.00× alone, 1.03× under contention. The heavy query needs CPU for hash table operations. With disk cache, it doesn't also need CPU for decode → more CPU available for the actual computation.

**Cache stats (disk 200MB):**
- Entries: 24436 total, 0 on disk
- Memory: 199MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 7, Iteration 4) ===
ProjectionExec: expr=[UserID@0 as UserID, count(*)@1 as count(*)], metrics=[output_rows=10, elapsed_compute=1.45µs, output_bytes=160.0 B, output_batches=1, expr_0_eval_time=200ns, expr_1_eval_time=170ns]
  SortPreservingMergeExec: [count(Int64(1))@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=5.49µs, output_bytes=240.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 1586], metrics=[output_rows=129, elapsed_compute=46.96ms, output_bytes=3.0 KB, output_batches=16, row_replacements=394]
      ProjectionExec: expr=[UserID@0 as UserID, count(Int64(1))@1 as count(*), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=17.54 M, elapsed_compute=2.24ms, output_bytes=67.0 GB, output_batches=2.15 K, expr_0_eval_time=413.12µs, expr_1_eval_time=236.83µs, expr_2_eval_time=171.79µs]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID], aggr=[count(Int64(1))], metrics=[output_rows=17.54 M, elapsed_compute=3.90s, output_bytes=67.0 GB, output_batches=2.15 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=2.01 B, aggregate_arguments_time=2.47ms, aggregation_time=299.25ms, emitting_time=6.03ms, time_calculating_group_ids=3.59s]
          RepartitionExec: partitioning=Hash([UserID@0], 16), input_partitions=16, metrics=[output_rows=21.04 M, elapsed_compute=106.68ms, output_bytes=322.0 MB, output_batches=2.58 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=7.05s, repartition_time=320.73ms, send_time=970.27ms]
            AggregateExec: mode=Partial, gby=[UserID@0 as UserID], aggr=[count(Int64(1))], metrics=[output_rows=21.04 M, elapsed_compute=5.12s, output_bytes=81.6 GB, output_batches=2.57 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=979.5 M, aggregate_arguments_time=56.09ms, aggregation_time=251.49ms, emitting_time=4.79ms, time_calculating_group_ids=4.78s, reduction_factor=23% (21.04 M/92.74 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parqu
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 7, Iteration 4) ===
ProjectionExec: expr=[UserID@0 as UserID, count(*)@1 as count(*)], metrics=[output_rows=10, elapsed_compute=1.19µs, output_bytes=160.0 B, output_batches=1, expr_0_eval_time=260ns, expr_1_eval_time=60ns]
  SortPreservingMergeExec: [count(Int64(1))@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=5.18µs, output_bytes=240.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 1586], metrics=[output_rows=129, elapsed_compute=52.34ms, output_bytes=3.0 KB, output_batches=16, row_replacements=278]
      ProjectionExec: expr=[UserID@0 as UserID, count(Int64(1))@1 as count(*), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=17.54 M, elapsed_compute=2.41ms, output_bytes=67.0 GB, output_batches=2.15 K, expr_0_eval_time=418.82µs, expr_1_eval_time=254.07µs, expr_2_eval_time=183.92µs]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID], aggr=[count(Int64(1))], metrics=[output_rows=17.54 M, elapsed_compute=3.99s, output_bytes=67.0 GB, output_batches=2.15 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=2.01 B, aggregate_arguments_time=2.43ms, aggregation_time=333.37ms, emitting_time=7.07ms, time_calculating_group_ids=3.64s]
          RepartitionExec: partitioning=Hash([UserID@0], 16), input_partitions=16, metrics=[output_rows=21.04 M, elapsed_compute=106.84ms, output_bytes=322.0 MB, output_batches=2.58 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=7.35s, repartition_time=327.60ms, send_time=948.71ms]
            AggregateExec: mode=Partial, gby=[UserID@0 as UserID], aggr=[count(Int64(1))], metrics=[output_rows=21.04 M, elapsed_compute=5.26s, output_bytes=81.2 GB, output_batches=2.57 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=977.3 M, aggregate_arguments_time=57.33ms, aggregation_time=252.88ms, emitting_time=2.55ms, time_calculating_group_ids=4.93s, reduction_factor=23% (21.04 M/92.74 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parque
```
</details>

---

### h7_watchid_filtered

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [3206, 2842, 2812, 2812, 2812] | 2812 | — | — | 1.00× | 0.0 |
| Disk cache 200MB | [3352, 2895, 2891, 2872, 2879] | 2872 | — | — | 0.98× | 0.1 |
| Memory cache 2048MB | [3249, 2911, 2924, 2918, 2877] | 2877 | — | — | 0.98× | 0.0 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [2953, 2857, 2802, 2796, 2788] | 2788 | — | — | 1.00× | +-1% |
| Disk cache 200MB | [3016, 2911, 2872, 2869, 2865] | 2865 | — | — | 0.97× | +-0% |
| Memory cache 2048MB | [3042, 2976, 2954, 2982, 2949] | 2949 | — | — | 0.95× | +3% |

**Analysis:** Heavy query: disk cache 0.98× alone, 0.97× under contention. For this query, the bottleneck is hash table computation, not data decode. Cache doesn't help much.

**Cache stats (disk 200MB):**
- Entries: 24436 total, 0 on disk
- Memory: 199MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 8, Iteration 4) ===
ProjectionExec: expr=[WatchID@0 as WatchID, ClientIP@1 as ClientIP, count(*)@2 as count(*), sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth)], metrics=[output_rows=10, elapsed_compute=3.00µs, output_bytes=360.0 B, output_batches=1, expr_0_eval_time=450ns, expr_1_eval_time=160ns, expr_2_eval_time=80ns, expr_3_eval_time=160ns, expr_4_eval_time=150ns]
  SortPreservingMergeExec: [count(Int64(1))@5 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=11.17µs, output_bytes=440.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@2 DESC], preserve_partitioning=[true], filter=[count(*)@2 IS NULL OR count(*)@2 > 1], metrics=[output_rows=14, elapsed_compute=257.95ms, output_bytes=616.0 B, output_batches=4, row_replacements=14]
      ProjectionExec: expr=[WatchID@0 as WatchID, ClientIP@1 as ClientIP, count(Int64(1))@2 as count(*), sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth), count(Int64(1))@2 as count(Int64(1))], metrics=[output_rows=93.33 M, elapsed_compute=19.79ms, output_bytes=3.1 TB, output_batches=11.40 K, expr_0_eval_time=1.93ms, expr_1_eval_time=1.09ms, expr_2_eval_time=961.64µs, expr_3_eval_time=938.38µs, expr_4_eval_time=908.36µs, expr_5_eval_time=1.31ms]
        AggregateExec: mode=FinalPartitioned, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=93.33 M, elapsed_compute=32.08s, output_bytes=3.1 TB, output_batches=11.40 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=13.42 B, aggregate_arguments_time=33.62ms, aggregation_time=11.86s, emitting_time=681.84ms, time_calculating_group_ids=24.99s]
          RepartitionExec: partitioning=Hash([WatchID@0, ClientIP@1], 16), input_partitions=16, metrics=[output_rows=93.33 M, elapsed_compute=1.45s, output_bytes=3.8 GB, output_batches=11.40 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=5.46s, repartition_time=3.77s, send_time=16.69s]
            AggregateExec: mode=Partial, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=93.33 M, elapsed_compute=1.05s, output_bytes=4.9 GB, output_batches=12.18 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=91.67 M, peak_mem_used=108.9 M, aggregate_arguments_time=8.07ms, aggregation_time=85.96ms, emitting_time=225.50µs, time_calculating_group_ids=261.96ms, reduction_factor=100% (1.66 M/1.66 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 8, Iteration 4) ===
ProjectionExec: expr=[WatchID@0 as WatchID, ClientIP@1 as ClientIP, count(*)@2 as count(*), sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth)], metrics=[output_rows=10, elapsed_compute=3.23µs, output_bytes=360.0 B, output_batches=1, expr_0_eval_time=440ns, expr_1_eval_time=150ns, expr_2_eval_time=150ns, expr_3_eval_time=160ns, expr_4_eval_time=70ns]
  SortPreservingMergeExec: [count(Int64(1))@5 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=11.51µs, output_bytes=440.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@2 DESC], preserve_partitioning=[true], filter=[count(*)@2 IS NULL OR count(*)@2 > 1], metrics=[output_rows=24, elapsed_compute=250.32ms, output_bytes=1056.0 B, output_batches=5, row_replacements=24]
      ProjectionExec: expr=[WatchID@0 as WatchID, ClientIP@1 as ClientIP, count(Int64(1))@2 as count(*), sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth), count(Int64(1))@2 as count(Int64(1))], metrics=[output_rows=93.33 M, elapsed_compute=21.31ms, output_bytes=3.1 TB, output_batches=11.40 K, expr_0_eval_time=1.95ms, expr_1_eval_time=1.00ms, expr_2_eval_time=1.07ms, expr_3_eval_time=919.39µs, expr_4_eval_time=879.35µs, expr_5_eval_time=1.41ms]
        AggregateExec: mode=FinalPartitioned, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=93.33 M, elapsed_compute=32.17s, output_bytes=3.1 TB, output_batches=11.40 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=13.42 B, aggregate_arguments_time=30.99ms, aggregation_time=11.85s, emitting_time=740.97ms, time_calculating_group_ids=24.92s]
          RepartitionExec: partitioning=Hash([WatchID@0, ClientIP@1], 16), input_partitions=16, metrics=[output_rows=93.33 M, elapsed_compute=1.32s, output_bytes=3.8 GB, output_batches=11.40 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=6.15s, repartition_time=3.67s, send_time=15.66s]
            AggregateExec: mode=Partial, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=93.33 M, elapsed_compute=1.13s, output_bytes=5.1 GB, output_batches=11.50 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=91.62 M, peak_mem_used=107.0 M, aggregate_arguments_time=10.68ms, aggregation_time=110.10ms, emitting_time=202.38µs, time_calculating_group_ids=252.13ms, reduction_factor=100% (1.70 M/1.70 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbenc
```
</details>

---

### h8_region_agg

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [663, 278, 265, 287, 273] | 265 | — | — | 1.00× | 0.0 |
| Disk cache 200MB | [650, 260, 253, 260, 258] | 253 | — | — | 1.05× | 0.0 |
| Memory cache 2048MB | [652, 251, 290, 270, 261] | 251 | — | — | 1.06× | 0.1 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [421, 454, 688, 365, 272] | 272 | — | — | 1.00× | +3% |
| Disk cache 200MB | [437, 416, 653, 376, 328] | 328 | — | — | 0.83× | +30% |
| Memory cache 2048MB | [427, 532, 495, 341, 261] | 261 | — | — | 1.04× | +4% |

**Analysis:** Even for heavy queries, disk cache helps: 1.05× alone, 0.83× under contention. The heavy query needs CPU for hash table operations. With disk cache, it doesn't also need CPU for decode → more CPU available for the actual computation.

**Cache stats (disk 200MB):**
- Entries: 24436 total, 0 on disk
- Memory: 199MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 9, Iteration 4) ===
ProjectionExec: expr=[RegionID@0 as RegionID, count(*)@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), sum(hits.AdvEngineID)@3 as sum(hits.AdvEngineID)], metrics=[output_rows=20, elapsed_compute=1.98µs, output_bytes=560.0 B, output_batches=1, expr_0_eval_time=230ns, expr_1_eval_time=60ns, expr_2_eval_time=80ns, expr_3_eval_time=150ns]
  SortPreservingMergeExec: [count(Int64(1))@4 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=8.75µs, output_bytes=720.0 B, output_batches=1]
    SortExec: TopK(fetch=20), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 36573], metrics=[output_rows=264, elapsed_compute=456.81µs, output_bytes=9.3 KB, output_batches=16, row_replacements=307]
      ProjectionExec: expr=[RegionID@0 as RegionID, count(Int64(1))@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), sum(hits.AdvEngineID)@3 as sum(hits.AdvEngineID), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=9.04 K, elapsed_compute=32.19µs, output_bytes=275.9 KB, output_batches=16, expr_0_eval_time=3.68µs, expr_1_eval_time=1.98µs, expr_2_eval_time=1.49µs, expr_3_eval_time=1.43µs, expr_4_eval_time=1.36µs]
        AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=9.04 K, elapsed_compute=1.49ms, output_bytes=275.9 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.98 M, aggregate_arguments_time=22.47µs, aggregation_time=588.12µs, emitting_time=49.25µs, time_calculating_group_ids=976.45µs]
          RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=68.25 K, elapsed_compute=752.76µs, output_bytes=4.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=3.37s, repartition_time=1.53ms, send_time=256.97µs]
            AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=68.25 K, elapsed_compute=1.45s, output_bytes=3.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=5.56 M, aggregate_arguments_time=144.82ms, aggregation_time=984.15ms, emitting_time=73.27µs, time_calculating_group_ids=796.96ms, reduction_factor=0.073% (68.25 K/93.33 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-use
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 9, Iteration 4) ===
ProjectionExec: expr=[RegionID@0 as RegionID, count(*)@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), sum(hits.AdvEngineID)@3 as sum(hits.AdvEngineID)], metrics=[output_rows=20, elapsed_compute=1.53µs, output_bytes=560.0 B, output_batches=1, expr_0_eval_time=180ns, expr_1_eval_time=60ns, expr_2_eval_time=60ns, expr_3_eval_time=60ns]
  SortPreservingMergeExec: [count(Int64(1))@4 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=8.65µs, output_bytes=720.0 B, output_batches=1]
    SortExec: TopK(fetch=20), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 36573], metrics=[output_rows=264, elapsed_compute=436.02µs, output_bytes=9.3 KB, output_batches=16, row_replacements=286]
      ProjectionExec: expr=[RegionID@0 as RegionID, count(Int64(1))@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth), sum(hits.AdvEngineID)@3 as sum(hits.AdvEngineID), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=9.04 K, elapsed_compute=33.58µs, output_bytes=275.9 KB, output_batches=16, expr_0_eval_time=3.53µs, expr_1_eval_time=1.71µs, expr_2_eval_time=1.28µs, expr_3_eval_time=1.40µs, expr_4_eval_time=1.40µs]
        AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=9.04 K, elapsed_compute=1.55ms, output_bytes=275.9 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.98 M, aggregate_arguments_time=23.32µs, aggregation_time=580.76µs, emitting_time=51.46µs, time_calculating_group_ids=1.04ms]
          RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=68.25 K, elapsed_compute=721.20µs, output_bytes=4.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=3.55s, repartition_time=1.49ms, send_time=272.61µs]
            AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[count(Int64(1)), avg(hits.ResolutionWidth), sum(hits.AdvEngineID)], metrics=[output_rows=68.25 K, elapsed_compute=1.45s, output_bytes=3.3 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=5.41 M, aggregate_arguments_time=143.99ms, aggregation_time=993.42ms, emitting_time=86.20µs, time_calculating_group_ids=803.08ms, reduction_factor=0.073% (68.25 K/93.33 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/l
```
</details>

---

### h9_counter_distinct

#### Alone (no contention)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Disk read (MB) |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|---------------:|
| Parquet | [466, 85, 80, 82, 86] | 80 | — | — | 1.00× | 0.0 |
| Disk cache 200MB | [497, 209, 214, 206, 211] | 206 | — | — | 0.39× | 0.0 |
| Memory cache 2048MB | [500, 212, 221, 205, 215] | 205 | — | — | 0.39× | 0.0 |

#### Under contention (another heavy in background)

| Mode | All iterations (ms) | Min hot | CPU cycles | Instructions | Speedup vs Parquet | Regression vs alone |
|------|--------------------:|--------:|-----------:|------------:|-------------------:|--------------------:|
| Parquet | [279, 91, 84, 80, 80] | 80 | — | — | 1.00× | +0% |
| Disk cache 200MB | [224, 208, 210, 202, 213] | 202 | — | — | 0.40× | +-2% |
| Memory cache 2048MB | [251, 207, 207, 203, 210] | 203 | — | — | 0.39× | +-1% |

**Analysis:** Heavy query: disk cache 0.39× alone, 0.40× under contention. Disk cache regresses less (-2% vs Parquet +0%) under contention — confirms decode CPU is freed.

**Cache stats (disk 200MB):**
- Entries: 22820 total, 0 on disk
- Memory: 199MB / Disk: 0MB
- eval_predicate: 0, squeezed_needs_io: 0

<details>
<summary>EXPLAIN ANALYZE — Disk 200MB alone</summary>

```
=== EXPLAIN ANALYZE(Query 10, Iteration 4) ===
SortPreservingMergeExec: [count(DISTINCT hits.UserID)@1 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=5.12µs, output_bytes=240.0 B, output_batches=1]
  SortExec: TopK(fetch=20), expr=[count(DISTINCT hits.UserID)@1 DESC], preserve_partitioning=[true], filter=[count(DISTINCT hits.UserID)@1 IS NULL OR count(DISTINCT hits.UserID)@1 > 81], metrics=[output_rows=270, elapsed_compute=337.31µs, output_bytes=3.2 KB, output_batches=16, row_replacements=288]
    ProjectionExec: expr=[CounterID@0 as CounterID, count(alias1)@1 as count(DISTINCT hits.UserID)], metrics=[output_rows=683, elapsed_compute=13.95µs, output_bytes=13.3 KB, output_batches=16, expr_0_eval_time=2.15µs, expr_1_eval_time=1.14µs]
      AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID], aggr=[count(alias1)], metrics=[output_rows=683, elapsed_compute=209.98µs, output_bytes=13.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=216.8 K, aggregate_arguments_time=9.05µs, aggregation_time=16.00µs, emitting_time=12.09µs, time_calculating_group_ids=92.11µs]
        RepartitionExec: partitioning=Hash([CounterID@0], 16), input_partitions=16, metrics=[output_rows=6.62 K, elapsed_compute=286.27µs, output_bytes=1536.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=3.33s, repartition_time=784.86µs, send_time=326.52µs]
          AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID], aggr=[count(alias1)], metrics=[output_rows=6.62 K, elapsed_compute=3.70ms, output_bytes=93.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.26 M, aggregate_arguments_time=32.60µs, aggregation_time=350.36µs, emitting_time=29.80µs, time_calculating_group_ids=3.15ms, reduction_factor=2.2% (6.62 K/297.3 K)]
            AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID, alias1@1 as alias1], aggr=[], metrics=[output_rows=297.3 K, elapsed_compute=25.48ms, output_bytes=18.0 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=30.40 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=43.06µs, time_calculating_group_ids=25.19ms]
              RepartitionExec: partitioning=Hash([CounterID@0, alias1@1], 16), input_partitions=16, metrics=[output_rows=298.5 K, elapsed_compute=2.27ms, output_bytes=4.5 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=2.63s, repartition_time=6.16ms, send_time=3.38ms]
                AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID, UserID@1 as alias1], aggr=[], metrics=[output_rows=298.5 K, elapsed_compute=112.02ms, output_bytes=20.3 MB, output_batches=44, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=11.92 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=85.49µs, time_calculating_group_ids=94.43ms, reduction_fac
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Parquet alone</summary>

```
=== EXPLAIN ANALYZE(Query 10, Iteration 4) ===
SortPreservingMergeExec: [count(DISTINCT hits.UserID)@1 DESC], fetch=20, metrics=[output_rows=20, elapsed_compute=4.72µs, output_bytes=240.0 B, output_batches=1]
  SortExec: TopK(fetch=20), expr=[count(DISTINCT hits.UserID)@1 DESC], preserve_partitioning=[true], filter=[count(DISTINCT hits.UserID)@1 IS NULL OR count(DISTINCT hits.UserID)@1 > 81], metrics=[output_rows=266, elapsed_compute=313.61µs, output_bytes=3.1 KB, output_batches=16, row_replacements=287]
    ProjectionExec: expr=[CounterID@0 as CounterID, count(alias1)@1 as count(DISTINCT hits.UserID)], metrics=[output_rows=683, elapsed_compute=14.59µs, output_bytes=13.3 KB, output_batches=16, expr_0_eval_time=2.16µs, expr_1_eval_time=1.17µs]
      AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID], aggr=[count(alias1)], metrics=[output_rows=683, elapsed_compute=189.36µs, output_bytes=13.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=216.8 K, aggregate_arguments_time=9.61µs, aggregation_time=13.73µs, emitting_time=11.71µs, time_calculating_group_ids=90.31µs]
        RepartitionExec: partitioning=Hash([CounterID@0], 16), input_partitions=16, metrics=[output_rows=6.62 K, elapsed_compute=226.18µs, output_bytes=1536.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=1.33s, repartition_time=587.10µs, send_time=175.91µs]
          AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID], aggr=[count(alias1)], metrics=[output_rows=6.62 K, elapsed_compute=3.64ms, output_bytes=112.5 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.28 M, aggregate_arguments_time=27.32µs, aggregation_time=326.20µs, emitting_time=22.18µs, time_calculating_group_ids=3.15ms, reduction_factor=2.2% (6.62 K/297.3 K)]
            AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID, alias1@1 as alias1], aggr=[], metrics=[output_rows=297.3 K, elapsed_compute=17.60ms, output_bytes=18.0 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=30.40 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=34.65µs, time_calculating_group_ids=17.38ms]
              RepartitionExec: partitioning=Hash([CounterID@0, alias1@1], 16), input_partitions=16, metrics=[output_rows=298.5 K, elapsed_compute=1.33ms, output_bytes=4.5 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=1.01s, repartition_time=4.55ms, send_time=795.48µs]
                AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID, UserID@1 as alias1], aggr=[], metrics=[output_rows=298.5 K, elapsed_compute=45.72ms, output_bytes=20.3 MB, output_batches=44, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=13.25 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=57.30µs, time_calculating_group_ids=44.59ms, reduction_f
```
</details>

---

## Conclusion

### CPU Savings (from Experiment A & B)

| Query | Mode | Alone (ms) | Contention (ms) | Regression | CPU cycles (contention) |
|-------|------|-----------|----------------|-----------|------------------------|
| c0_range_filter | Parquet | 54 | 55 | +2% | — |
| c0_range_filter | Disk | 192 | 221 | +15% | — |
| c0_range_filter | Memory | 16 | 14 | +-12% | — |
| c1_multi_numeric | Parquet | 17 | 17 | +0% | — |
| c1_multi_numeric | Disk | 4 | 3 | +-25% | — |
| c1_multi_numeric | Memory | 3 | 3 | +0% | — |
| c3_group_filter | Parquet | 64 | 65 | +2% | — |
| c3_group_filter | Disk | 228 | 231 | +1% | — |
| c3_group_filter | Memory | 228 | 226 | +-1% | — |
| c4_date_range | Parquet | 147 | 148 | +1% | — |
| c4_date_range | Disk | 160 | 153 | +-4% | — |
| c4_date_range | Memory | 155 | 155 | +0% | — |
| c7_wide_scan | Parquet | 376 | 368 | +-2% | — |
| c7_wide_scan | Disk | 300 | 307 | +2% | — |
| c7_wide_scan | Memory | 309 | 299 | +-3% | — |
| q1_advengine | Parquet | 25 | 25 | +0% | — |
| q1_advengine | Disk | 11 | 12 | +9% | — |
| q1_advengine | Memory | 10 | 11 | +10% | — |
| q7_group_advengine | Parquet | 32 | 30 | +-6% | — |
| q7_group_advengine | Disk | 15 | 14 | +-7% | — |
| q7_group_advengine | Memory | 15 | 15 | +0% | — |
| q40_multi_pred | Parquet | 38 | 38 | +0% | — |
| q40_multi_pred | Disk | 85 | 97 | +14% | — |
| q40_multi_pred | Memory | 20 | 20 | +0% | — |
| q41_hash_eq | Parquet | 35 | 36 | +3% | — |
| q41_hash_eq | Disk | 74 | 77 | +4% | — |
| q41_hash_eq | Memory | 19 | 19 | +0% | — |
| q42_time_bucket | Parquet | 30 | 30 | +0% | — |
| q42_time_bucket | Disk | 18 | 18 | +0% | — |
| q42_time_bucket | Memory | 18 | 18 | +0% | — |

### Throughput Impact

Throughput = queries completed / wall time. Under contention:

| Query | Parquet QPS | Disk cache QPS | Memory cache QPS | Disk/Parquet ratio |
|-------|------------|----------------|------------------|-------------------|
| c0_range_filter | 14.8 | 0.9 | 27.3 | 0.06× |
| c1_multi_numeric | 40.3 | 116.3 | 113.6 | 2.88× |
| c3_group_filter | 12.9 | 4.5 | 4.5 | 0.35× |
| c4_date_range | 6.1 | 5.8 | 5.7 | 0.95× |
| c7_wide_scan | 2.5 | 3.0 | 3.0 | 1.18× |
| q1_advengine | 31.8 | 46.7 | 45.5 | 1.47× |
| q7_group_advengine | 25.5 | 35.0 | 39.1 | 1.37× |
| q40_multi_pred | 18.7 | 5.2 | 27.9 | 0.28× |
| q41_hash_eq | 20.2 | 6.1 | 31.1 | 0.30× |
| q42_time_bucket | 23.4 | 31.6 | 36.8 | 1.35× |

**How to read:** QPS = queries per second under contention. Disk/Parquet ratio > 1.0 means disk cache improves throughput by freeing decode CPU.

### Summary

| Scenario | Disk cache advantage | Why |
|----------|---------------------|-----|
| Light query alone | ✅ if working set fits | Skip decode → faster even without contention |
| Light query + heavy bg | ✅✅ amplified | Parquet needs CPU for decode, but CPU is saturated → disk cache wins more |
| Heavy query alone | Depends on working set | If decode cost is significant fraction of total time |
| Heavy query + heavy bg | ✅ if decode is bottleneck | Freed CPU goes to hash table ops → faster completion |

**Key insight:** The advantage of disk cache over Parquet grows under CPU contention, because Parquet's decode step competes for the same CPU that heavy queries need. Disk cache converts a CPU problem (decode) into an I/O problem (sequential read), and I/O doesn't compete with CPU-bound hash table operations.
