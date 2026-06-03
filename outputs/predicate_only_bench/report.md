# 3-Way Benchmark: DF vs DF+Pushdown vs LiquidCache (Predicate-Only)

**Config:** LiquidCache 2048MB, 5 iterations

**Metric:** Hot average (skip first cold iteration)


## Summary Table

| Query | No Pushdown (ms) | Pushdown (ms) | LiquidCache (ms) | Push vs NP | LC vs Push | LC vs NP |
|-------|-----------------|--------------|-----------------|-----------|-----------|----------|
| Q0 | 0 | 0 | 0 | 0.00x | 0.00x | 0.00x |
| Q1 | 24 | 26 | 12 | 0.92x | 2.23x | 2.06x |
| Q2 | 54 | 53 | 61 | 1.01x | 0.87x | 0.88x |
| Q3 | 58 | 56 | 65 | 1.04x | 0.87x | 0.90x |
| Q4 | 614 | 610 | 617 | 1.01x | 0.99x | 0.99x |
| Q5 | 664 | 674 | 708 | 0.98x | 0.95x | 0.94x |
| Q6 | 6 | 21 | 22 | 0.29x | 0.94x | 0.28x |
| Q7 | 26 | 33 | 15 | 0.79x | 2.15x | 1.70x |
| Q8 | 743 | 741 | 774 | 1.00x | 0.96x | 0.96x |
| Q9 | 920 | 920 | 920 | 1.00x | 1.00x | 1.00x |
| Q10 | 162 | 282 | 224 | 0.58x | 1.26x | 0.73x |
| Q11 | 196 | 303 | 252 | 0.65x | 1.20x | 0.78x |
| Q12 | 714 | 806 | 486 | 0.89x | 1.66x | 1.47x |
| Q13 | 1039 | 1214 | 1156 | 0.86x | 1.05x | 0.90x |
| Q14 | 707 | 832 | 794 | 0.85x | 1.05x | 0.89x |
| Q15 | 703 | 701 | 706 | 1.00x | 0.99x | 1.00x |
| Q16 | 1473 | 1467 | 1572 | 1.00x | 0.93x | 0.94x |
| Q17 | 1455 | 1460 | 1554 | 1.00x | 0.94x | 0.94x |
| Q18 | 3192 | 3286 | 3135 | 0.97x | 1.05x | 1.02x |
| Q19 | 60 | 85 | 20 | 0.70x | 4.20x | 2.94x |
| Q20 | 1028 | 1022 | 15314 | 1.01x | 0.07x | 0.07x |
| Q21 | 1263 | 1278 | 18077 | 0.99x | 0.07x | 0.07x |
| Q22 | 2998 | 2878 | 31785 | 1.04x | 0.09x | 0.09x |
| Q23 | 9633 | 1547 | 16684 | 6.23x | 0.09x | 0.58x |
| Q24 | 397 | 446 | 61 | 0.89x | 7.35x | 6.54x |
| Q25 | 306 | 387 | 86 | 0.79x | 4.47x | 3.54x |
| Q26 | 386 | 536 | 97 | 0.72x | 5.51x | 3.97x |
| Q27 | 1240 | 1484 | 13412 | 0.84x | 0.11x | 0.09x |
| Q28 | 8974 | 9152 | 10664 | 0.98x | 0.86x | 0.84x |
| Q29 | 377 | 378 | 392 | 1.00x | 0.97x | 0.96x |
| Q30 | 673 | 704 | 715 | 0.96x | 0.98x | 0.94x |
| Q31 | 829 | 860 | 934 | 0.96x | 0.92x | 0.89x |
| Q32 | 3295 | 3252 | 3355 | 1.01x | 0.97x | 0.98x |
| Q33 | 3456 | 3604 | 4882 | 0.96x | 0.74x | 0.71x |
| Q34 | 3414 | 3320 | 4718 | 1.03x | 0.70x | 0.72x |
| Q35 | 938 | 936 | 956 | 1.00x | 0.98x | 0.98x |
| Q36 | 152 | 125 | 75 | 1.21x | 1.67x | 2.03x |
| Q37 | 105 | 96 | 32 | 1.10x | 3.02x | 3.31x |
| Q38 | 106 | 73 | 61 | 1.45x | 1.20x | 1.74x |
| Q39 | 276 | 221 | 260 | 1.25x | 0.85x | 1.06x |
| Q40 | 34 | 40 | 20 | 0.86x | 1.96x | 1.68x |
| Q41 | 33 | 36 | 20 | 0.92x | 1.77x | 1.62x |
| Q42 | 30 | 32 | 20 | 0.95x | 1.63x | 1.55x |

## Aggregate Summary

- **LC faster than Pushdown:** 16 queries
- **LC neutral vs Pushdown:** 11 queries
- **LC slower than Pushdown:** 16 queries
- **Avg LC speedup (faster):** 2.65x
- **Slower queries:** Q0, Q2, Q3, Q6, Q16, Q17, Q20, Q21, Q22, Q23, Q27, Q28, Q31, Q33, Q34, Q39

---

## Per-Query Details

### Q0

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 3ms | 4ms | 10ms |
| Hot avg | 0ms | 0ms | 0ms |
| All iters | [3, 0, 0, 0, 0] | [4, 0, 0, 0, 0] | [10, 0, 0, 0, 0] |
| LC vs Push | | | **0.00x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[99997497 as count(*)], metrics=[output_rows=1, elapsed_compute=2.00µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=971ns]
  PlaceholderRowExec, metrics=[]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 10ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[99997497 as count(*)], metrics=[output_rows=1, elapsed_compute=1.04µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=490ns]
  PlaceholderRowExec, metrics=[]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 0ms
```
</details>

---

### Q1

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 53ms | 58ms | 63ms |
| Hot avg | 24ms | 26ms | 12ms |
| All iters | [53, 26, 24, 24, 23] | [58, 26, 28, 25, 26] | [63, 14, 11, 11, 11] |
| LC vs Push | | | **2.23x** |

**Cache Stats (after last iteration):**
- Entries: 11540 | Memory: 181MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.24µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=300ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=25.39µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=21.66µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=10.91ms, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=liquid_parquet, metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=5.87 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=941.5 K, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.98ms, metadata_load_time=175.16ms, page_index_eval_time=2.71µs, row_pushdown_eval_time=32ns, statistics_eval_time=353.80µs, time_elapsed_opening=205.66ms, time_elapsed_processing=534.93ms, time_elapsed_scanning_total=589.83ms, time_elapsed_scanning_until_data=64.09ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=23080
  Misses: cache_miss=11540
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 63ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.17µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=360ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=9.48µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=13.75µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=2.34ms, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=liquid_parquet, metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=5.87 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.88ms, metadata_load_time=1.69ms, page_index_eval_time=2.70µs, row_pushdown_eval_time=32ns, statistics_eval_time=263.92µs, time_elapsed_opening=5.05ms, time_elapsed_processing=113.25ms, time_elapsed_scanning_total=115.83ms, time_elapsed_scanning_until_data=1.42ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 11ms
```
</details>

---

### Q2

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 73ms | 71ms | 86ms |
| Hot avg | 54ms | 53ms | 61ms |
| All iters | [73, 55, 55, 53, 52] | [71, 52, 55, 54, 51] | [86, 61, 61, 61, 61] |
| LC vs Push | | | **0.87x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[sum(hits.AdvEngineID)@0 as sum(hits.AdvEngineID), count(Int64(1))@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth)], metrics=[output_rows=1, elapsed_compute=1.49µs, output_bytes=24.0 B, output_batches=1, expr_0_eval_time=270ns, expr_1_eval_time=70ns, expr_2_eval_time=50ns]
  AggregateExec: mode=Final, gby=[], aggr=[sum(hits.AdvEngineID), count(Int64(1)), avg(hits.ResolutionWidth)], metrics=[output_rows=1, elapsed_compute=36.14µs, output_bytes=24.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=23.50µs, output_bytes=512.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[sum(hits.AdvEngineID), count(Int64(1)), avg(hits.ResolutionWidth)], metrics=[output_rows=16, elapsed_compute=187.90ms, output_bytes=512.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[ResolutionWidth, AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=381.5 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=42.01 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=161.48ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=164.34ms, time_elapsed_processing=547.73ms, time_elapsed_scanning_total=860.54ms, time_elapsed_scanning_until_data=97.26ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 86ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[sum(hits.AdvEngineID)@0 as sum(hits.AdvEngineID), count(Int64(1))@1 as count(*), avg(hits.ResolutionWidth)@2 as avg(hits.ResolutionWidth)], metrics=[output_rows=1, elapsed_compute=1.57µs, output_bytes=24.0 B, output_batches=1, expr_0_eval_time=200ns, expr_1_eval_time=140ns, expr_2_eval_time=150ns]
  AggregateExec: mode=Final, gby=[], aggr=[sum(hits.AdvEngineID), count(Int64(1)), avg(hits.ResolutionWidth)], metrics=[output_rows=1, elapsed_compute=32.40µs, output_bytes=24.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=12.99µs, output_bytes=512.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[sum(hits.AdvEngineID), count(Int64(1)), avg(hits.ResolutionWidth)], metrics=[output_rows=16, elapsed_compute=184.73ms, output_bytes=512.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[ResolutionWidth, AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=381.5 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=42.01 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=1.69ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=3.28ms, time_elapsed_processing=468.73ms, time_elapsed_scanning_total=758.62ms, time_elapsed_scanning_until_data=17.37ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 61ms
```
</details>

---

### Q3

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 78ms | 76ms | 830ms |
| Hot avg | 58ms | 56ms | 65ms |
| All iters | [78, 55, 55, 64, 60] | [76, 58, 54, 57, 56] | [830, 63, 64, 69, 64] |
| LC vs Push | | | **0.87x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
AggregateExec: mode=Final, gby=[], aggr=[avg(hits.UserID)], metrics=[output_rows=1, elapsed_compute=22.86µs, output_bytes=8.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=21.38µs, output_bytes=256.0 B, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[avg(hits.UserID)], metrics=[output_rows=16, elapsed_compute=64.10ms, output_bytes=256.0 B, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=764.8 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=270.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=157.43ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=160.90ms, time_elapsed_processing=404.83ms, time_elapsed_scanning_total=9.28s, time_elapsed_scanning_until_data=96.59ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 830ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
AggregateExec: mode=Final, gby=[], aggr=[avg(hits.UserID)], metrics=[output_rows=1, elapsed_compute=23.65µs, output_bytes=8.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.80µs, output_bytes=256.0 B, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[avg(hits.UserID)], metrics=[output_rows=16, elapsed_compute=93.59ms, output_bytes=256.0 B, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=764.8 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=270.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=3.11ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=3.95ms, time_elapsed_processing=565.17ms, time_elapsed_scanning_total=800.88ms, time_elapsed_scanning_until_data=29.58ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 64ms
```
</details>

---

### Q4

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 641ms | 636ms | 660ms |
| Hot avg | 614ms | 610ms | 617ms |
| All iters | [641, 607, 624, 618, 605] | [636, 608, 625, 607, 601] | [660, 614, 615, 604, 635] |
| LC vs Push | | | **0.99x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[count(alias1)@0 as count(DISTINCT hits.UserID)], metrics=[output_rows=1, elapsed_compute=1.57µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=190ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(alias1)], metrics=[output_rows=1, elapsed_compute=10.83µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=18.94µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(alias1)], metrics=[output_rows=16, elapsed_compute=599.29µs, output_bytes=128.0 B, output_batches=16]
        AggregateExec: mode=FinalPartitioned, gby=[alias1@0 as alias1], aggr=[], metrics=[output_rows=17.63 M, elapsed_compute=3.34s, output_bytes=33.8 GB, output_batches=2.16 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.48 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=2.97ms, time_calculating_group_ids=3.33s]
          RepartitionExec: partitioning=Hash([alias1@0], 16), input_partitions=16, metrics=[output_rows=21.16 M, elapsed_compute=48.97ms, output_bytes=162.0 MB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=6.19s, repartition_time=208.85ms, send_time=707.13ms]
            AggregateExec: mode=Partial, gby=[UserID@0 as alias1], aggr=[], metrics=[output_rows=21.16 M, elapsed_compute=4.79s, output_bytes=42.2 GB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=730.9 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=2.22ms, time_calculating_group_ids=4.77s, reduction_factor=21% (21.16 M/100.00 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=764.8 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=270.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=158.74ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=161.26ms, time_elapsed_processing=681.42ms, time_elapsed_scanning_total=6.02s, time_elapsed_scanning_until_data=135.88ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 660ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[count(alias1)@0 as count(DISTINCT hits.UserID)], metrics=[output_rows=1, elapsed_compute=2.04µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=230ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(alias1)], metrics=[output_rows=1, elapsed_compute=14.47µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=15.12µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(alias1)], metrics=[output_rows=16, elapsed_compute=610.80µs, output_bytes=128.0 B, output_batches=16]
        AggregateExec: mode=FinalPartitioned, gby=[alias1@0 as alias1], aggr=[], metrics=[output_rows=17.63 M, elapsed_compute=3.17s, output_bytes=33.8 GB, output_batches=2.16 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.48 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=3.28ms, time_calculating_group_ids=3.16s]
          RepartitionExec: partitioning=Hash([alias1@0], 16), input_partitions=16, metrics=[output_rows=21.16 M, elapsed_compute=97.95ms, output_bytes=162.0 MB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=5.69s, repartition_time=195.14ms, send_time=742.30ms]
            AggregateExec: mode=Partial, gby=[UserID@0 as alias1], aggr=[], metrics=[output_rows=21.16 M, elapsed_compute=4.49s, output_bytes=42.2 GB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=730.9 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=2.21ms, time_calculating_group_ids=4.48s, reduction_factor=21% (21.16 M/100.00 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=764.8 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=270.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=1.89ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=2.71ms, time_elapsed_processing=632.92ms, time_elapsed_scanning_total=5.68s, time_elapsed_scanning_until_data=58.74ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 635ms
```
</details>

---

### Q5

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 677ms | 671ms | 817ms |
| Hot avg | 664ms | 674ms | 708ms |
| All iters | [677, 647, 670, 657, 682] | [671, 682, 669, 677, 669] | [817, 716, 692, 713, 710] |
| LC vs Push | | | **0.95x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[count(alias1)@0 as count(DISTINCT hits.SearchPhrase)], metrics=[output_rows=1, elapsed_compute=1.87µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=110ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(alias1)], metrics=[output_rows=1, elapsed_compute=7.70µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=19.36µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(alias1)], metrics=[output_rows=16, elapsed_compute=286.49µs, output_bytes=128.0 B, output_batches=16]
        AggregateExec: mode=FinalPartitioned, gby=[alias1@0 as alias1], aggr=[], metrics=[output_rows=6.02 M, elapsed_compute=2.13s, output_bytes=24.5 GB, output_batches=739, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.61 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=61.34µs, time_calculating_group_ids=2.12s]
          RepartitionExec: partitioning=Hash([alias1@0], 16), input_partitions=16, metrics=[output_rows=7.17 M, elapsed_compute=123.88ms, output_bytes=457.7 MB, output_batches=880, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=8.12s, repartition_time=284.19ms, send_time=353.79ms]
            AggregateExec: mode=Partial, gby=[SearchPhrase@0 as alias1], aggr=[], metrics=[output_rows=7.17 M, elapsed_compute=4.06s, output_bytes=39.5 GB, output_batches=885, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=973.0 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=90.25µs, time_calculating_group_ids=4.05s, reduction_factor=7.2% (7.17 M/100.00 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1629.8 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=373.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=158.13ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=159.33ms, time_elapsed_processing=3.29s, time_elapsed_scanning_total=7.96s, time_elapsed_scanning_until_data=200.95ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 817ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[count(alias1)@0 as count(DISTINCT hits.SearchPhrase)], metrics=[output_rows=1, elapsed_compute=1.70µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=210ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(alias1)], metrics=[output_rows=1, elapsed_compute=8.14µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.74µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(alias1)], metrics=[output_rows=16, elapsed_compute=220.15µs, output_bytes=128.0 B, output_batches=16]
        AggregateExec: mode=FinalPartitioned, gby=[alias1@0 as alias1], aggr=[], metrics=[output_rows=6.02 M, elapsed_compute=1.99s, output_bytes=24.5 GB, output_batches=739, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.61 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=65.79µs, time_calculating_group_ids=1.98s]
          RepartitionExec: partitioning=Hash([alias1@0], 16), input_partitions=16, metrics=[output_rows=7.17 M, elapsed_compute=123.14ms, output_bytes=457.7 MB, output_batches=880, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=7.82s, repartition_time=300.94ms, send_time=354.88ms]
            AggregateExec: mode=Partial, gby=[SearchPhrase@0 as alias1], aggr=[], metrics=[output_rows=7.17 M, elapsed_compute=3.97s, output_bytes=39.5 GB, output_batches=885, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=973.0 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=92.21µs, time_calculating_group_ids=3.95s, reduction_factor=7.2% (7.17 M/100.00 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1629.8 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=373.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=1.64ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=2.40ms, time_elapsed_processing=3.21s, time_elapsed_scanning_total=7.81s, time_elapsed_scanning_until_data=97.85ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 710ms
```
</details>

---

### Q6

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 14ms | 32ms | 64ms |
| Hot avg | 6ms | 21ms | 22ms |
| All iters | [14, 8, 5, 6, 6] | [32, 18, 23, 23, 21] | [64, 24, 22, 22, 22] |
| LC vs Push | | | **0.94x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 191MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
AggregateExec: mode=Final, gby=[], aggr=[min(hits.EventDate), max(hits.EventDate)], metrics=[output_rows=1, elapsed_compute=54.54µs, output_bytes=8.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=18.99µs, output_bytes=142.0 B, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[min(hits.EventDate), max(hits.EventDate)], metrics=[output_rows=16, elapsed_compute=251.67µs, output_bytes=142.0 B, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CAST(CAST(EventDate@5 AS Int32) AS Date32) as __common_expr_1], file_type=liquid_parquet, metrics=[output_rows=67.27 K, elapsed_compute=16ns, output_bytes=262.8 KB, output_batches=9, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=80.05 K, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=67.27 K, pushdown_rows_pruned=99.93 M, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=160.76ms, page_index_eval_time=2.67µs, row_pushdown_eval_time=219.11ms, statistics_eval_time=32ns, time_elapsed_opening=167.06ms, time_elapsed_processing=598.36ms, time_elapsed_scanning_total=663.64ms, time_elapsed_scanning_until_data=297.76ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=191MB, disk=0MB
  Hits: cache_hit=12227, eval_predicate=0
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 64ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
AggregateExec: mode=Final, gby=[], aggr=[min(hits.EventDate), max(hits.EventDate)], metrics=[output_rows=1, elapsed_compute=19.92µs, output_bytes=8.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.33µs, output_bytes=142.0 B, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[min(hits.EventDate), max(hits.EventDate)], metrics=[output_rows=16, elapsed_compute=104.12µs, output_bytes=142.0 B, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CAST(CAST(EventDate@5 AS Int32) AS Date32) as __common_expr_1], file_type=liquid_parquet, metrics=[output_rows=62.08 K, elapsed_compute=16ns, output_bytes=242.6 KB, output_batches=10, files_ranges_pruned_statistics=16 total → 15 matched, row_groups_pruned_statistics=131 total → 97 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=62.08 K, pushdown_rows_pruned=79.76 M, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.09ms, metadata_load_time=1.86ms, page_index_eval_time=2.90µs, row_pushdown_eval_time=174.03ms, statistics_eval_time=202.88µs, time_elapsed_opening=4.47ms, time_elapsed_processing=212.31ms, time_elapsed_scanning_total=207.93ms, time_elapsed_scanning_until_data=83.52ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=191MB, disk=0MB
  Hits: cache_hit=9764, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 22ms
```
</details>

---

### Q7

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 61ms | 70ms | 64ms |
| Hot avg | 26ms | 33ms | 15ms |
| All iters | [61, 27, 26, 26, 25] | [70, 32, 35, 32, 32] | [64, 14, 15, 16, 16] |
| LC vs Push | | | **2.15x** |

**Cache Stats (after last iteration):**
- Entries: 11540 | Memory: 181MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(*)@1 as count(*)], metrics=[output_rows=18, elapsed_compute=1.15µs, output_bytes=180.0 B, output_batches=1, expr_0_eval_time=180ns, expr_1_eval_time=49ns]
  SortPreservingMergeExec: [count(Int64(1))@2 DESC], metrics=[output_rows=18, elapsed_compute=27.67µs, output_bytes=324.0 B, output_batches=1]
    SortExec: expr=[count(*)@1 DESC], preserve_partitioning=[true], metrics=[output_rows=18, elapsed_compute=17.84µs, output_bytes=0.0 B, output_batches=0, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0]
      ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(Int64(1))@1 as count(*), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=18, elapsed_compute=9.42µs, output_bytes=2.8 KB, output_batches=10, expr_0_eval_time=1.29µs, expr_1_eval_time=798ns, expr_2_eval_time=816ns]
        AggregateExec: mode=FinalPartitioned, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=18, elapsed_compute=85.05µs, output_bytes=2.8 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=80.06 K, aggregate_arguments_time=5.47µs, aggregation_time=5.88µs, emitting_time=8.56µs, time_calculating_group_ids=11.14µs]
          RepartitionExec: partitioning=Hash([AdvEngineID@0], 16), input_partitions=16, metrics=[output_rows=164, elapsed_compute=3.29ms, output_bytes=800.0 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=815.48ms, repartition_time=273.65µs, send_time=215.68µs]
            AggregateExec: mode=Partial, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=164, elapsed_compute=27.42ms, output_bytes=5.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=342.8 K, aggregate_arguments_time=10.53ms, aggregation_time=1.97ms, emitting_time=89.07µs, time_calculating_group_ids=8.48ms, reduction_factor=0.026% (164/630.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=1469.4 KB, output_batches=5.87 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=941.5 K, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.91ms, metadata_load_time=163.50ms, page_index_eval_time=2.82µs, row_pushdown_eval_time=32ns, statistics_eval_time=288.52µs, time_elapsed_opening=202.74ms, time_elapsed_processing=559.87ms, time_elapsed_scanning_total=611.98ms, time_elapsed_scanning_until_data=56.37ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=23080
  Misses: cache_miss=11540
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 64ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(*)@1 as count(*)], metrics=[output_rows=18, elapsed_compute=1.50µs, output_bytes=180.0 B, output_batches=1, expr_0_eval_time=260ns, expr_1_eval_time=80ns]
  SortPreservingMergeExec: [count(Int64(1))@2 DESC], metrics=[output_rows=18, elapsed_compute=11.33µs, output_bytes=324.0 B, output_batches=1]
    SortExec: expr=[count(*)@1 DESC], preserve_partitioning=[true], metrics=[output_rows=18, elapsed_compute=17.01µs, output_bytes=0.0 B, output_batches=0, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0]
      ProjectionExec: expr=[AdvEngineID@0 as AdvEngineID, count(Int64(1))@1 as count(*), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=18, elapsed_compute=9.45µs, output_bytes=2.8 KB, output_batches=10, expr_0_eval_time=1.26µs, expr_1_eval_time=876ns, expr_2_eval_time=785ns]
        AggregateExec: mode=FinalPartitioned, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=18, elapsed_compute=96.50µs, output_bytes=2.8 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=80.06 K, aggregate_arguments_time=5.34µs, aggregation_time=5.06µs, emitting_time=7.14µs, time_calculating_group_ids=9.12µs]
          RepartitionExec: partitioning=Hash([AdvEngineID@0], 16), input_partitions=16, metrics=[output_rows=164, elapsed_compute=135.94µs, output_bytes=800.0 KB, output_batches=10, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=144.61ms, repartition_time=112.11µs, send_time=109.43µs]
            AggregateExec: mode=Partial, gby=[AdvEngineID@0 as AdvEngineID], aggr=[count(Int64(1))], metrics=[output_rows=164, elapsed_compute=12.49ms, output_bytes=5.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=342.8 K, aggregate_arguments_time=2.36ms, aggregation_time=1.36ms, emitting_time=19.61µs, time_calculating_group_ids=5.32ms, reduction_factor=0.026% (164/630.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=630.5 K, elapsed_compute=16ns, output_bytes=1469.4 KB, output_batches=5.87 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 212 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.85ms, metadata_load_time=1.86ms, page_index_eval_time=3.05µs, row_pushdown_eval_time=32ns, statistics_eval_time=316.51µs, time_elapsed_opening=5.63ms, time_elapsed_processing=123.50ms, time_elapsed_scanning_total=138.55ms, time_elapsed_scanning_until_data=1.49ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 16ms
```
</details>

---

### Q8

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 785ms | 799ms | 809ms |
| Hot avg | 743ms | 741ms | 774ms |
| All iters | [785, 746, 752, 737, 736] | [799, 744, 743, 734, 743] | [809, 755, 799, 763, 781] |
| LC vs Push | | | **0.96x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [u@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=4.63µs, output_bytes=120.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[u@1 DESC], preserve_partitioning=[true], filter=[u@1 IS NULL OR u@1 > 32992], metrics=[output_rows=123, elapsed_compute=712.13µs, output_bytes=1476.0 B, output_batches=16, row_replacements=135]
    ProjectionExec: expr=[RegionID@0 as RegionID, count(alias1)@1 as u], metrics=[output_rows=9.04 K, elapsed_compute=20.41µs, output_bytes=134.6 KB, output_batches=16, expr_0_eval_time=3.30µs, expr_1_eval_time=1.23µs]
      AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[count(alias1)], metrics=[output_rows=9.04 K, elapsed_compute=1.31ms, output_bytes=134.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.75 M, aggregate_arguments_time=9.89µs, aggregation_time=110.67µs, emitting_time=14.12µs, time_calculating_group_ids=1.07ms]
        RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=69.75 K, elapsed_compute=819.17µs, output_bytes=1536.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=12.70s, repartition_time=1.75ms, send_time=344.67µs]
          AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[count(alias1)], metrics=[output_rows=69.75 K, elapsed_compute=171.78ms, output_bytes=1207.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=4.12 M, aggregate_arguments_time=568.66µs, aggregation_time=12.69ms, emitting_time=66.30µs, time_calculating_group_ids=156.75ms, reduction_factor=0.39% (69.75 K/18.00 M)]
            AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID, alias1@1 as alias1], aggr=[], metrics=[output_rows=18.00 M, elapsed_compute=3.66s, output_bytes=51.8 GB, output_batches=2.21 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.75 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=33.45µs, time_calculating_group_ids=3.66s]
              RepartitionExec: partitioning=Hash([RegionID@0, alias1@1], 16), input_partitions=16, metrics=[output_rows=21.32 M, elapsed_compute=72.64ms, output_bytes=244.5 MB, output_batches=2.61 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=7.66s, repartition_time=332.71ms, send_time=939.61ms]
                AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID, UserID@1 as alias1], aggr=[], metrics=[output_rows=21.32 M, elapsed_compute=5.71s, output_bytes=63.7 GB, output_batches=2.61 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=861.9 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=93.64µs, time_calculating_group_ids=5.69s, reduction_factor=21% (21.32 M/100.00 M)]
                  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[RegionID, UserID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1146.4 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=328.6 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=159.05ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=169.45ms, time_elapsed_processing=1.07s, time_elapsed_scanning_total=7.48s, time_elapsed_scanning_until_data=214.70ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 809ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [u@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=4.39µs, output_bytes=120.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[u@1 DESC], preserve_partitioning=[true], filter=[u@1 IS NULL OR u@1 > 32992], metrics=[output_rows=126, elapsed_compute=522.74µs, output_bytes=1512.0 B, output_batches=16, row_replacements=147]
    ProjectionExec: expr=[RegionID@0 as RegionID, count(alias1)@1 as u], metrics=[output_rows=9.04 K, elapsed_compute=22.88µs, output_bytes=134.6 KB, output_batches=16, expr_0_eval_time=3.49µs, expr_1_eval_time=1.37µs]
      AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[count(alias1)], metrics=[output_rows=9.04 K, elapsed_compute=1.27ms, output_bytes=134.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.75 M, aggregate_arguments_time=11.03µs, aggregation_time=118.37µs, emitting_time=22.04µs, time_calculating_group_ids=1.04ms]
        RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=69.75 K, elapsed_compute=597.35µs, output_bytes=1536.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=12.32s, repartition_time=2.41ms, send_time=552.87µs]
          AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[count(alias1)], metrics=[output_rows=69.75 K, elapsed_compute=169.80ms, output_bytes=1162.7 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=4.08 M, aggregate_arguments_time=607.61µs, aggregation_time=11.94ms, emitting_time=84.81µs, time_calculating_group_ids=155.41ms, reduction_factor=0.39% (69.75 K/18.00 M)]
            AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID, alias1@1 as alias1], aggr=[], metrics=[output_rows=18.00 M, elapsed_compute=3.55s, output_bytes=51.8 GB, output_batches=2.21 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.75 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=28.78µs, time_calculating_group_ids=3.55s]
              RepartitionExec: partitioning=Hash([RegionID@0, alias1@1], 16), input_partitions=16, metrics=[output_rows=21.32 M, elapsed_compute=89.09ms, output_bytes=244.5 MB, output_batches=2.61 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=7.18s, repartition_time=325.03ms, send_time=890.98ms]
                AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID, UserID@1 as alias1], aggr=[], metrics=[output_rows=21.32 M, elapsed_compute=5.58s, output_bytes=63.7 GB, output_batches=2.61 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=861.9 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=75.67µs, time_calculating_group_ids=5.56s, reduction_factor=21% (21.32 M/100.00 M)]
                  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[RegionID, UserID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1146.4 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=328.6 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=2.01ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=2.90ms, time_elapsed_processing=1.01s, time_elapsed_scanning_total=7.17s, time_elapsed_scanning_until_data=67.31ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 781ms
```
</details>

---

### Q9

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 941ms | 930ms | 973ms |
| Hot avg | 920ms | 920ms | 920ms |
| All iters | [941, 927, 923, 903, 925] | [930, 924, 919, 923, 912] | [973, 929, 931, 925, 896] |
| LC vs Push | | | **1.00x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=13.15µs, output_bytes=360.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 141991], metrics=[output_rows=141, elapsed_compute=1.01ms, output_bytes=5.0 KB, output_batches=16, row_replacements=154]
    ProjectionExec: expr=[RegionID@0 as RegionID, sum(hits.AdvEngineID)@1 as sum(hits.AdvEngineID), count(Int64(1))@2 as c, avg(hits.ResolutionWidth)@3 as avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)@4 as count(DISTINCT hits.UserID)], metrics=[output_rows=9.04 K, elapsed_compute=70.53µs, output_bytes=403.9 KB, output_batches=16, expr_0_eval_time=21.61µs, expr_1_eval_time=2.24µs, expr_2_eval_time=2.46µs, expr_3_eval_time=1.32µs, expr_4_eval_time=870ns]
      AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[sum(hits.AdvEngineID), count(Int64(1)), avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)], metrics=[output_rows=9.04 K, elapsed_compute=1.12s, output_bytes=403.9 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=541.4 M, aggregate_arguments_time=206.75µs, aggregation_time=1.11s, emitting_time=2.15ms, time_calculating_group_ids=3.90ms]
        RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=68.25 K, elapsed_compute=195.96ms, output_bytes=167.6 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=9.35s, repartition_time=50.63ms, send_time=716.82µs]
          AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[sum(hits.AdvEngineID), count(Int64(1)), avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)], metrics=[output_rows=68.25 K, elapsed_compute=7.09s, output_bytes=166.6 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=335.6 M, aggregate_arguments_time=179.13ms, aggregation_time=6.91s, emitting_time=132.76ms, time_calculating_group_ids=919.90ms, reduction_factor=0.068% (68.25 K/100.00 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[RegionID, UserID, ResolutionWidth, AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1527.9 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=370.6 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=165.07ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=173.00ms, time_elapsed_processing=1.48s, time_elapsed_scanning_total=9.05s, time_elapsed_scanning_until_data=267.50ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 973ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=13.13µs, output_bytes=360.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 141991], metrics=[output_rows=140, elapsed_compute=1.02ms, output_bytes=4.9 KB, output_batches=16, row_replacements=151]
    ProjectionExec: expr=[RegionID@0 as RegionID, sum(hits.AdvEngineID)@1 as sum(hits.AdvEngineID), count(Int64(1))@2 as c, avg(hits.ResolutionWidth)@3 as avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)@4 as count(DISTINCT hits.UserID)], metrics=[output_rows=9.04 K, elapsed_compute=83.96µs, output_bytes=403.9 KB, output_batches=16, expr_0_eval_time=22.00µs, expr_1_eval_time=2.65µs, expr_2_eval_time=2.40µs, expr_3_eval_time=2.20µs, expr_4_eval_time=2.72µs]
      AggregateExec: mode=FinalPartitioned, gby=[RegionID@0 as RegionID], aggr=[sum(hits.AdvEngineID), count(Int64(1)), avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)], metrics=[output_rows=9.04 K, elapsed_compute=1.08s, output_bytes=403.9 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=541.4 M, aggregate_arguments_time=170.31µs, aggregation_time=1.08s, emitting_time=2.19ms, time_calculating_group_ids=3.10ms]
        RepartitionExec: partitioning=Hash([RegionID@0], 16), input_partitions=16, metrics=[output_rows=68.25 K, elapsed_compute=187.62ms, output_bytes=167.6 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=9.14s, repartition_time=52.46ms, send_time=569.82µs]
          AggregateExec: mode=Partial, gby=[RegionID@0 as RegionID], aggr=[sum(hits.AdvEngineID), count(Int64(1)), avg(hits.ResolutionWidth), count(DISTINCT hits.UserID)], metrics=[output_rows=68.25 K, elapsed_compute=7.33s, output_bytes=166.6 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=335.6 M, aggregate_arguments_time=188.24ms, aggregation_time=7.09s, emitting_time=168.41ms, time_calculating_group_ids=908.04ms, reduction_factor=0.068% (68.25 K/100.00 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[RegionID, UserID, ResolutionWidth, AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1527.9 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=370.6 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=3.00ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=4.31ms, time_elapsed_processing=1.39s, time_elapsed_scanning_total=8.97s, time_elapsed_scanning_until_data=77.32ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 896ms
```
</details>

---

### Q10

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 202ms | 331ms | 279ms |
| Hot avg | 162ms | 282ms | 224ms |
| All iters | [202, 163, 162, 164, 161] | [331, 283, 283, 282, 281] | [279, 226, 223, 213, 234] |
| LC vs Push | | | **1.26x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 795MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [u@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=5.72µs, output_bytes=193.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[u@1 DESC], preserve_partitioning=[true], filter=[u@1 IS NULL OR u@1 > 6], metrics=[output_rows=126, elapsed_compute=355.47µs, output_bytes=2.5 KB, output_batches=16, row_replacements=128]
    ProjectionExec: expr=[MobilePhoneModel@0 as MobilePhoneModel, count(alias1)@1 as u], metrics=[output_rows=165, elapsed_compute=15.07µs, output_bytes=130.2 KB, output_batches=16, expr_0_eval_time=2.19µs, expr_1_eval_time=1.19µs]
      AggregateExec: mode=FinalPartitioned, gby=[MobilePhoneModel@0 as MobilePhoneModel], aggr=[count(alias1)], metrics=[output_rows=165, elapsed_compute=1.39ms, output_bytes=130.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=317.0 K, aggregate_arguments_time=11.49µs, aggregation_time=12.96µs, emitting_time=20.12µs, time_calculating_group_ids=86.89µs]
        RepartitionExec: partitioning=Hash([MobilePhoneModel@0], 16), input_partitions=16, metrics=[output_rows=1.53 K, elapsed_compute=337.74µs, output_bytes=1041.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=4.35s, repartition_time=513.70µs, send_time=161.47µs]
          AggregateExec: mode=Partial, gby=[MobilePhoneModel@0 as MobilePhoneModel], aggr=[count(alias1)], metrics=[output_rows=1.53 K, elapsed_compute=22.01ms, output_bytes=157.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.26 M, aggregate_arguments_time=52.44µs, aggregation_time=2.06ms, emitting_time=42.22µs, time_calculating_group_ids=19.67ms, reduction_factor=0.13% (1.53 K/1.19 M)]
            AggregateExec: mode=FinalPartitioned, gby=[MobilePhoneModel@0 as MobilePhoneModel, alias1@1 as alias1], aggr=[], metrics=[output_rows=1.19 M, elapsed_compute=184.49ms, output_bytes=320.0 MB, output_batches=160, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=129.0 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=26.84µs, time_calculating_group_ids=183.96ms]
              RepartitionExec: partitioning=Hash([MobilePhoneModel@0, alias1@1], 16), input_partitions=16, metrics=[output_rows=1.37 M, elapsed_compute=7.94ms, output_bytes=21.7 MB, output_batches=176, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=3.32s, repartition_time=30.64ms, send_time=21.87ms]
                AggregateExec: mode=Partial, gby=[MobilePhoneModel@1 as MobilePhoneModel, UserID@0 as alias1], aggr=[], metrics=[output_rows=1.37 M, elapsed_compute=445.48ms, output_bytes=373.0 MB, output_batches=177, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=63.04 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=68.33µs, time_calculating_group_ids=430.50ms, reduction_factor=25% (1.37 M/5.56 M)]
                  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, MobilePhoneModel], file_type=liquid_parquet, metrics=[output_rows=5.56 M, elapsed_compute=16ns, output_bytes=86.2 MB, output_batches=12.20 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=274.9 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.05ms, metadata_load_time=155.78ms, page_index_eval_time=2.58µs, row_pushdown_eval_time=32ns, statistics_eval_time=349.69µs, time_elapsed_opening=170.73ms, time_elapsed_processing=2.39s, time_elapsed_scanning_total=3.15s, time_elapsed_scanning_until_data=172.20ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=795MB, disk=0MB
  Hits: cache_hit=12201, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 279ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [u@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=10.42µs, output_bytes=193.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[u@1 DESC], preserve_partitioning=[true], filter=[u@1 IS NULL OR u@1 > 6], metrics=[output_rows=111, elapsed_compute=312.86µs, output_bytes=2.2 KB, output_batches=16, row_replacements=112]
    ProjectionExec: expr=[MobilePhoneModel@0 as MobilePhoneModel, count(alias1)@1 as u], metrics=[output_rows=165, elapsed_compute=16.26µs, output_bytes=130.2 KB, output_batches=16, expr_0_eval_time=2.21µs, expr_1_eval_time=1.15µs]
      AggregateExec: mode=FinalPartitioned, gby=[MobilePhoneModel@0 as MobilePhoneModel], aggr=[count(alias1)], metrics=[output_rows=165, elapsed_compute=203.90µs, output_bytes=130.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=317.0 K, aggregate_arguments_time=11.52µs, aggregation_time=11.78µs, emitting_time=19.58µs, time_calculating_group_ids=87.05µs]
        RepartitionExec: partitioning=Hash([MobilePhoneModel@0], 16), input_partitions=16, metrics=[output_rows=1.53 K, elapsed_compute=342.08µs, output_bytes=1041.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=3.68s, repartition_time=580.89µs, send_time=152.92µs]
          AggregateExec: mode=Partial, gby=[MobilePhoneModel@0 as MobilePhoneModel], aggr=[count(alias1)], metrics=[output_rows=1.53 K, elapsed_compute=23.13ms, output_bytes=156.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.26 M, aggregate_arguments_time=54.65µs, aggregation_time=2.10ms, emitting_time=41.26µs, time_calculating_group_ids=20.74ms, reduction_factor=0.13% (1.53 K/1.19 M)]
            AggregateExec: mode=FinalPartitioned, gby=[MobilePhoneModel@0 as MobilePhoneModel, alias1@1 as alias1], aggr=[], metrics=[output_rows=1.19 M, elapsed_compute=165.19ms, output_bytes=320.0 MB, output_batches=160, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=129.0 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=28.75µs, time_calculating_group_ids=164.66ms]
              RepartitionExec: partitioning=Hash([MobilePhoneModel@0, alias1@1], 16), input_partitions=16, metrics=[output_rows=1.37 M, elapsed_compute=7.82ms, output_bytes=21.7 MB, output_batches=176, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=2.60s, repartition_time=32.31ms, send_time=13.22ms]
                AggregateExec: mode=Partial, gby=[MobilePhoneModel@1 as MobilePhoneModel, UserID@0 as alias1], aggr=[], metrics=[output_rows=1.37 M, elapsed_compute=351.54ms, output_bytes=373.0 MB, output_batches=177, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=63.04 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=45.47µs, time_calculating_group_ids=339.23ms, reduction_factor=25% (1.37 M/5.56 M)]
                  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, MobilePhoneModel], file_type=liquid_parquet, metrics=[output_rows=5.56 M, elapsed_compute=16ns, output_bytes=86.2 MB, output_batches=12.20 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=287.3 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.39ms, metadata_load_time=2.24ms, page_index_eval_time=4.10µs, row_pushdown_eval_time=32ns, statistics_eval_time=341.54µs, time_elapsed_opening=6.81ms, time_elapsed_processing=2.05s, time_elapsed_scanning_total=2.59s, time_elapsed_scanning_until_data=44.57ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=795MB, disk=0MB
  Hits: cache_hit=12201, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 234ms
```
</details>

---

### Q11

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 228ms | 357ms | 298ms |
| Hot avg | 196ms | 303ms | 252ms |
| All iters | [228, 204, 189, 194, 195] | [357, 302, 306, 305, 298] | [298, 240, 254, 265, 248] |
| LC vs Push | | | **1.20x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 795MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [u@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=6.55µs, output_bytes=188.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[u@2 DESC], preserve_partitioning=[true], filter=[u@2 IS NULL OR u@2 > 31], metrics=[output_rows=133, elapsed_compute=497.15µs, output_bytes=2.8 KB, output_batches=16, row_replacements=138]
    ProjectionExec: expr=[MobilePhone@0 as MobilePhone, MobilePhoneModel@1 as MobilePhoneModel, count(alias1)@2 as u], metrics=[output_rows=302, elapsed_compute=19.57µs, output_bytes=133.0 KB, output_batches=16, expr_0_eval_time=2.85µs, expr_1_eval_time=1.18µs, expr_2_eval_time=1.22µs]
      AggregateExec: mode=FinalPartitioned, gby=[MobilePhone@0 as MobilePhone, MobilePhoneModel@1 as MobilePhoneModel], aggr=[count(alias1)], metrics=[output_rows=302, elapsed_compute=382.82µs, output_bytes=133.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=344.2 K, aggregate_arguments_time=9.49µs, aggregation_time=12.98µs, emitting_time=23.14µs, time_calculating_group_ids=228.26µs]
        RepartitionExec: partitioning=Hash([MobilePhone@0, MobilePhoneModel@1], 16), input_partitions=16, metrics=[output_rows=2.61 K, elapsed_compute=372.77µs, output_bytes=1308.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=4.65s, repartition_time=666.66µs, send_time=197.40µs]
          AggregateExec: mode=Partial, gby=[MobilePhone@0 as MobilePhone, MobilePhoneModel@1 as MobilePhoneModel], aggr=[count(alias1)], metrics=[output_rows=2.61 K, elapsed_compute=36.09ms, output_bytes=176.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.33 M, aggregate_arguments_time=61.15µs, aggregation_time=2.02ms, emitting_time=21.63µs, time_calculating_group_ids=33.78ms, reduction_factor=0.22% (2.61 K/1.19 M)]
            AggregateExec: mode=FinalPartitioned, gby=[MobilePhone@0 as MobilePhone, MobilePhoneModel@1 as MobilePhoneModel, alias1@2 as alias1], aggr=[], metrics=[output_rows=1.19 M, elapsed_compute=180.43ms, output_bytes=360.0 MB, output_batches=160, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=137.4 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=35.63µs, time_calculating_group_ids=179.86ms]
              RepartitionExec: partitioning=Hash([MobilePhone@0, MobilePhoneModel@1, alias1@2], 16), input_partitions=16, metrics=[output_rows=1.37 M, elapsed_compute=10.04ms, output_bytes=24.5 MB, output_batches=176, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=3.61s, repartition_time=36.75ms, send_time=30.80ms]
                AggregateExec: mode=Partial, gby=[MobilePhone@1 as MobilePhone, MobilePhoneModel@2 as MobilePhoneModel, UserID@0 as alias1], aggr=[], metrics=[output_rows=1.37 M, elapsed_compute=461.96ms, output_bytes=419.4 MB, output_batches=177, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=67.10 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=77.53µs, time_calculating_group_ids=445.38ms, reduction_factor=25% (1.37 M/5.56 M)]
                  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, MobilePhone, MobilePhoneModel], file_type=liquid_parquet, metrics=[output_rows=5.56 M, elapsed_compute=16ns, output_bytes=97.2 MB, output_batches=12.20 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=281.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.05ms, metadata_load_time=156.83ms, page_index_eval_time=2.60µs, row_pushdown_eval_time=32ns, statistics_eval_time=387.16µs, time_elapsed_opening=172.89ms, time_elapsed_processing=2.68s, time_elapsed_scanning_total=3.43s, time_elapsed_scanning_until_data=199.03ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=795MB, disk=0MB
  Hits: cache_hit=12201, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 298ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [u@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=6.65µs, output_bytes=188.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[u@2 DESC], preserve_partitioning=[true], filter=[u@2 IS NULL OR u@2 > 31], metrics=[output_rows=127, elapsed_compute=347.06µs, output_bytes=2.6 KB, output_batches=16, row_replacements=131]
    ProjectionExec: expr=[MobilePhone@0 as MobilePhone, MobilePhoneModel@1 as MobilePhoneModel, count(alias1)@2 as u], metrics=[output_rows=302, elapsed_compute=18.48µs, output_bytes=133.0 KB, output_batches=16, expr_0_eval_time=2.30µs, expr_1_eval_time=1.18µs, expr_2_eval_time=1.12µs]
      AggregateExec: mode=FinalPartitioned, gby=[MobilePhone@0 as MobilePhone, MobilePhoneModel@1 as MobilePhoneModel], aggr=[count(alias1)], metrics=[output_rows=302, elapsed_compute=307.31µs, output_bytes=133.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=344.2 K, aggregate_arguments_time=8.78µs, aggregation_time=12.74µs, emitting_time=18.18µs, time_calculating_group_ids=191.87µs]
        RepartitionExec: partitioning=Hash([MobilePhone@0, MobilePhoneModel@1], 16), input_partitions=16, metrics=[output_rows=2.61 K, elapsed_compute=359.98µs, output_bytes=1308.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=3.89s, repartition_time=715.09µs, send_time=175.19µs]
          AggregateExec: mode=Partial, gby=[MobilePhone@0 as MobilePhone, MobilePhoneModel@1 as MobilePhoneModel], aggr=[count(alias1)], metrics=[output_rows=2.61 K, elapsed_compute=36.79ms, output_bytes=178.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.34 M, aggregate_arguments_time=83.61µs, aggregation_time=2.04ms, emitting_time=22.82µs, time_calculating_group_ids=34.41ms, reduction_factor=0.22% (2.61 K/1.19 M)]
            AggregateExec: mode=FinalPartitioned, gby=[MobilePhone@0 as MobilePhone, MobilePhoneModel@1 as MobilePhoneModel, alias1@2 as alias1], aggr=[], metrics=[output_rows=1.19 M, elapsed_compute=162.33ms, output_bytes=360.0 MB, output_batches=160, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=137.4 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=37.05µs, time_calculating_group_ids=161.83ms]
              RepartitionExec: partitioning=Hash([MobilePhone@0, MobilePhoneModel@1, alias1@2], 16), input_partitions=16, metrics=[output_rows=1.37 M, elapsed_compute=7.91ms, output_bytes=24.5 MB, output_batches=176, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=2.90s, repartition_time=36.27ms, send_time=23.18ms]
                AggregateExec: mode=Partial, gby=[MobilePhone@1 as MobilePhone, MobilePhoneModel@2 as MobilePhoneModel, UserID@0 as alias1], aggr=[], metrics=[output_rows=1.37 M, elapsed_compute=391.32ms, output_bytes=419.4 MB, output_batches=177, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=67.10 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=54.57µs, time_calculating_group_ids=376.97ms, reduction_factor=25% (1.37 M/5.56 M)]
                  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, MobilePhone, MobilePhoneModel], file_type=liquid_parquet, metrics=[output_rows=5.56 M, elapsed_compute=16ns, output_bytes=97.2 MB, output_batches=12.20 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=293.7 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.75ms, metadata_load_time=2.56ms, page_index_eval_time=3.74µs, row_pushdown_eval_time=32ns, statistics_eval_time=390.73µs, time_elapsed_opening=8.49ms, time_elapsed_processing=2.31s, time_elapsed_scanning_total=2.89s, time_elapsed_scanning_until_data=43.09ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=795MB, disk=0MB
  Hits: cache_hit=12201, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 248ms
```
</details>

---

### Q12

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 743ms | 848ms | 838ms |
| Hot avg | 714ms | 806ms | 486ms |
| All iters | [743, 692, 765, 697, 702] | [848, 805, 799, 805, 817] | [838, 489, 495, 469, 492] |
| LC vs Push | | | **1.66x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 1631MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=4.91µs, output_bytes=380.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@1 DESC], preserve_partitioning=[true], filter=[c@1 IS NULL OR c@1 > 4036], metrics=[output_rows=98, elapsed_compute=14.09ms, output_bytes=4.3 KB, output_batches=16, row_replacements=269]
    ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase, count(Int64(1))@1 as c], metrics=[output_rows=6.02 M, elapsed_compute=499.93µs, output_bytes=27.4 GB, output_batches=739, expr_0_eval_time=89.51µs, expr_1_eval_time=64.72µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=6.02 M, elapsed_compute=2.45s, output_bytes=27.4 GB, output_batches=739, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.75 B, aggregate_arguments_time=1.21ms, aggregation_time=88.65ms, emitting_time=190.00µs, time_calculating_group_ids=2.36s]
        RepartitionExec: partitioning=Hash([SearchPhrase@0], 16), input_partitions=16, metrics=[output_rows=7.17 M, elapsed_compute=153.36ms, output_bytes=512.7 MB, output_batches=880, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=8.71s, repartition_time=353.12ms, send_time=400.61ms]
          AggregateExec: mode=Partial, gby=[SearchPhrase@0 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=7.17 M, elapsed_compute=3.28s, output_bytes=43.9 GB, output_batches=885, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.05 B, aggregate_arguments_time=28.56ms, aggregation_time=129.18ms, emitting_time=142.12µs, time_calculating_group_ids=3.10s, reduction_factor=54% (7.17 M/13.17 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=755.7 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=373.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.18ms, metadata_load_time=164.07ms, page_index_eval_time=2.95µs, row_pushdown_eval_time=32ns, statistics_eval_time=365.19µs, time_elapsed_opening=185.94ms, time_elapsed_processing=4.44s, time_elapsed_scanning_total=8.52s, time_elapsed_scanning_until_data=224.16ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=12142, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 838ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=6.82µs, output_bytes=380.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@1 DESC], preserve_partitioning=[true], filter=[c@1 IS NULL OR c@1 > 4036], metrics=[output_rows=95, elapsed_compute=15.47ms, output_bytes=4.1 KB, output_batches=16, row_replacements=337]
    ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase, count(Int64(1))@1 as c], metrics=[output_rows=6.02 M, elapsed_compute=747.97µs, output_bytes=27.4 GB, output_batches=739, expr_0_eval_time=73.09µs, expr_1_eval_time=63.27µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=6.02 M, elapsed_compute=2.27s, output_bytes=27.4 GB, output_batches=739, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.75 B, aggregate_arguments_time=1.23ms, aggregation_time=91.90ms, emitting_time=153.62µs, time_calculating_group_ids=2.18s]
        RepartitionExec: partitioning=Hash([SearchPhrase@0], 16), input_partitions=16, metrics=[output_rows=7.17 M, elapsed_compute=175.20ms, output_bytes=512.7 MB, output_batches=880, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=4.43s, repartition_time=390.40ms, send_time=474.55ms]
          AggregateExec: mode=Partial, gby=[SearchPhrase@0 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=7.17 M, elapsed_compute=3.09s, output_bytes=43.9 GB, output_batches=885, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.05 B, aggregate_arguments_time=26.34ms, aggregation_time=121.61ms, emitting_time=165.76µs, time_calculating_group_ids=2.92s, reduction_factor=54% (7.17 M/13.17 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=755.7 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.38ms, metadata_load_time=2.40ms, page_index_eval_time=2.86µs, row_pushdown_eval_time=32ns, statistics_eval_time=421.28µs, time_elapsed_opening=7.51ms, time_elapsed_processing=993.81ms, time_elapsed_scanning_total=4.42s, time_elapsed_scanning_until_data=1.94ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=12142, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 492ms
```
</details>

---

### Q13

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 1136ms | 1291ms | 1234ms |
| Hot avg | 1039ms | 1214ms | 1156ms |
| All iters | [1136, 1052, 1027, 1032, 1044] | [1291, 1227, 1190, 1215, 1225] | [1234, 1161, 1147, 1163, 1152] |
| LC vs Push | | | **1.05x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 1631MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [u@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=5.94µs, output_bytes=413.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[u@1 DESC], preserve_partitioning=[true], filter=[u@1 IS NULL OR u@1 > 3225], metrics=[output_rows=101, elapsed_compute=7.22ms, output_bytes=4.5 KB, output_batches=16, row_replacements=146]
    ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase, count(alias1)@1 as u], metrics=[output_rows=6.02 M, elapsed_compute=328.62µs, output_bytes=27.2 GB, output_batches=739, expr_0_eval_time=51.69µs, expr_1_eval_time=44.62µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase], aggr=[count(alias1)], metrics=[output_rows=6.02 M, elapsed_compute=3.39s, output_bytes=27.2 GB, output_batches=739, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.74 B, aggregate_arguments_time=2.01ms, aggregation_time=148.03ms, emitting_time=89.98µs, time_calculating_group_ids=3.23s]
        RepartitionExec: partitioning=Hash([SearchPhrase@0], 16), input_partitions=16, metrics=[output_rows=10.38 M, elapsed_compute=207.71ms, output_bytes=686.3 MB, output_batches=1.27 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=15.13s, repartition_time=605.24ms, send_time=1.41s]
          AggregateExec: mode=Partial, gby=[SearchPhrase@0 as SearchPhrase], aggr=[count(alias1)], metrics=[output_rows=10.38 M, elapsed_compute=611.11ms, output_bytes=75.0 GB, output_batches=1.28 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=8.98 M, peak_mem_used=217.6 M, aggregate_arguments_time=287.87µs, aggregation_time=14.27ms, emitting_time=207.28µs, time_calculating_group_ids=582.52ms, reduction_factor=82% (1.40 M/1.70 M)]
            AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase, alias1@1 as alias1], aggr=[], metrics=[output_rows=10.68 M, elapsed_compute=4.01s, output_bytes=97.4 GB, output_batches=1.31 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=3.02 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=73.69µs, time_calculating_group_ids=4.01s]
              RepartitionExec: partitioning=Hash([SearchPhrase@0, alias1@1], 16), input_partitions=16, metrics=[output_rows=12.49 M, elapsed_compute=487.46ms, output_bytes=815.3 MB, output_batches=1.54 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=6.79s, repartition_time=953.80ms, send_time=2.20s]
                AggregateExec: mode=Partial, gby=[SearchPhrase@1 as SearchPhrase, UserID@0 as alias1], aggr=[], metrics=[output_rows=12.49 M, elapsed_compute=897.58ms, output_bytes=9.7 GB, output_batches=8.45 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=9.70 M, peak_mem_used=340.1 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=142.95µs, time_calculating_group_ids=869.19ms, reduction_factor=80% (2.80 M/3.48 M)]
                  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=856.5 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=643.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.99ms, metadata_load_time=157.56ms, page_index_eval_time=2.43µs, row_pushdown_eval_time=32ns, statistics_eval_time=387.09µs, time_elapsed_opening=172.18ms, time_elapsed_processing=5.32s, time_elapsed_scanning_total=12.18s, time_elapsed_scanning_until_data=327.73ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=12142, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 1234ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [u@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=6.44µs, output_bytes=413.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[u@1 DESC], preserve_partitioning=[true], filter=[u@1 IS NULL OR u@1 > 3225], metrics=[output_rows=83, elapsed_compute=8.68ms, output_bytes=4.0 KB, output_batches=14, row_replacements=165]
    ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase, count(alias1)@1 as u], metrics=[output_rows=6.02 M, elapsed_compute=389.83µs, output_bytes=27.0 GB, output_batches=739, expr_0_eval_time=57.43µs, expr_1_eval_time=48.45µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase], aggr=[count(alias1)], metrics=[output_rows=6.02 M, elapsed_compute=3.32s, output_bytes=27.0 GB, output_batches=739, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.73 B, aggregate_arguments_time=2.20ms, aggregation_time=181.12ms, emitting_time=88.61µs, time_calculating_group_ids=3.13s]
        RepartitionExec: partitioning=Hash([SearchPhrase@0], 16), input_partitions=16, metrics=[output_rows=10.36 M, elapsed_compute=243.52ms, output_bytes=685.5 MB, output_batches=1.27 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=13.90s, repartition_time=651.34ms, send_time=1.38s]
          AggregateExec: mode=Partial, gby=[SearchPhrase@0 as SearchPhrase], aggr=[count(alias1)], metrics=[output_rows=10.36 M, elapsed_compute=493.01ms, output_bytes=75.0 GB, output_batches=1.28 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=8.98 M, peak_mem_used=217.6 M, aggregate_arguments_time=301.15µs, aggregation_time=13.36ms, emitting_time=147.77µs, time_calculating_group_ids=464.67ms, reduction_factor=81% (1.38 M/1.70 M)]
            AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase, alias1@1 as alias1], aggr=[], metrics=[output_rows=10.68 M, elapsed_compute=3.57s, output_bytes=97.4 GB, output_batches=1.31 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=3.02 B, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=56.94µs, time_calculating_group_ids=3.57s]
              RepartitionExec: partitioning=Hash([SearchPhrase@0, alias1@1], 16), input_partitions=16, metrics=[output_rows=12.49 M, elapsed_compute=489.22ms, output_bytes=815.3 MB, output_batches=1.54 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=6.23s, repartition_time=985.22ms, send_time=2.04s]
                AggregateExec: mode=Partial, gby=[SearchPhrase@1 as SearchPhrase, UserID@0 as alias1], aggr=[], metrics=[output_rows=12.49 M, elapsed_compute=707.41ms, output_bytes=9.7 GB, output_batches=8.45 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=9.70 M, peak_mem_used=340.1 M, aggregate_arguments_time=16ns, aggregation_time=16ns, emitting_time=78.92µs, time_calculating_group_ids=679.69ms, reduction_factor=80% (2.80 M/3.48 M)]
                  DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=856.5 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=679.7 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.81ms, metadata_load_time=2.49ms, page_index_eval_time=2.52µs, row_pushdown_eval_time=32ns, statistics_eval_time=406.68µs, time_elapsed_opening=8.83ms, time_elapsed_processing=5.06s, time_elapsed_scanning_total=11.57s, time_elapsed_scanning_until_data=124.82ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=12142, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 1152ms
```
</details>

---

### Q14

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 759ms | 900ms | 852ms |
| Hot avg | 707ms | 832ms | 794ms |
| All iters | [759, 696, 723, 703, 706] | [900, 823, 828, 829, 847] | [852, 795, 792, 788, 799] |
| LC vs Push | | | **1.05x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 1631MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=5.75µs, output_bytes=397.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 3147], metrics=[output_rows=113, elapsed_compute=15.34ms, output_bytes=5.6 KB, output_batches=16, row_replacements=209]
    ProjectionExec: expr=[SearchEngineID@0 as SearchEngineID, SearchPhrase@1 as SearchPhrase, count(Int64(1))@2 as c], metrics=[output_rows=6.47 M, elapsed_compute=629.55µs, output_bytes=30.5 GB, output_batches=800, expr_0_eval_time=88.51µs, expr_1_eval_time=57.36µs, expr_2_eval_time=58.09µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchEngineID@0 as SearchEngineID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=6.47 M, elapsed_compute=2.13s, output_bytes=30.5 GB, output_batches=800, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.55 B, aggregate_arguments_time=1.31ms, aggregation_time=95.77ms, emitting_time=71.70µs, time_calculating_group_ids=2.03s]
        RepartitionExec: partitioning=Hash([SearchEngineID@0, SearchPhrase@1], 16), input_partitions=16, metrics=[output_rows=7.56 M, elapsed_compute=193.92ms, output_bytes=547.3 MB, output_batches=928, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=9.03s, repartition_time=443.23ms, send_time=395.27ms]
          AggregateExec: mode=Partial, gby=[SearchEngineID@0 as SearchEngineID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=7.56 M, elapsed_compute=3.25s, output_bytes=49.8 GB, output_batches=929, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=983.2 M, aggregate_arguments_time=26.21ms, aggregation_time=134.62ms, emitting_time=139.43µs, time_calculating_group_ids=3.06s, reduction_factor=57% (7.56 M/13.17 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchEngineID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=781.2 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=391.8 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.04ms, metadata_load_time=160.83ms, page_index_eval_time=3.14µs, row_pushdown_eval_time=32ns, statistics_eval_time=361.51µs, time_elapsed_opening=182.31ms, time_elapsed_processing=4.97s, time_elapsed_scanning_total=8.84s, time_elapsed_scanning_until_data=237.35ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=12142, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 852ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=6.75µs, output_bytes=397.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 3147], metrics=[output_rows=89, elapsed_compute=15.57ms, output_bytes=4.3 KB, output_batches=15, row_replacements=143]
    ProjectionExec: expr=[SearchEngineID@0 as SearchEngineID, SearchPhrase@1 as SearchPhrase, count(Int64(1))@2 as c], metrics=[output_rows=6.47 M, elapsed_compute=730.81µs, output_bytes=30.5 GB, output_batches=800, expr_0_eval_time=83.05µs, expr_1_eval_time=61.05µs, expr_2_eval_time=60.94µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchEngineID@0 as SearchEngineID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=6.47 M, elapsed_compute=1.99s, output_bytes=30.5 GB, output_batches=800, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.55 B, aggregate_arguments_time=1.56ms, aggregation_time=112.86ms, emitting_time=74.73µs, time_calculating_group_ids=1.87s]
        RepartitionExec: partitioning=Hash([SearchEngineID@0, SearchPhrase@1], 16), input_partitions=16, metrics=[output_rows=7.56 M, elapsed_compute=187.24ms, output_bytes=547.3 MB, output_batches=928, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=8.41s, repartition_time=454.60ms, send_time=432.67ms]
          AggregateExec: mode=Partial, gby=[SearchEngineID@0 as SearchEngineID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=7.56 M, elapsed_compute=3.09s, output_bytes=49.8 GB, output_batches=929, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=983.2 M, aggregate_arguments_time=29.19ms, aggregation_time=128.94ms, emitting_time=101.29µs, time_calculating_group_ids=2.90s, reduction_factor=57% (7.56 M/13.17 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchEngineID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=781.2 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=408.5 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.30ms, metadata_load_time=2.39ms, page_index_eval_time=3.02µs, row_pushdown_eval_time=32ns, statistics_eval_time=374.34µs, time_elapsed_opening=6.77ms, time_elapsed_processing=4.72s, time_elapsed_scanning_total=8.39s, time_elapsed_scanning_until_data=90.46ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=12142, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 799ms
```
</details>

---

### Q15

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 749ms | 719ms | 765ms |
| Hot avg | 703ms | 701ms | 706ms |
| All iters | [749, 691, 727, 693, 702] | [719, 698, 706, 704, 697] | [765, 692, 709, 710, 715] |
| LC vs Push | | | **0.99x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[UserID@0 as UserID, count(*)@1 as count(*)], metrics=[output_rows=10, elapsed_compute=1.04µs, output_bytes=160.0 B, output_batches=1, expr_0_eval_time=220ns, expr_1_eval_time=140ns]
  SortPreservingMergeExec: [count(Int64(1))@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=4.88µs, output_bytes=240.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 1983], metrics=[output_rows=131, elapsed_compute=46.81ms, output_bytes=3.1 KB, output_batches=16, row_replacements=427]
      ProjectionExec: expr=[UserID@0 as UserID, count(Int64(1))@1 as count(*), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=17.63 M, elapsed_compute=2.16ms, output_bytes=67.5 GB, output_batches=2.16 K, expr_0_eval_time=316.74µs, expr_1_eval_time=241.65µs, expr_2_eval_time=162.51µs]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID], aggr=[count(Int64(1))], metrics=[output_rows=17.63 M, elapsed_compute=3.90s, output_bytes=67.5 GB, output_batches=2.16 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=2.01 B, aggregate_arguments_time=1.97ms, aggregation_time=308.48ms, emitting_time=5.03ms, time_calculating_group_ids=3.58s]
          RepartitionExec: partitioning=Hash([UserID@0], 16), input_partitions=16, metrics=[output_rows=21.16 M, elapsed_compute=75.98ms, output_bytes=324.0 MB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=6.73s, repartition_time=317.29ms, send_time=904.80ms]
            AggregateExec: mode=Partial, gby=[UserID@0 as UserID], aggr=[count(Int64(1))], metrics=[output_rows=21.16 M, elapsed_compute=5.35s, output_bytes=82.6 GB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=982.2 M, aggregate_arguments_time=50.74ms, aggregation_time=256.46ms, emitting_time=3.08ms, time_calculating_group_ids=5.02s, reduction_factor=21% (21.16 M/100.00 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=764.8 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=270.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=154.61ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=168.78ms, time_elapsed_processing=686.03ms, time_elapsed_scanning_total=6.55s, time_elapsed_scanning_until_data=144.16ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 765ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[UserID@0 as UserID, count(*)@1 as count(*)], metrics=[output_rows=10, elapsed_compute=1.01µs, output_bytes=160.0 B, output_batches=1, expr_0_eval_time=150ns, expr_1_eval_time=150ns]
  SortPreservingMergeExec: [count(Int64(1))@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=5.13µs, output_bytes=240.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@1 DESC], preserve_partitioning=[true], filter=[count(*)@1 IS NULL OR count(*)@1 > 1983], metrics=[output_rows=132, elapsed_compute=44.66ms, output_bytes=3.1 KB, output_batches=16, row_replacements=352]
      ProjectionExec: expr=[UserID@0 as UserID, count(Int64(1))@1 as count(*), count(Int64(1))@1 as count(Int64(1))], metrics=[output_rows=17.63 M, elapsed_compute=1.95ms, output_bytes=67.5 GB, output_batches=2.16 K, expr_0_eval_time=262.04µs, expr_1_eval_time=207.34µs, expr_2_eval_time=152.11µs]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID], aggr=[count(Int64(1))], metrics=[output_rows=17.63 M, elapsed_compute=3.73s, output_bytes=67.5 GB, output_batches=2.16 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=2.01 B, aggregate_arguments_time=2.21ms, aggregation_time=313.00ms, emitting_time=5.22ms, time_calculating_group_ids=3.41s]
          RepartitionExec: partitioning=Hash([UserID@0], 16), input_partitions=16, metrics=[output_rows=21.16 M, elapsed_compute=83.91ms, output_bytes=324.0 MB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=6.20s, repartition_time=328.64ms, send_time=892.39ms]
            AggregateExec: mode=Partial, gby=[UserID@0 as UserID], aggr=[count(Int64(1))], metrics=[output_rows=21.16 M, elapsed_compute=4.99s, output_bytes=82.6 GB, output_batches=2.59 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=982.2 M, aggregate_arguments_time=54.49ms, aggregation_time=240.66ms, emitting_time=2.33ms, time_calculating_group_ids=4.67s, reduction_factor=21% (21.16 M/100.00 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=764.8 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=270.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=1.94ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=2.65ms, time_elapsed_processing=676.06ms, time_elapsed_scanning_total=6.19s, time_elapsed_scanning_until_data=57.99ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 715ms
```
</details>

---

### Q16

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 1519ms | 1514ms | 1605ms |
| Hot avg | 1473ms | 1467ms | 1572ms |
| All iters | [1519, 1462, 1481, 1462, 1487] | [1514, 1457, 1472, 1455, 1483] | [1605, 1579, 1567, 1579, 1561] |
| LC vs Push | | | **0.93x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase, count(*)@2 as count(*)], metrics=[output_rows=10, elapsed_compute=1.61µs, output_bytes=204.0 B, output_batches=1, expr_0_eval_time=170ns, expr_1_eval_time=60ns, expr_2_eval_time=160ns]
  SortPreservingMergeExec: [count(Int64(1))@3 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=7.35µs, output_bytes=284.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@2 DESC], preserve_partitioning=[true], filter=[count(*)@2 IS NULL OR count(*)@2 > 1980], metrics=[output_rows=126, elapsed_compute=56.22ms, output_bytes=3.5 KB, output_batches=16, row_replacements=381]
      ProjectionExec: expr=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase, count(Int64(1))@2 as count(*), count(Int64(1))@2 as count(Int64(1))], metrics=[output_rows=24.07 M, elapsed_compute=3.11ms, output_bytes=299.1 GB, output_batches=2.94 K, expr_0_eval_time=507.89µs, expr_1_eval_time=285.92µs, expr_2_eval_time=322.28µs, expr_3_eval_time=261.95µs]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=24.07 M, elapsed_compute=7.37s, output_bytes=299.1 GB, output_batches=2.94 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=4.43 B, aggregate_arguments_time=4.33ms, aggregation_time=372.24ms, emitting_time=69.56µs, time_calculating_group_ids=6.99s]
          RepartitionExec: partitioning=Hash([UserID@0, SearchPhrase@1], 16), input_partitions=16, metrics=[output_rows=26.36 M, elapsed_compute=430.70ms, output_bytes=1091.1 MB, output_batches=3.23 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=15.31s, repartition_time=1.41s, send_time=2.61s]
            AggregateExec: mode=Partial, gby=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=26.36 M, elapsed_compute=9.76s, output_bytes=317.4 GB, output_batches=3.22 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.22 B, aggregate_arguments_time=76.31ms, aggregation_time=279.62ms, emitting_time=139.81µs, time_calculating_group_ids=9.37s, reduction_factor=26% (26.36 M/100.00 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=2.3 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=643.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=169.50ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=187.48ms, time_elapsed_processing=4.26s, time_elapsed_scanning_total=15.11s, time_elapsed_scanning_until_data=310.21ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 1605ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase, count(*)@2 as count(*)], metrics=[output_rows=10, elapsed_compute=1.80µs, output_bytes=204.0 B, output_batches=1, expr_0_eval_time=290ns, expr_1_eval_time=60ns, expr_2_eval_time=150ns]
  SortPreservingMergeExec: [count(Int64(1))@3 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=7.38µs, output_bytes=284.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@2 DESC], preserve_partitioning=[true], filter=[count(*)@2 IS NULL OR count(*)@2 > 1980], metrics=[output_rows=128, elapsed_compute=52.21ms, output_bytes=3.6 KB, output_batches=16, row_replacements=390]
      ProjectionExec: expr=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase, count(Int64(1))@2 as count(*), count(Int64(1))@2 as count(Int64(1))], metrics=[output_rows=24.07 M, elapsed_compute=3.18ms, output_bytes=299.1 GB, output_batches=2.94 K, expr_0_eval_time=447.94µs, expr_1_eval_time=298.80µs, expr_2_eval_time=300.15µs, expr_3_eval_time=249.27µs]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=24.07 M, elapsed_compute=7.33s, output_bytes=299.1 GB, output_batches=2.94 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=4.43 B, aggregate_arguments_time=5.28ms, aggregation_time=390.97ms, emitting_time=79.72µs, time_calculating_group_ids=6.93s]
          RepartitionExec: partitioning=Hash([UserID@0, SearchPhrase@1], 16), input_partitions=16, metrics=[output_rows=26.36 M, elapsed_compute=407.54ms, output_bytes=1091.1 MB, output_batches=3.23 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=14.83s, repartition_time=1.45s, send_time=2.65s]
            AggregateExec: mode=Partial, gby=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=26.36 M, elapsed_compute=9.51s, output_bytes=317.4 GB, output_batches=3.22 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.22 B, aggregate_arguments_time=88.68ms, aggregation_time=298.48ms, emitting_time=133.68µs, time_calculating_group_ids=9.09s, reduction_factor=26% (26.36 M/100.00 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=2.3 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=643.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=2.11ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=2.99ms, time_elapsed_processing=4.11s, time_elapsed_scanning_total=14.81s, time_elapsed_scanning_until_data=189.20ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 1561ms
```
</details>

---

### Q17

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 1494ms | 1504ms | 1594ms |
| Hot avg | 1455ms | 1460ms | 1554ms |
| All iters | [1494, 1452, 1458, 1452, 1458] | [1504, 1458, 1458, 1473, 1449] | [1594, 1560, 1570, 1546, 1540] |
| LC vs Push | | | **0.94x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase, count(Int64(1))@2 as count(*)], metrics=[output_rows=10, elapsed_compute=6.12µs, output_bytes=104.0 MB, output_batches=1, expr_0_eval_time=869ns, expr_1_eval_time=180ns, expr_2_eval_time=350ns]
  CoalescePartitionsExec: fetch=10, metrics=[output_rows=10, elapsed_compute=18.16µs, output_bytes=104.0 MB, output_batches=1]
    AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=196.6 K, elapsed_compute=7.12s, output_bytes=2.4 GB, output_batches=24, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=4.43 B, aggregate_arguments_time=4.52ms, aggregation_time=343.99ms, emitting_time=22.43µs, time_calculating_group_ids=6.76s]
      RepartitionExec: partitioning=Hash([UserID@0, SearchPhrase@1], 16), input_partitions=16, metrics=[output_rows=26.36 M, elapsed_compute=464.25ms, output_bytes=1091.1 MB, output_batches=3.23 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=15.06s, repartition_time=1.42s, send_time=2.83s]
        AggregateExec: mode=Partial, gby=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=26.36 M, elapsed_compute=9.70s, output_bytes=317.4 GB, output_batches=3.22 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.22 B, aggregate_arguments_time=74.31ms, aggregation_time=308.16ms, emitting_time=193.61µs, time_calculating_group_ids=9.29s, reduction_factor=26% (26.36 M/100.00 M)]
          DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=2.3 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=643.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=155.37ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=156.23ms, time_elapsed_processing=4.10s, time_elapsed_scanning_total=14.88s, time_elapsed_scanning_until_data=300.95ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 1594ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase, count(Int64(1))@2 as count(*)], metrics=[output_rows=10, elapsed_compute=5.04µs, output_bytes=104.0 MB, output_batches=1, expr_0_eval_time=1.12µs, expr_1_eval_time=180ns, expr_2_eval_time=200ns]
  CoalescePartitionsExec: fetch=10, metrics=[output_rows=10, elapsed_compute=13.64µs, output_bytes=104.0 MB, output_batches=1]
    AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=180.2 K, elapsed_compute=7.30s, output_bytes=2.2 GB, output_batches=22, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=4.43 B, aggregate_arguments_time=5.04ms, aggregation_time=432.05ms, emitting_time=13.47µs, time_calculating_group_ids=6.85s]
      RepartitionExec: partitioning=Hash([UserID@0, SearchPhrase@1], 16), input_partitions=16, metrics=[output_rows=26.36 M, elapsed_compute=418.24ms, output_bytes=1090.4 MB, output_batches=3.22 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=14.65s, repartition_time=1.38s, send_time=2.32s]
        AggregateExec: mode=Partial, gby=[UserID@0 as UserID, SearchPhrase@1 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=26.36 M, elapsed_compute=9.46s, output_bytes=317.4 GB, output_batches=3.22 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.22 B, aggregate_arguments_time=92.16ms, aggregation_time=276.61ms, emitting_time=127.59µs, time_calculating_group_ids=9.05s, reduction_factor=26% (26.36 M/100.00 M)]
          DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=2.3 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=643.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=2.08ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=2.76ms, time_elapsed_processing=4.15s, time_elapsed_scanning_total=14.62s, time_elapsed_scanning_until_data=164.40ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 1540ms
```
</details>

---

### Q18

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 4071ms | 4378ms | 3461ms |
| Hot avg | 3192ms | 3286ms | 3135ms |
| All iters | [4071, 3667, 3130, 3061, 2912] | [4378, 3943, 3198, 2955, 3049] | [3461, 3595, 3094, 2904, 2948] |
| LC vs Push | | | **1.05x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[UserID@0 as UserID, m@1 as m, SearchPhrase@2 as SearchPhrase, count(*)@3 as count(*)], metrics=[output_rows=10, elapsed_compute=2.19µs, output_bytes=244.0 B, output_batches=1, expr_0_eval_time=330ns, expr_1_eval_time=160ns, expr_2_eval_time=150ns, expr_3_eval_time=150ns]
  SortPreservingMergeExec: [count(Int64(1))@4 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=18.49µs, output_bytes=324.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@3 DESC], preserve_partitioning=[true], filter=[count(*)@3 IS NULL OR count(*)@3 > 434], metrics=[output_rows=155, elapsed_compute=130.97ms, output_bytes=4.9 KB, output_batches=16, row_replacements=537]
      ProjectionExec: expr=[UserID@0 as UserID, date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime))@1 as m, SearchPhrase@2 as SearchPhrase, count(Int64(1))@3 as count(*), count(Int64(1))@3 as count(Int64(1))], metrics=[output_rows=56.38 M, elapsed_compute=9.39ms, output_bytes=1077.3 GB, output_batches=6.89 K, expr_0_eval_time=867.09µs, expr_1_eval_time=612.86µs, expr_2_eval_time=588.77µs, expr_3_eval_time=669.61µs, expr_4_eval_time=540.32µs]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID, date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime))@1 as date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime)), SearchPhrase@2 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=56.38 M, elapsed_compute=23.39s, output_bytes=1077.3 GB, output_batches=6.89 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=7.25 B, aggregate_arguments_time=10.36ms, aggregation_time=1.49s, emitting_time=135.27µs, time_calculating_group_ids=21.86s]
          RepartitionExec: partitioning=Hash([UserID@0, date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime))@1, SearchPhrase@2], 16), input_partitions=16, metrics=[output_rows=62.58 M, elapsed_compute=974.82ms, output_bytes=2.1 GB, output_batches=7.65 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=24.58s, repartition_time=3.32s, send_time=5.24s]
            AggregateExec: mode=Partial, gby=[UserID@1 as UserID, date_part(MINUTE, to_timestamp_seconds(EventTime@0)) as date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime)), SearchPhrase@2 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=62.58 M, elapsed_compute=17.13s, output_bytes=1034.4 GB, output_batches=7.65 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=14.13 M, peak_mem_used=3.63 B, aggregate_arguments_time=80.41ms, aggregation_time=463.52ms, emitting_time=148.63µs, time_calculating_group_ids=15.00s, reduction_factor=56% (48.45 M/85.87 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[EventTime, UserID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=3.1 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=1.05 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=157.65ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=167.38ms, time_elapsed_processing=6.27s, time_elapsed_scanning_total=29.73s, time_elapsed_scanning_until_data=439.83ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 3461ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[UserID@0 as UserID, m@1 as m, SearchPhrase@2 as SearchPhrase, count(*)@3 as count(*)], metrics=[output_rows=10, elapsed_compute=2.13µs, output_bytes=244.0 B, output_batches=1, expr_0_eval_time=260ns, expr_1_eval_time=160ns, expr_2_eval_time=160ns, expr_3_eval_time=160ns]
  SortPreservingMergeExec: [count(Int64(1))@4 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=11.06µs, output_bytes=324.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[count(*)@3 DESC], preserve_partitioning=[true], filter=[count(*)@3 IS NULL OR count(*)@3 > 434], metrics=[output_rows=160, elapsed_compute=135.31ms, output_bytes=5.1 KB, output_batches=16, row_replacements=439]
      ProjectionExec: expr=[UserID@0 as UserID, date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime))@1 as m, SearchPhrase@2 as SearchPhrase, count(Int64(1))@3 as count(*), count(Int64(1))@3 as count(Int64(1))], metrics=[output_rows=56.38 M, elapsed_compute=9.46ms, output_bytes=1077.3 GB, output_batches=6.89 K, expr_0_eval_time=778.86µs, expr_1_eval_time=599.98µs, expr_2_eval_time=515.59µs, expr_3_eval_time=646.14µs, expr_4_eval_time=512.26µs]
        AggregateExec: mode=FinalPartitioned, gby=[UserID@0 as UserID, date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime))@1 as date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime)), SearchPhrase@2 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=56.38 M, elapsed_compute=16.28s, output_bytes=1077.3 GB, output_batches=6.89 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=7.25 B, aggregate_arguments_time=13.49ms, aggregation_time=823.95ms, emitting_time=97.76µs, time_calculating_group_ids=15.42s]
          RepartitionExec: partitioning=Hash([UserID@0, date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime))@1, SearchPhrase@2], 16), input_partitions=16, metrics=[output_rows=62.58 M, elapsed_compute=1.07s, output_bytes=2.1 GB, output_batches=7.65 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=24.04s, repartition_time=3.08s, send_time=5.41s]
            AggregateExec: mode=Partial, gby=[UserID@1 as UserID, date_part(MINUTE, to_timestamp_seconds(EventTime@0)) as date_part(Utf8("MINUTE"),to_timestamp_seconds(hits.EventTime)), SearchPhrase@2 as SearchPhrase], aggr=[count(Int64(1))], metrics=[output_rows=62.58 M, elapsed_compute=17.05s, output_bytes=1034.4 GB, output_batches=7.65 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=14.13 M, peak_mem_used=3.63 B, aggregate_arguments_time=149.15ms, aggregation_time=397.90ms, emitting_time=99.92µs, time_calculating_group_ids=14.88s, reduction_factor=56% (48.45 M/85.87 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[EventTime, UserID, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=3.1 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=1.05 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=2.07ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=3.39ms, time_elapsed_processing=5.98s, time_elapsed_scanning_total=28.96s, time_elapsed_scanning_until_data=228.26ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 2948ms
```
</details>

---

### Q19

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 93ms | 125ms | 168ms |
| Hot avg | 60ms | 85ms | 20ms |
| All iters | [93, 60, 56, 58, 64] | [125, 88, 86, 85, 81] | [168, 20, 20, 21, 20] |
| LC vs Push | | | **4.20x** |

**Cache Stats (after last iteration):**
- Entries: 10668 | Memory: 668MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID], file_type=liquid_parquet, metrics=[output_rows=4, elapsed_compute=16ns, output_bytes=64.0 B, output_batches=1, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 202 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=231.7 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.89ms, metadata_load_time=227.13ms, page_index_eval_time=3.03µs, row_pushdown_eval_time=32ns, statistics_eval_time=435.48µs, time_elapsed_opening=245.83ms, time_elapsed_processing=1.80s, time_elapsed_scanning_total=2.06s, time_elapsed_scanning_until_data=2.02s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=10668, mem=668MB, disk=0MB
  Hits: cache_hit=1, eval_predicate=21336
  Misses: cache_miss=10668
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 168ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[UserID], file_type=liquid_parquet, metrics=[output_rows=4, elapsed_compute=16ns, output_bytes=64.0 B, output_batches=1, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 202 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.96ms, metadata_load_time=1.77ms, page_index_eval_time=3.23µs, row_pushdown_eval_time=32ns, statistics_eval_time=275.61µs, time_elapsed_opening=5.46ms, time_elapsed_processing=260.63ms, time_elapsed_scanning_total=255.23ms, time_elapsed_scanning_until_data=248.35ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=10668, mem=668MB, disk=0MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

---

### Q20

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 1039ms | 1009ms | 24350ms |
| Hot avg | 1028ms | 1022ms | 15314ms |
| All iters | [1039, 1029, 1012, 1037, 1036] | [1009, 1031, 1001, 1023, 1032] | [24350, 14676, 15526, 15526, 15527] |
| LC vs Push | | | **0.07x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 2047MB | Disk: 1928MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.77µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=420ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=51.92µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=25.05µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=12.42ms, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=liquid_parquet, metrics=[output_rows=15.91 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=3.12 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=2.65 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=158.27ms, page_index_eval_time=2.52µs, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=167.37ms, time_elapsed_processing=48.21s, time_elapsed_scanning_total=225.15s, time_elapsed_scanning_until_data=1.22s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=2047MB, disk=1928MB
  Hits: cache_hit=0, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=7604
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 24350ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[count(Int64(1))@0 as count(*)], metrics=[output_rows=1, elapsed_compute=1.81µs, output_bytes=8.0 B, output_batches=1, expr_0_eval_time=450ns]
  AggregateExec: mode=Final, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=1, elapsed_compute=35.72µs, output_bytes=8.0 B, output_batches=1]
    CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=14.50µs, output_bytes=128.0 B, output_batches=16]
      AggregateExec: mode=Partial, gby=[], aggr=[count(Int64(1))], metrics=[output_rows=16, elapsed_compute=2.96ms, output_bytes=128.0 B, output_batches=16]
        DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, file_type=liquid_parquet, metrics=[output_rows=15.91 K, elapsed_compute=16ns, output_bytes=0.0 B, output_batches=3.12 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=1.86ms, page_index_eval_time=2.40µs, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=2.93ms, time_elapsed_processing=3.46s, time_elapsed_scanning_total=196.42s, time_elapsed_scanning_until_data=12.54s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=2047MB, disk=1928MB
  Hits: cache_hit=0, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=7579, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=7579
Time: 15527ms
```
</details>

---

### Q21

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 1296ms | 1350ms | 40999ms |
| Hot avg | 1263ms | 1278ms | 18077ms |
| All iters | [1296, 1239, 1269, 1260, 1283] | [1350, 1277, 1250, 1285, 1298] | [40999, 17351, 18321, 18319, 18318] |
| LC vs Push | | | **0.07x** |

**Cache Stats (after last iteration):**
- Entries: 24436 | Memory: 2047MB | Disk: 2455MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=7.39µs, output_bytes=1367.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 2], metrics=[output_rows=80, elapsed_compute=452.64µs, output_bytes=13.8 KB, output_batches=15, row_replacements=99]
    ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase, min(hits.URL)@1 as min(hits.URL), count(Int64(1))@2 as c], metrics=[output_rows=677, elapsed_compute=23.54µs, output_bytes=211.3 KB, output_batches=16, expr_0_eval_time=3.10µs, expr_1_eval_time=1.14µs, expr_2_eval_time=1.57µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase], aggr=[min(hits.URL), count(Int64(1))], metrics=[output_rows=677, elapsed_compute=1.13ms, output_bytes=211.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=487.6 K, aggregate_arguments_time=17.84µs, aggregation_time=319.56µs, emitting_time=76.68µs, time_calculating_group_ids=112.84µs]
        RepartitionExec: partitioning=Hash([SearchPhrase@0], 16), input_partitions=16, metrics=[output_rows=729, elapsed_compute=912.44µs, output_bytes=1157.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=384.62s, repartition_time=500.76µs, send_time=277.41µs]
          AggregateExec: mode=Partial, gby=[SearchPhrase@1 as SearchPhrase], aggr=[min(hits.URL), count(Int64(1))], metrics=[output_rows=729, elapsed_compute=16.34ms, output_bytes=228.1 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=255.3 K, aggregate_arguments_time=2.14ms, aggregation_time=10.42ms, emitting_time=187.71µs, time_calculating_group_ids=3.24ms, reduction_factor=70% (729/1.04 K)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=1.04 K, elapsed_compute=16ns, output_bytes=178.4 KB, output_batches=577, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=3.03 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=1.04 K, pushdown_rows_pruned=13.17 M, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.38ms, metadata_load_time=158.68ms, page_index_eval_time=3.10µs, row_pushdown_eval_time=326.63ms, statistics_eval_time=471.57µs, time_elapsed_opening=181.37ms, time_elapsed_processing=54.95s, time_elapsed_scanning_total=384.44s, time_elapsed_scanning_until_data=5.31s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=24436, mem=2047MB, disk=2455MB
  Hits: cache_hit=13296, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=17368
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 40999ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=8.27µs, output_bytes=1367.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 2], metrics=[output_rows=70, elapsed_compute=348.06µs, output_bytes=11.6 KB, output_batches=15, row_replacements=88]
    ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase, min(hits.URL)@1 as min(hits.URL), count(Int64(1))@2 as c], metrics=[output_rows=677, elapsed_compute=23.12µs, output_bytes=211.3 KB, output_batches=16, expr_0_eval_time=2.96µs, expr_1_eval_time=1.41µs, expr_2_eval_time=1.36µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase], aggr=[min(hits.URL), count(Int64(1))], metrics=[output_rows=677, elapsed_compute=440.88µs, output_bytes=211.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=487.6 K, aggregate_arguments_time=18.54µs, aggregation_time=235.10µs, emitting_time=66.23µs, time_calculating_group_ids=110.29µs]
        RepartitionExec: partitioning=Hash([SearchPhrase@0], 16), input_partitions=16, metrics=[output_rows=729, elapsed_compute=722.18µs, output_bytes=1157.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=238.25s, repartition_time=316.06µs, send_time=253.78µs]
          AggregateExec: mode=Partial, gby=[SearchPhrase@1 as SearchPhrase], aggr=[min(hits.URL), count(Int64(1))], metrics=[output_rows=729, elapsed_compute=3.94ms, output_bytes=228.1 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=255.3 K, aggregate_arguments_time=648.13µs, aggregation_time=2.22ms, emitting_time=117.30µs, time_calculating_group_ids=691.50µs, reduction_factor=70% (729/1.04 K)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=1.04 K, elapsed_compute=16ns, output_bytes=178.4 KB, output_batches=577, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=1.04 K, pushdown_rows_pruned=13.17 M, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=3.15ms, metadata_load_time=2.51ms, page_index_eval_time=3.50µs, row_pushdown_eval_time=230.89ms, statistics_eval_time=576.63µs, time_elapsed_opening=8.59ms, time_elapsed_processing=1.96s, time_elapsed_scanning_total=238.24s, time_elapsed_scanning_until_data=59.04s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=24436, mem=2047MB, disk=2455MB
  Hits: cache_hit=13296, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=9411, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=9411
Time: 18318ms
```
</details>

---

### Q22

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 3164ms | 2834ms | 75665ms |
| Hot avg | 2998ms | 2878ms | 31785ms |
| All iters | [3164, 2974, 2987, 3036, 2996] | [2834, 2847, 2863, 2863, 2940] | [75665, 31425, 31887, 31924, 31904] |
| LC vs Push | | | **0.09x** |

**Cache Stats (after last iteration):**
- Entries: 36654 | Memory: 2047MB | Disk: 4975MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@3 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=12.46µs, output_bytes=3.2 KB, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@3 DESC], preserve_partitioning=[true], filter=[c@3 IS NULL OR c@3 > 5], metrics=[output_rows=117, elapsed_compute=474.51µs, output_bytes=40.7 KB, output_batches=16, row_replacements=131]
    ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase, min(hits.URL)@1 as min(hits.URL), min(hits.Title)@2 as min(hits.Title), count(Int64(1))@3 as c, count(DISTINCT hits.UserID)@4 as count(DISTINCT hits.UserID)], metrics=[output_rows=3.67 K, elapsed_compute=36.55µs, output_bytes=1245.1 KB, output_batches=16, expr_0_eval_time=5.58µs, expr_1_eval_time=1.32µs, expr_2_eval_time=1.29µs, expr_3_eval_time=1.31µs, expr_4_eval_time=1.41µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase], aggr=[min(hits.URL), min(hits.Title), count(Int64(1)), count(DISTINCT hits.UserID)], metrics=[output_rows=3.67 K, elapsed_compute=8.27ms, output_bytes=1245.1 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=4.93 M, aggregate_arguments_time=33.85µs, aggregation_time=9.69ms, emitting_time=779.57µs, time_calculating_group_ids=561.88µs]
        RepartitionExec: partitioning=Hash([SearchPhrase@0], 16), input_partitions=16, metrics=[output_rows=4.08 K, elapsed_compute=2.37ms, output_bytes=2.3 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=933.88s, repartition_time=1.30ms, send_time=281.64µs]
          AggregateExec: mode=Partial, gby=[SearchPhrase@3 as SearchPhrase], aggr=[min(hits.URL), min(hits.Title), count(Int64(1)), count(DISTINCT hits.UserID)], metrics=[output_rows=4.08 K, elapsed_compute=103.30ms, output_bytes=1451.5 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.75 M, aggregate_arguments_time=9.27ms, aggregation_time=124.22ms, emitting_time=4.54ms, time_calculating_group_ids=11.16ms, reduction_factor=57% (4.08 K/7.13 K)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[Title, UserID, URL, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=7.13 K, elapsed_compute=16ns, output_bytes=2.3 MB, output_batches=2.81 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=5.73 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=14.26 K, pushdown_rows_pruned=13.17 M, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.78ms, metadata_load_time=157.15ms, page_index_eval_time=2.72µs, row_pushdown_eval_time=352.01ms, statistics_eval_time=623.29µs, time_elapsed_opening=191.70ms, time_elapsed_processing=94.76s, time_elapsed_scanning_total=933.68s, time_elapsed_scanning_until_data=6.47s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=36654, mem=2047MB, disk=4975MB
  Hits: cache_hit=23366, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=31308
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 75665ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@3 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=9.81µs, output_bytes=3.2 KB, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@3 DESC], preserve_partitioning=[true], filter=[c@3 IS NULL OR c@3 > 5], metrics=[output_rows=100, elapsed_compute=466.09µs, output_bytes=34.0 KB, output_batches=16, row_replacements=115]
    ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase, min(hits.URL)@1 as min(hits.URL), min(hits.Title)@2 as min(hits.Title), count(Int64(1))@3 as c, count(DISTINCT hits.UserID)@4 as count(DISTINCT hits.UserID)], metrics=[output_rows=3.67 K, elapsed_compute=36.55µs, output_bytes=1245.1 KB, output_batches=16, expr_0_eval_time=5.10µs, expr_1_eval_time=1.70µs, expr_2_eval_time=1.38µs, expr_3_eval_time=1.37µs, expr_4_eval_time=1.29µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchPhrase@0 as SearchPhrase], aggr=[min(hits.URL), min(hits.Title), count(Int64(1)), count(DISTINCT hits.UserID)], metrics=[output_rows=3.67 K, elapsed_compute=9.18ms, output_bytes=1245.1 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=4.93 M, aggregate_arguments_time=40.66µs, aggregation_time=12.26ms, emitting_time=1.17ms, time_calculating_group_ids=560.73µs]
        RepartitionExec: partitioning=Hash([SearchPhrase@0], 16), input_partitions=16, metrics=[output_rows=4.08 K, elapsed_compute=2.16ms, output_bytes=2.3 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=419.58s, repartition_time=1.36ms, send_time=331.43µs]
          AggregateExec: mode=Partial, gby=[SearchPhrase@3 as SearchPhrase], aggr=[min(hits.URL), min(hits.Title), count(Int64(1)), count(DISTINCT hits.UserID)], metrics=[output_rows=4.08 K, elapsed_compute=72.36ms, output_bytes=1451.5 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.75 M, aggregate_arguments_time=8.27ms, aggregation_time=81.20ms, emitting_time=4.86ms, time_calculating_group_ids=7.26ms, reduction_factor=57% (4.08 K/7.13 K)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[Title, UserID, URL, SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=7.13 K, elapsed_compute=16ns, output_bytes=2.3 MB, output_batches=2.81 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=32.51 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=14.26 K, pushdown_rows_pruned=13.17 M, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=3.56ms, metadata_load_time=2.89ms, page_index_eval_time=2.83µs, row_pushdown_eval_time=315.70ms, statistics_eval_time=689.44µs, time_elapsed_opening=9.84ms, time_elapsed_processing=18.77s, time_elapsed_scanning_total=419.56s, time_elapsed_scanning_until_data=10.37s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=36654, mem=2047MB, disk=4975MB
  Hits: cache_hit=23366, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=19697, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=19697
Time: 31904ms
```
</details>

---

### Q23

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 9778ms | 4160ms | 54590ms |
| Hot avg | 9633ms | 1547ms | 16684ms |
| All iters | [9778, 9668, 9614, 9652, 9597] | [4160, 1608, 1536, 1529, 1514] | [54590, 15987, 16907, 16925, 16917] |
| LC vs Push | | | **0.09x** |

**Cache Stats (after last iteration):**
- Entries: 24436 | Memory: 2047MB | Disk: 2223MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [to_timestamp_seconds(EventTime@4) ASC NULLS LAST], fetch=10, metrics=[output_rows=10, elapsed_compute=131.53µs, output_bytes=6.0 KB, output_batches=1]
  SortExec: TopK(fetch=10), expr=[to_timestamp_seconds(EventTime@4) ASC NULLS LAST], preserve_partitioning=[true], filter=[to_timestamp_seconds(EventTime@4) < 1372720043], metrics=[output_rows=79, elapsed_compute=10.71ms, output_bytes=59.1 KB, output_batches=11, row_replacements=140]
    DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[WatchID, JavaEnable, Title, GoodEvent, EventTime, EventDate, CounterID, ClientIP, RegionID, UserID, CounterClass, OS, UserAgent, URL, Referer, IsRefresh, RefererCategoryID, RefererRegionID, URLCategoryID, URLRegionID, ResolutionWidth, ResolutionHeight, ResolutionDepth, FlashMajor, FlashMinor, FlashMinor2, NetMajor, NetMinor, UserAgentMajor, UserAgentMinor, CookieEnable, JavascriptEnable, IsMobile, MobilePhone, MobilePhoneModel, Params, IPNetworkID, TraficSourceID, SearchEngineID, SearchPhrase, AdvEngineID, IsArtifical, WindowClientWidth, WindowClientHeight, ClientTimeZone, ClientEventTime, SilverlightVersion1, SilverlightVersion2, SilverlightVersion3, SilverlightVersion4, PageCharset, CodeVersion, IsLink, IsDownload, IsNotBounce, FUniqID, OriginalURL, HID, IsOldCounter, IsEvent, IsParameter, DontCountHits, WithHash, HitColor, LocalEventTime, Age, Sex, Income, Interests, Robotness, RemoteIP, WindowName, OpenerName, HistoryLength, BrowserLanguage, BrowserCountry, SocialNetwork, SocialAction, HTTPError, SendTiming, DNSTiming, ConnectTiming, ResponseStartTiming, ResponseEndTiming, FetchTiming, SocialSourceNetworkID, SocialSourcePage, ParamPrice, ParamOrderID, ParamCurrency, ParamCurrencyID, OpenstatServiceName, OpenstatCampaignID, OpenstatAdID, OpenstatSourceID, UTMSource, UTMMedium, UTMCampaign, UTMContent, UTMTerm, FromTag, HasGCLID, RefererHash, URLHash, CLID], file_type=liquid_parquet, metrics=[output_rows=167, elapsed_compute=16ns, output_bytes=474.3 KB, output_batches=79, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=14.78 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=30, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=162.02ms, page_index_eval_time=2.53µs, row_pushdown_eval_time=71.23µs, statistics_eval_time=32ns, time_elapsed_opening=203.83ms, time_elapsed_processing=109.39s, time_elapsed_scanning_total=518.34s, time_elapsed_scanning_until_data=216.07s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=24436, mem=2047MB, disk=2223MB
  Hits: cache_hit=162, eval_predicate=27557
  Misses: cache_miss=12218
  IO: read=0, write=16611
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 54590ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [to_timestamp_seconds(EventTime@4) ASC NULLS LAST], fetch=10, metrics=[output_rows=10, elapsed_compute=109.21µs, output_bytes=6.0 KB, output_batches=1]
  SortExec: TopK(fetch=10), expr=[to_timestamp_seconds(EventTime@4) ASC NULLS LAST], preserve_partitioning=[true], filter=[to_timestamp_seconds(EventTime@4) < 1372720043], metrics=[output_rows=96, elapsed_compute=8.17ms, output_bytes=84.3 KB, output_batches=14, row_replacements=154]
    DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[WatchID, JavaEnable, Title, GoodEvent, EventTime, EventDate, CounterID, ClientIP, RegionID, UserID, CounterClass, OS, UserAgent, URL, Referer, IsRefresh, RefererCategoryID, RefererRegionID, URLCategoryID, URLRegionID, ResolutionWidth, ResolutionHeight, ResolutionDepth, FlashMajor, FlashMinor, FlashMinor2, NetMajor, NetMinor, UserAgentMajor, UserAgentMinor, CookieEnable, JavascriptEnable, IsMobile, MobilePhone, MobilePhoneModel, Params, IPNetworkID, TraficSourceID, SearchEngineID, SearchPhrase, AdvEngineID, IsArtifical, WindowClientWidth, WindowClientHeight, ClientTimeZone, ClientEventTime, SilverlightVersion1, SilverlightVersion2, SilverlightVersion3, SilverlightVersion4, PageCharset, CodeVersion, IsLink, IsDownload, IsNotBounce, FUniqID, OriginalURL, HID, IsOldCounter, IsEvent, IsParameter, DontCountHits, WithHash, HitColor, LocalEventTime, Age, Sex, Income, Interests, Robotness, RemoteIP, WindowName, OpenerName, HistoryLength, BrowserLanguage, BrowserCountry, SocialNetwork, SocialAction, HTTPError, SendTiming, DNSTiming, ConnectTiming, ResponseStartTiming, ResponseEndTiming, FetchTiming, SocialSourceNetworkID, SocialSourcePage, ParamPrice, ParamOrderID, ParamCurrency, ParamCurrencyID, OpenstatServiceName, OpenstatCampaignID, OpenstatAdID, OpenstatSourceID, UTMSource, UTMMedium, UTMCampaign, UTMContent, UTMTerm, FromTag, HasGCLID, RefererHash, URLHash, CLID], file_type=liquid_parquet, metrics=[output_rows=193, elapsed_compute=16ns, output_bytes=559.2 KB, output_batches=90, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=4.55 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=32, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=4.97ms, page_index_eval_time=2.79µs, row_pushdown_eval_time=134.38µs, statistics_eval_time=32ns, time_elapsed_opening=10.28ms, time_elapsed_processing=6.22s, time_elapsed_scanning_total=220.31s, time_elapsed_scanning_until_data=23.24s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=24436, mem=2047MB, disk=2223MB
  Hits: cache_hit=192, eval_predicate=15331
  Misses: cache_miss=0
  IO: read=8432, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=8432
Time: 16917ms
```
</details>

---

### Q24

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 431ms | 497ms | 808ms |
| Hot avg | 397ms | 446ms | 61ms |
| All iters | [431, 394, 406, 381, 408] | [497, 446, 451, 435, 453] | [808, 56, 60, 65, 62] |
| LC vs Push | | | **7.35x** |

**Cache Stats (after last iteration):**
- Entries: 24436 | Memory: 2047MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase], metrics=[output_rows=10, elapsed_compute=2.74µs, output_bytes=491.0 B, output_batches=1, expr_0_eval_time=420ns]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC NULLS LAST], fetch=10, metrics=[output_rows=10, elapsed_compute=9.44µs, output_bytes=571.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[to_timestamp_seconds(EventTime@1) ASC NULLS LAST], preserve_partitioning=[true], filter=[to_timestamp_seconds(EventTime@1) < 1372708804], metrics=[output_rows=83, elapsed_compute=6.50ms, output_bytes=5.4 KB, output_batches=11, row_replacements=343]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase, EventTime], file_type=liquid_parquet, metrics=[output_rows=1.65 K, elapsed_compute=16ns, output_bytes=113.9 KB, output_batches=104, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=776.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=38, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.13ms, metadata_load_time=160.23ms, page_index_eval_time=2.86µs, row_pushdown_eval_time=6.11µs, statistics_eval_time=429.22µs, time_elapsed_opening=178.99ms, time_elapsed_processing=8.60s, time_elapsed_scanning_total=9.07s, time_elapsed_scanning_until_data=3.82s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=24436, mem=2047MB, disk=0MB
  Hits: cache_hit=209, eval_predicate=36577
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 808ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase], metrics=[output_rows=10, elapsed_compute=1.20µs, output_bytes=491.0 B, output_batches=1, expr_0_eval_time=251ns]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC NULLS LAST], fetch=10, metrics=[output_rows=10, elapsed_compute=6.38µs, output_bytes=571.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[to_timestamp_seconds(EventTime@1) ASC NULLS LAST], preserve_partitioning=[true], filter=[to_timestamp_seconds(EventTime@1) < 1372708804], metrics=[output_rows=60, elapsed_compute=800.85µs, output_bytes=4.2 KB, output_batches=10, row_replacements=260]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase, EventTime], file_type=liquid_parquet, metrics=[output_rows=2.36 K, elapsed_compute=16ns, output_bytes=165.7 KB, output_batches=93, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=1.63 K, pushdown_rows_pruned=483, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.44ms, metadata_load_time=2.27ms, page_index_eval_time=3.66µs, row_pushdown_eval_time=19.20µs, statistics_eval_time=436.64µs, time_elapsed_opening=26.28ms, time_elapsed_processing=678.90ms, time_elapsed_scanning_total=653.46ms, time_elapsed_scanning_until_data=290.25ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=24436, mem=2047MB, disk=0MB
  Hits: cache_hit=189, eval_predicate=24357
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 62ms
```
</details>

---

### Q25

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 346ms | 438ms | 425ms |
| Hot avg | 306ms | 387ms | 86ms |
| All iters | [346, 308, 307, 302, 307] | [438, 389, 386, 377, 395] | [425, 92, 84, 87, 83] |
| LC vs Push | | | **4.47x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 1631MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [SearchPhrase@0 ASC NULLS LAST], fetch=10, metrics=[output_rows=10, elapsed_compute=9.14µs, output_bytes=404.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[SearchPhrase@0 ASC NULLS LAST], preserve_partitioning=[true], filter=[SearchPhrase@0 < $_posten of greenjera mi 300 мегафонов (1944-105 отзывы], metrics=[output_rows=134, elapsed_compute=3.38ms, output_bytes=5.0 KB, output_batches=16, row_replacements=370]
    DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=1.18 K, elapsed_compute=16ns, output_bytes=52.9 KB, output_batches=163, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=373.1 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.11ms, metadata_load_time=239.16ms, page_index_eval_time=2.81µs, row_pushdown_eval_time=32ns, statistics_eval_time=385.01µs, time_elapsed_opening=257.76ms, time_elapsed_processing=4.91s, time_elapsed_scanning_total=5.15s, time_elapsed_scanning_until_data=309.07ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=163, eval_predicate=36578
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 425ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [SearchPhrase@0 ASC NULLS LAST], fetch=10, metrics=[output_rows=10, elapsed_compute=8.43µs, output_bytes=404.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[SearchPhrase@0 ASC NULLS LAST], preserve_partitioning=[true], filter=[SearchPhrase@0 < $_posten of greenjera mi 300 мегафонов (1944-105 отзывы], metrics=[output_rows=127, elapsed_compute=846.36µs, output_bytes=5.2 KB, output_batches=15, row_replacements=272]
    DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase], file_type=liquid_parquet, metrics=[output_rows=1.09 K, elapsed_compute=16ns, output_bytes=63.8 KB, output_batches=145, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.53ms, metadata_load_time=2.32ms, page_index_eval_time=3.25µs, row_pushdown_eval_time=32ns, statistics_eval_time=394.24µs, time_elapsed_opening=27.12ms, time_elapsed_processing=980.59ms, time_elapsed_scanning_total=954.40ms, time_elapsed_scanning_until_data=79.73ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=145, eval_predicate=24360
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 83ms
```
</details>

---

### Q26

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 444ms | 615ms | 833ms |
| Hot avg | 386ms | 536ms | 97ms |
| All iters | [444, 380, 387, 390, 387] | [615, 528, 543, 528, 543] | [833, 93, 101, 100, 95] |
| LC vs Push | | | **5.51x** |

**Cache Stats (after last iteration):**
- Entries: 24436 | Memory: 2047MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase], metrics=[output_rows=10, elapsed_compute=2.54µs, output_bytes=494.0 B, output_batches=1, expr_0_eval_time=880ns]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC NULLS LAST, SearchPhrase@0 ASC NULLS LAST], fetch=10, metrics=[output_rows=10, elapsed_compute=13.65µs, output_bytes=574.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[to_timestamp_seconds(EventTime@1) ASC NULLS LAST, SearchPhrase@0 ASC NULLS LAST], preserve_partitioning=[true], filter=[to_timestamp_seconds(EventTime@1) < 1372708804 OR to_timestamp_seconds(EventTime@1) = 1372708804 AND SearchPhrase@0 < венгридический якутии видео ни], metrics=[output_rows=94, elapsed_compute=5.40ms, output_bytes=6.1 KB, output_batches=13, row_replacements=446]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase, EventTime], file_type=liquid_parquet, metrics=[output_rows=3.05 K, elapsed_compute=16ns, output_bytes=195.6 KB, output_batches=107, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=776.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=3.05 K, pushdown_rows_pruned=13.17 M, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.10ms, metadata_load_time=234.84ms, page_index_eval_time=2.97µs, row_pushdown_eval_time=193.41ms, statistics_eval_time=387.60µs, time_elapsed_opening=266.03ms, time_elapsed_processing=8.89s, time_elapsed_scanning_total=9.39s, time_elapsed_scanning_until_data=3.76s, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=24436, mem=2047MB, disk=0MB
  Hits: cache_hit=24498, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 833ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
ProjectionExec: expr=[SearchPhrase@0 as SearchPhrase], metrics=[output_rows=10, elapsed_compute=1.19µs, output_bytes=494.0 B, output_batches=1, expr_0_eval_time=230ns]
  SortPreservingMergeExec: [to_timestamp_seconds(EventTime@1) ASC NULLS LAST, SearchPhrase@0 ASC NULLS LAST], fetch=10, metrics=[output_rows=10, elapsed_compute=8.16µs, output_bytes=574.0 B, output_batches=1]
    SortExec: TopK(fetch=10), expr=[to_timestamp_seconds(EventTime@1) ASC NULLS LAST, SearchPhrase@0 ASC NULLS LAST], preserve_partitioning=[true], filter=[to_timestamp_seconds(EventTime@1) < 1372708804 OR to_timestamp_seconds(EventTime@1) = 1372708804 AND SearchPhrase@0 < венгридический якутии видео ни], metrics=[output_rows=112, elapsed_compute=1.58ms, output_bytes=7.5 KB, output_batches=13, row_replacements=483]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[SearchPhrase, EventTime], file_type=liquid_parquet, metrics=[output_rows=2.93 K, elapsed_compute=16ns, output_bytes=182.5 KB, output_batches=112, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=2.93 K, pushdown_rows_pruned=13.17 M, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.53ms, metadata_load_time=2.48ms, page_index_eval_time=4.11µs, row_pushdown_eval_time=109.33ms, statistics_eval_time=448.46µs, time_elapsed_opening=7.65ms, time_elapsed_processing=1.21s, time_elapsed_scanning_total=1.21s, time_elapsed_scanning_until_data=348.89ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=24436, mem=2047MB, disk=0MB
  Hits: cache_hit=24508, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 95ms
```
</details>

---

### Q27

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 1283ms | 1537ms | 22253ms |
| Hot avg | 1240ms | 1484ms | 13412ms |
| All iters | [1283, 1268, 1241, 1216, 1234] | [1537, 1475, 1486, 1492, 1484] | [22253, 13151, 13498, 13495, 13506] |
| LC vs Push | | | **0.11x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 2047MB | Disk: 1675MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [l@1 DESC], fetch=25, metrics=[output_rows=25, elapsed_compute=7.17µs, output_bytes=500.0 B, output_batches=1]
  SortExec: TopK(fetch=25), expr=[l@1 DESC], preserve_partitioning=[true], metrics=[output_rows=100, elapsed_compute=383.90µs, output_bytes=2000.0 B, output_batches=16, row_replacements=100]
    ProjectionExec: expr=[CounterID@0 as CounterID, avg(length(hits.URL))@1 as l, count(Int64(1))@2 as c], metrics=[output_rows=100, elapsed_compute=23.50µs, output_bytes=2.5 MB, output_batches=16, expr_0_eval_time=3.18µs, expr_1_eval_time=1.52µs, expr_2_eval_time=1.12µs]
      FilterExec: count(Int64(1))@2 > 100000, metrics=[output_rows=100, elapsed_compute=242.44µs, output_bytes=2.5 MB, output_batches=16, selectivity=1.5% (100/6.49 K)]
        AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID], aggr=[avg(length(hits.URL)), count(Int64(1))], metrics=[output_rows=6.49 K, elapsed_compute=1.23ms, output_bytes=133.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=569.0 K, aggregate_arguments_time=27.31µs, aggregation_time=206.75µs, emitting_time=75.13µs, time_calculating_group_ids=244.63µs]
          RepartitionExec: partitioning=Hash([CounterID@0], 16), input_partitions=16, metrics=[output_rows=6.72 K, elapsed_compute=807.07µs, output_bytes=3.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=199.44s, repartition_time=822.54µs, send_time=368.00µs]
            AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID], aggr=[avg(length(hits.URL)), count(Int64(1))], metrics=[output_rows=6.72 K, elapsed_compute=4.26s, output_bytes=266.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.40 M, aggregate_arguments_time=3.03s, aggregation_time=809.18ms, emitting_time=156.04µs, time_calculating_group_ids=744.19ms, reduction_factor=0.0067% (6.72 K/99.93 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CounterID, URL], file_type=liquid_parquet, metrics=[output_rows=99.93 M, elapsed_compute=16ns, output_bytes=10.7 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=2.65 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.98ms, metadata_load_time=158.03ms, page_index_eval_time=3.30µs, row_pushdown_eval_time=32ns, statistics_eval_time=377.05µs, time_elapsed_opening=193.79ms, time_elapsed_processing=45.94s, time_elapsed_scanning_total=199.25s, time_elapsed_scanning_until_data=552.94ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=2047MB, disk=1675MB
  Hits: cache_hit=12218, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=7019
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 22253ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [l@1 DESC], fetch=25, metrics=[output_rows=25, elapsed_compute=7.98µs, output_bytes=500.0 B, output_batches=1]
  SortExec: TopK(fetch=25), expr=[l@1 DESC], preserve_partitioning=[true], metrics=[output_rows=100, elapsed_compute=207.02µs, output_bytes=2000.0 B, output_batches=16, row_replacements=100]
    ProjectionExec: expr=[CounterID@0 as CounterID, avg(length(hits.URL))@1 as l, count(Int64(1))@2 as c], metrics=[output_rows=100, elapsed_compute=21.89µs, output_bytes=2.5 MB, output_batches=16, expr_0_eval_time=2.50µs, expr_1_eval_time=1.23µs, expr_2_eval_time=1.32µs]
      FilterExec: count(Int64(1))@2 > 100000, metrics=[output_rows=100, elapsed_compute=178.13µs, output_bytes=2.5 MB, output_batches=16, selectivity=1.5% (100/6.49 K)]
        AggregateExec: mode=FinalPartitioned, gby=[CounterID@0 as CounterID], aggr=[avg(length(hits.URL)), count(Int64(1))], metrics=[output_rows=6.49 K, elapsed_compute=487.17µs, output_bytes=133.3 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=569.0 K, aggregate_arguments_time=20.04µs, aggregation_time=106.95µs, emitting_time=41.43µs, time_calculating_group_ids=230.41µs]
          RepartitionExec: partitioning=Hash([CounterID@0], 16), input_partitions=16, metrics=[output_rows=6.72 K, elapsed_compute=754.00µs, output_bytes=3.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=169.87s, repartition_time=783.34µs, send_time=377.00µs]
            AggregateExec: mode=Partial, gby=[CounterID@0 as CounterID], aggr=[avg(length(hits.URL)), count(Int64(1))], metrics=[output_rows=6.72 K, elapsed_compute=3.26s, output_bytes=266.6 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.40 M, aggregate_arguments_time=2.31s, aggregation_time=756.91ms, emitting_time=100.59µs, time_calculating_group_ids=523.39ms, reduction_factor=0.0067% (6.72 K/99.93 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CounterID, URL], file_type=liquid_parquet, metrics=[output_rows=99.93 M, elapsed_compute=16ns, output_bytes=9.2 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=2.65 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.52ms, metadata_load_time=2.60ms, page_index_eval_time=3.49µs, row_pushdown_eval_time=32ns, statistics_eval_time=425.85µs, time_elapsed_opening=7.68ms, time_elapsed_processing=12.42s, time_elapsed_scanning_total=169.86s, time_elapsed_scanning_until_data=373.62ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=2047MB, disk=1675MB
  Hits: cache_hit=12218, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=7019, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=7019
Time: 13506ms
```
</details>

---

### Q28

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 8900ms | 9041ms | 18124ms |
| Hot avg | 8974ms | 9152ms | 10664ms |
| All iters | [8900, 9013, 8859, 8874, 9149] | [9041, 9060, 9222, 9131, 9193] | [18124, 10679, 10722, 10865, 10388] |
| LC vs Push | | | **0.86x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 2045MB | Disk: 614MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [l@1 DESC], fetch=25, metrics=[output_rows=25, elapsed_compute=15.45µs, output_bytes=3.0 KB, output_batches=1]
  SortExec: TopK(fetch=25), expr=[l@1 DESC], preserve_partitioning=[true], metrics=[output_rows=77, elapsed_compute=455.90µs, output_bytes=6.7 KB, output_batches=16, row_replacements=77]
    ProjectionExec: expr=[regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))@0 as k, avg(length(hits.Referer))@1 as l, count(Int64(1))@2 as c, min(hits.Referer)@3 as min(hits.Referer)], metrics=[output_rows=77, elapsed_compute=119.75µs, output_bytes=2.0 MB, output_batches=16, expr_0_eval_time=5.05µs, expr_1_eval_time=1.94µs, expr_2_eval_time=1.52µs, expr_3_eval_time=79.83µs]
      FilterExec: count(Int64(1))@2 > 100000, metrics=[output_rows=77, elapsed_compute=5.50ms, output_bytes=2.0 MB, output_batches=16, selectivity=0.0026% (77/3.01 M)]
        AggregateExec: mode=FinalPartitioned, gby=[regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))@0 as regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))], aggr=[avg(length(hits.Referer)), count(Int64(1)), min(hits.Referer)], metrics=[output_rows=3.01 M, elapsed_compute=3.42s, output_bytes=24.2 GB, output_batches=373, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=2.59 B, aggregate_arguments_time=1.49ms, aggregation_time=1.45s, emitting_time=781.29ms, time_calculating_group_ids=1.39s]
          RepartitionExec: partitioning=Hash([regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))@0], 16), input_partitions=16, metrics=[output_rows=3.66 M, elapsed_compute=398.93ms, output_bytes=975.9 MB, output_batches=448, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=218.86s, repartition_time=410.43ms, send_time=66.81ms]
            AggregateExec: mode=Partial, gby=[regexp_replace(Referer@0, ^https?://(?:www\\.)?([^/]+)/.*$, \\1) as regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))], aggr=[avg(length(hits.Referer)), count(Int64(1)), min(hits.Referer)], metrics=[output_rows=3.66 M, elapsed_compute=108.89s, output_bytes=35.0 GB, output_batches=454, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.45 B, aggregate_arguments_time=2.60s, aggregation_time=4.33s, emitting_time=342.44ms, time_calculating_group_ids=3.46s, reduction_factor=4.5% (3.66 M/81.03 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[Referer], file_type=liquid_parquet, metrics=[output_rows=81.03 M, elapsed_compute=16ns, output_bytes=6.5 GB, output_batches=12.21 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=2.25 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.06ms, metadata_load_time=157.58ms, page_index_eval_time=2.59µs, row_pushdown_eval_time=32ns, statistics_eval_time=384.40µs, time_elapsed_opening=181.66ms, time_elapsed_processing=35.40s, time_elapsed_scanning_total=218.33s, time_elapsed_scanning_until_data=448.94ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=2045MB, disk=614MB
  Hits: cache_hit=12211, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=3280
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18124ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [l@1 DESC], fetch=25, metrics=[output_rows=25, elapsed_compute=17.35µs, output_bytes=3.0 KB, output_batches=1]
  SortExec: TopK(fetch=25), expr=[l@1 DESC], preserve_partitioning=[true], metrics=[output_rows=77, elapsed_compute=659.76µs, output_bytes=6.7 KB, output_batches=16, row_replacements=77]
    ProjectionExec: expr=[regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))@0 as k, avg(length(hits.Referer))@1 as l, count(Int64(1))@2 as c, min(hits.Referer)@3 as min(hits.Referer)], metrics=[output_rows=77, elapsed_compute=41.33µs, output_bytes=2.0 MB, output_batches=16, expr_0_eval_time=4.20µs, expr_1_eval_time=1.95µs, expr_2_eval_time=1.32µs, expr_3_eval_time=4.30µs]
      FilterExec: count(Int64(1))@2 > 100000, metrics=[output_rows=77, elapsed_compute=5.83ms, output_bytes=2.0 MB, output_batches=16, selectivity=0.0026% (77/3.01 M)]
        AggregateExec: mode=FinalPartitioned, gby=[regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))@0 as regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))], aggr=[avg(length(hits.Referer)), count(Int64(1)), min(hits.Referer)], metrics=[output_rows=3.01 M, elapsed_compute=2.89s, output_bytes=24.2 GB, output_batches=373, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=2.59 B, aggregate_arguments_time=1.39ms, aggregation_time=1.18s, emitting_time=769.33ms, time_calculating_group_ids=1.11s]
          RepartitionExec: partitioning=Hash([regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))@0], 16), input_partitions=16, metrics=[output_rows=3.66 M, elapsed_compute=279.69ms, output_bytes=975.9 MB, output_batches=448, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=145.39s, repartition_time=412.99ms, send_time=219.63ms]
            AggregateExec: mode=Partial, gby=[regexp_replace(Referer@0, ^https?://(?:www\\.)?([^/]+)/.*$, \\1) as regexp_replace(hits.Referer,Utf8("^https?://(?:www\\.)?([^/]+)/.*$"),Utf8("\\1"))], aggr=[avg(length(hits.Referer)), count(Int64(1)), min(hits.Referer)], metrics=[output_rows=3.66 M, elapsed_compute=104.77s, output_bytes=35.0 GB, output_batches=454, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.45 B, aggregate_arguments_time=2.59s, aggregation_time=4.23s, emitting_time=331.12ms, time_calculating_group_ids=3.52s, reduction_factor=4.5% (3.66 M/81.03 M)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[Referer], file_type=liquid_parquet, metrics=[output_rows=81.03 M, elapsed_compute=16ns, output_bytes=6.5 GB, output_batches=12.21 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=3.41ms, metadata_load_time=2.68ms, page_index_eval_time=3.40µs, row_pushdown_eval_time=32ns, statistics_eval_time=394.18µs, time_elapsed_opening=8.86ms, time_elapsed_processing=5.00s, time_elapsed_scanning_total=145.04s, time_elapsed_scanning_until_data=37.02ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=2045MB, disk=614MB
  Hits: cache_hit=12211, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=3280, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=3280
Time: 10388ms
```
</details>

---

### Q29

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 398ms | 380ms | 435ms |
| Hot avg | 377ms | 378ms | 392ms |
| All iters | [398, 379, 384, 380, 365] | [380, 391, 393, 363, 366] | [435, 388, 393, 390, 396] |
| LC vs Push | | | **0.97x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
AggregateExec: mode=Final, gby=[], aggr=[sum(hits.ResolutionWidth), sum(hits.ResolutionWidth + Int64(1)), sum(hits.ResolutionWidth + Int64(2)), sum(hits.ResolutionWidth + Int64(3)), sum(hits.ResolutionWidth + Int64(4)), sum(hits.ResolutionWidth + Int64(5)), sum(hits.ResolutionWidth + Int64(6)), sum(hits.ResolutionWidth + Int64(7)), sum(hits.ResolutionWidth + Int64(8)), sum(hits.ResolutionWidth + Int64(9)), sum(hits.ResolutionWidth + Int64(10)), sum(hits.ResolutionWidth + Int64(11)), sum(hits.ResolutionWidth + Int64(12)), sum(hits.ResolutionWidth + Int64(13)), sum(hits.ResolutionWidth + Int64(14)), sum(hits.ResolutionWidth + Int64(15)), sum(hits.ResolutionWidth + Int64(16)), sum(hits.ResolutionWidth + Int64(17)), sum(hits.ResolutionWidth + Int64(18)), sum(hits.ResolutionWidth + Int64(19)), sum(hits.ResolutionWidth + Int64(20)), sum(hits.ResolutionWidth + Int64(21)), sum(hits.ResolutionWidth + Int64(22)), sum(hits.ResolutionWidth + Int64(23)), sum(hits.ResolutionWidth + Int64(24)), sum(hits.ResolutionWidth + Int64(25)), sum(hits.ResolutionWidth + Int64(26)), sum(hits.ResolutionWidth + Int64(27)), sum(hits.ResolutionWidth + Int64(28)), sum(hits.ResolutionWidth + Int64(29)), sum(hits.ResolutionWidth + Int64(30)), sum(hits.ResolutionWidth + Int64(31)), sum(hits.ResolutionWidth + Int64(32)), sum(hits.ResolutionWidth + Int64(33)), sum(hits.ResolutionWidth + Int64(34)), sum(hits.ResolutionWidth + Int64(35)), sum(hits.ResolutionWidth + Int64(36)), sum(hits.ResolutionWidth + Int64(37)), sum(hits.ResolutionWidth + Int64(38)), sum(hits.ResolutionWidth + Int64(39)), sum(hits.ResolutionWidth + Int64(40)), sum(hits.ResolutionWidth + Int64(41)), sum(hits.ResolutionWidth + Int64(42)), sum(hits.ResolutionWidth + Int64(43)), sum(hits.ResolutionWidth + Int64(44)), sum(hits.ResolutionWidth + Int64(45)), sum(hits.ResolutionWidth + Int64(46)), sum(hits.ResolutionWidth + Int64(47)), sum(hits.ResolutionWidth + Int64(48)), sum(hits.ResolutionWidth + Int64(49)), sum(hits.ResolutionWidth + Int64(50)), sum(hits.ResolutionWidth + Int64(51)), sum(hits.ResolutionWidth + Int64(52)), sum(hits.ResolutionWidth + Int64(53)), sum(hits.ResolutionWidth + Int64(54)), sum(hits.ResolutionWidth + Int64(55)), sum(hits.ResolutionWidth + Int64(56)), sum(hits.ResolutionWidth + Int64(57)), sum(hits.ResolutionWidth + Int64(58)), sum(hits.ResolutionWidth + Int64(59)), sum(hits.ResolutionWidth + Int64(60)), sum(hits.ResolutionWidth + Int64(61)), sum(hits.ResolutionWidth + Int64(62)), sum(hits.ResolutionWidth + Int64(63)), sum(hits.ResolutionWidth + Int64(64)), sum(hits.ResolutionWidth + Int64(65)), sum(hits.ResolutionWidth + Int64(66)), sum(hits.ResolutionWidth + Int64(67)), sum(hits.ResolutionWidth + Int64(68)), sum(hits.ResolutionWidth + Int64(69)), sum(hits.ResolutionWidth + Int64(70)), sum(hits.ResolutionWidth + Int64(71)), sum(hits.ResolutionWidth + Int64(72)), sum(hits.ResolutionWidth + Int64(73)), sum(hits.ResolutionWidth + Int64(74)), sum(hits.ResolutionWidth + Int64(75)), sum(hits.ResolutionWidth + Int64(76)), sum(hits.ResolutionWidth + Int64(77)), sum(hits.ResolutionWidth + Int64(78)), sum(hits.ResolutionWidth + Int64(79)), sum(hits.ResolutionWidth + Int64(80)), sum(hits.ResolutionWidth + Int64(81)), sum(hits.ResolutionWidth + Int64(82)), sum(hits.ResolutionWidth + Int64(83)), sum(hits.ResolutionWidth + Int64(84)), sum(hits.ResolutionWidth + Int64(85)), sum(hits.ResolutionWidth + Int64(86)), sum(hits.ResolutionWidth + Int64(87)), sum(hits.ResolutionWidth + Int64(88)), sum(hits.ResolutionWidth + Int64(89))], metrics=[output_rows=1, elapsed_compute=270.41µs, output_bytes=720.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=21.79µs, output_bytes=11.2 KB, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[sum(hits.ResolutionWidth), sum(hits.ResolutionWidth + Int64(1)), sum(hits.ResolutionWidth + Int64(2)), sum(hits.ResolutionWidth + Int64(3)), sum(hits.ResolutionWidth + Int64(4)), sum(hits.ResolutionWidth + Int64(5)), sum(hits.ResolutionWidth + Int64(6)), sum(hits.ResolutionWidth + Int64(7)), sum(hits.ResolutionWidth + Int64(8)), sum(hits.ResolutionWidth + Int64(9)), sum(hits.ResolutionWidth + Int64(10)), sum(hits.ResolutionWidth + Int64(11)), sum(hits.ResolutionWidth + Int64(12)), sum(hits.ResolutionWidth + Int64(13)), sum(hits.ResolutionWidth + Int64(14)), sum(hits.ResolutionWidth + Int64(15)), sum(hits.ResolutionWidth + Int64(16)), sum(hits.ResolutionWidth + Int64(17)), sum(hits.ResolutionWidth + Int64(18)), sum(hits.ResolutionWidth + Int64(19)), sum(hits.ResolutionWidth + Int64(20)), sum(hits.ResolutionWidth + Int64(21)), sum(hits.ResolutionWidth + Int64(22)), sum(hits.ResolutionWidth + Int64(23)), sum(hits.ResolutionWidth + Int64(24)), sum(hits.ResolutionWidth + Int64(25)), sum(hits.ResolutionWidth + Int64(26)), sum(hits.ResolutionWidth + Int64(27)), sum(hits.ResolutionWidth + Int64(28)), sum(hits.ResolutionWidth + Int64(29)), sum(hits.ResolutionWidth + Int64(30)), sum(hits.ResolutionWidth + Int64(31)), sum(hits.ResolutionWidth + Int64(32)), sum(hits.ResolutionWidth + Int64(33)), sum(hits.ResolutionWidth + Int64(34)), sum(hits.ResolutionWidth + Int64(35)), sum(hits.ResolutionWidth + Int64(36)), sum(hits.ResolutionWidth + Int64(37)), sum(hits.ResolutionWidth + Int64(38)), sum(hits.ResolutionWidth + Int64(39)), sum(hits.ResolutionWidth + Int64(40)), sum(hits.ResolutionWidth + Int64(41)), sum(hits.ResolutionWidth + Int64(42)), sum(hits.ResolutionWidth + Int64(43)), sum(hits.ResolutionWidth + Int64(44)), sum(hits.ResolutionWidth + Int64(45)), sum(hits.ResolutionWidth + Int64(46)), sum(hits.ResolutionWidth + Int64(47)), sum(hits.ResolutionWidth + Int64(48)), sum(hits.ResolutionWidth + Int64(49)), sum(hits.ResolutionWidth + Int64(50)), sum(hits.ResolutionWidth + Int64(51)), sum(hits.ResolutionWidth + Int64(52)), sum(hits.ResolutionWidth + Int64(53)), sum(hits.ResolutionWidth + Int64(54)), sum(hits.ResolutionWidth + Int64(55)), sum(hits.ResolutionWidth + Int64(56)), sum(hits.ResolutionWidth + Int64(57)), sum(hits.ResolutionWidth + Int64(58)), sum(hits.ResolutionWidth + Int64(59)), sum(hits.ResolutionWidth + Int64(60)), sum(hits.ResolutionWidth + Int64(61)), sum(hits.ResolutionWidth + Int64(62)), sum(hits.ResolutionWidth + Int64(63)), sum(hits.ResolutionWidth + Int64(64)), sum(hits.ResolutionWidth + Int64(65)), sum(hits.ResolutionWidth + Int64(66)), sum(hits.ResolutionWidth + Int64(67)), sum(hits.ResolutionWidth + Int64(68)), sum(hits.ResolutionWidth + Int64(69)), sum(hits.ResolutionWidth + Int64(70)), sum(hits.ResolutionWidth + Int64(71)), sum(hits.ResolutionWidth + Int64(72)), sum(hits.ResolutionWidth + Int64(73)), sum(hits.ResolutionWidth + Int64(74)), sum(hits.ResolutionWidth + Int64(75)), sum(hits.ResolutionWidth + Int64(76)), sum(hits.ResolutionWidth + Int64(77)), sum(hits.ResolutionWidth + Int64(78)), sum(hits.ResolutionWidth + Int64(79)), sum(hits.ResolutionWidth + Int64(80)), sum(hits.ResolutionWidth + Int64(81)), sum(hits.ResolutionWidth + Int64(82)), sum(hits.ResolutionWidth + Int64(83)), sum(hits.ResolutionWidth + Int64(84)), sum(hits.ResolutionWidth + Int64(85)), sum(hits.ResolutionWidth + Int64(86)), sum(hits.ResolutionWidth + Int64(87)), sum(hits.ResolutionWidth + Int64(88)), sum(hits.ResolutionWidth + Int64(89))], metrics=[output_rows=16, elapsed_compute=4.25s, output_bytes=11.2 KB, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CAST(ResolutionWidth@20 AS Int64) as __common_expr_1], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=762.9 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=41.07 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=154.19ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=157.26ms, time_elapsed_processing=559.08ms, time_elapsed_scanning_total=5.11s, time_elapsed_scanning_until_data=104.53ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 435ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
AggregateExec: mode=Final, gby=[], aggr=[sum(hits.ResolutionWidth), sum(hits.ResolutionWidth + Int64(1)), sum(hits.ResolutionWidth + Int64(2)), sum(hits.ResolutionWidth + Int64(3)), sum(hits.ResolutionWidth + Int64(4)), sum(hits.ResolutionWidth + Int64(5)), sum(hits.ResolutionWidth + Int64(6)), sum(hits.ResolutionWidth + Int64(7)), sum(hits.ResolutionWidth + Int64(8)), sum(hits.ResolutionWidth + Int64(9)), sum(hits.ResolutionWidth + Int64(10)), sum(hits.ResolutionWidth + Int64(11)), sum(hits.ResolutionWidth + Int64(12)), sum(hits.ResolutionWidth + Int64(13)), sum(hits.ResolutionWidth + Int64(14)), sum(hits.ResolutionWidth + Int64(15)), sum(hits.ResolutionWidth + Int64(16)), sum(hits.ResolutionWidth + Int64(17)), sum(hits.ResolutionWidth + Int64(18)), sum(hits.ResolutionWidth + Int64(19)), sum(hits.ResolutionWidth + Int64(20)), sum(hits.ResolutionWidth + Int64(21)), sum(hits.ResolutionWidth + Int64(22)), sum(hits.ResolutionWidth + Int64(23)), sum(hits.ResolutionWidth + Int64(24)), sum(hits.ResolutionWidth + Int64(25)), sum(hits.ResolutionWidth + Int64(26)), sum(hits.ResolutionWidth + Int64(27)), sum(hits.ResolutionWidth + Int64(28)), sum(hits.ResolutionWidth + Int64(29)), sum(hits.ResolutionWidth + Int64(30)), sum(hits.ResolutionWidth + Int64(31)), sum(hits.ResolutionWidth + Int64(32)), sum(hits.ResolutionWidth + Int64(33)), sum(hits.ResolutionWidth + Int64(34)), sum(hits.ResolutionWidth + Int64(35)), sum(hits.ResolutionWidth + Int64(36)), sum(hits.ResolutionWidth + Int64(37)), sum(hits.ResolutionWidth + Int64(38)), sum(hits.ResolutionWidth + Int64(39)), sum(hits.ResolutionWidth + Int64(40)), sum(hits.ResolutionWidth + Int64(41)), sum(hits.ResolutionWidth + Int64(42)), sum(hits.ResolutionWidth + Int64(43)), sum(hits.ResolutionWidth + Int64(44)), sum(hits.ResolutionWidth + Int64(45)), sum(hits.ResolutionWidth + Int64(46)), sum(hits.ResolutionWidth + Int64(47)), sum(hits.ResolutionWidth + Int64(48)), sum(hits.ResolutionWidth + Int64(49)), sum(hits.ResolutionWidth + Int64(50)), sum(hits.ResolutionWidth + Int64(51)), sum(hits.ResolutionWidth + Int64(52)), sum(hits.ResolutionWidth + Int64(53)), sum(hits.ResolutionWidth + Int64(54)), sum(hits.ResolutionWidth + Int64(55)), sum(hits.ResolutionWidth + Int64(56)), sum(hits.ResolutionWidth + Int64(57)), sum(hits.ResolutionWidth + Int64(58)), sum(hits.ResolutionWidth + Int64(59)), sum(hits.ResolutionWidth + Int64(60)), sum(hits.ResolutionWidth + Int64(61)), sum(hits.ResolutionWidth + Int64(62)), sum(hits.ResolutionWidth + Int64(63)), sum(hits.ResolutionWidth + Int64(64)), sum(hits.ResolutionWidth + Int64(65)), sum(hits.ResolutionWidth + Int64(66)), sum(hits.ResolutionWidth + Int64(67)), sum(hits.ResolutionWidth + Int64(68)), sum(hits.ResolutionWidth + Int64(69)), sum(hits.ResolutionWidth + Int64(70)), sum(hits.ResolutionWidth + Int64(71)), sum(hits.ResolutionWidth + Int64(72)), sum(hits.ResolutionWidth + Int64(73)), sum(hits.ResolutionWidth + Int64(74)), sum(hits.ResolutionWidth + Int64(75)), sum(hits.ResolutionWidth + Int64(76)), sum(hits.ResolutionWidth + Int64(77)), sum(hits.ResolutionWidth + Int64(78)), sum(hits.ResolutionWidth + Int64(79)), sum(hits.ResolutionWidth + Int64(80)), sum(hits.ResolutionWidth + Int64(81)), sum(hits.ResolutionWidth + Int64(82)), sum(hits.ResolutionWidth + Int64(83)), sum(hits.ResolutionWidth + Int64(84)), sum(hits.ResolutionWidth + Int64(85)), sum(hits.ResolutionWidth + Int64(86)), sum(hits.ResolutionWidth + Int64(87)), sum(hits.ResolutionWidth + Int64(88)), sum(hits.ResolutionWidth + Int64(89))], metrics=[output_rows=1, elapsed_compute=316.49µs, output_bytes=720.0 B, output_batches=1]
  CoalescePartitionsExec, metrics=[output_rows=16, elapsed_compute=13.82µs, output_bytes=11.2 KB, output_batches=16]
    AggregateExec: mode=Partial, gby=[], aggr=[sum(hits.ResolutionWidth), sum(hits.ResolutionWidth + Int64(1)), sum(hits.ResolutionWidth + Int64(2)), sum(hits.ResolutionWidth + Int64(3)), sum(hits.ResolutionWidth + Int64(4)), sum(hits.ResolutionWidth + Int64(5)), sum(hits.ResolutionWidth + Int64(6)), sum(hits.ResolutionWidth + Int64(7)), sum(hits.ResolutionWidth + Int64(8)), sum(hits.ResolutionWidth + Int64(9)), sum(hits.ResolutionWidth + Int64(10)), sum(hits.ResolutionWidth + Int64(11)), sum(hits.ResolutionWidth + Int64(12)), sum(hits.ResolutionWidth + Int64(13)), sum(hits.ResolutionWidth + Int64(14)), sum(hits.ResolutionWidth + Int64(15)), sum(hits.ResolutionWidth + Int64(16)), sum(hits.ResolutionWidth + Int64(17)), sum(hits.ResolutionWidth + Int64(18)), sum(hits.ResolutionWidth + Int64(19)), sum(hits.ResolutionWidth + Int64(20)), sum(hits.ResolutionWidth + Int64(21)), sum(hits.ResolutionWidth + Int64(22)), sum(hits.ResolutionWidth + Int64(23)), sum(hits.ResolutionWidth + Int64(24)), sum(hits.ResolutionWidth + Int64(25)), sum(hits.ResolutionWidth + Int64(26)), sum(hits.ResolutionWidth + Int64(27)), sum(hits.ResolutionWidth + Int64(28)), sum(hits.ResolutionWidth + Int64(29)), sum(hits.ResolutionWidth + Int64(30)), sum(hits.ResolutionWidth + Int64(31)), sum(hits.ResolutionWidth + Int64(32)), sum(hits.ResolutionWidth + Int64(33)), sum(hits.ResolutionWidth + Int64(34)), sum(hits.ResolutionWidth + Int64(35)), sum(hits.ResolutionWidth + Int64(36)), sum(hits.ResolutionWidth + Int64(37)), sum(hits.ResolutionWidth + Int64(38)), sum(hits.ResolutionWidth + Int64(39)), sum(hits.ResolutionWidth + Int64(40)), sum(hits.ResolutionWidth + Int64(41)), sum(hits.ResolutionWidth + Int64(42)), sum(hits.ResolutionWidth + Int64(43)), sum(hits.ResolutionWidth + Int64(44)), sum(hits.ResolutionWidth + Int64(45)), sum(hits.ResolutionWidth + Int64(46)), sum(hits.ResolutionWidth + Int64(47)), sum(hits.ResolutionWidth + Int64(48)), sum(hits.ResolutionWidth + Int64(49)), sum(hits.ResolutionWidth + Int64(50)), sum(hits.ResolutionWidth + Int64(51)), sum(hits.ResolutionWidth + Int64(52)), sum(hits.ResolutionWidth + Int64(53)), sum(hits.ResolutionWidth + Int64(54)), sum(hits.ResolutionWidth + Int64(55)), sum(hits.ResolutionWidth + Int64(56)), sum(hits.ResolutionWidth + Int64(57)), sum(hits.ResolutionWidth + Int64(58)), sum(hits.ResolutionWidth + Int64(59)), sum(hits.ResolutionWidth + Int64(60)), sum(hits.ResolutionWidth + Int64(61)), sum(hits.ResolutionWidth + Int64(62)), sum(hits.ResolutionWidth + Int64(63)), sum(hits.ResolutionWidth + Int64(64)), sum(hits.ResolutionWidth + Int64(65)), sum(hits.ResolutionWidth + Int64(66)), sum(hits.ResolutionWidth + Int64(67)), sum(hits.ResolutionWidth + Int64(68)), sum(hits.ResolutionWidth + Int64(69)), sum(hits.ResolutionWidth + Int64(70)), sum(hits.ResolutionWidth + Int64(71)), sum(hits.ResolutionWidth + Int64(72)), sum(hits.ResolutionWidth + Int64(73)), sum(hits.ResolutionWidth + Int64(74)), sum(hits.ResolutionWidth + Int64(75)), sum(hits.ResolutionWidth + Int64(76)), sum(hits.ResolutionWidth + Int64(77)), sum(hits.ResolutionWidth + Int64(78)), sum(hits.ResolutionWidth + Int64(79)), sum(hits.ResolutionWidth + Int64(80)), sum(hits.ResolutionWidth + Int64(81)), sum(hits.ResolutionWidth + Int64(82)), sum(hits.ResolutionWidth + Int64(83)), sum(hits.ResolutionWidth + Int64(84)), sum(hits.ResolutionWidth + Int64(85)), sum(hits.ResolutionWidth + Int64(86)), sum(hits.ResolutionWidth + Int64(87)), sum(hits.ResolutionWidth + Int64(88)), sum(hits.ResolutionWidth + Int64(89))], metrics=[output_rows=16, elapsed_compute=4.30s, output_bytes=11.2 KB, output_batches=16]
      DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CAST(ResolutionWidth@20 AS Int64) as __common_expr_1], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=762.9 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=41.07 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=1.67ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=2.45ms, time_elapsed_processing=499.73ms, time_elapsed_scanning_total=5.12s, time_elapsed_scanning_until_data=27.26ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 396ms
```
</details>

---

### Q30

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 720ms | 744ms | 821ms |
| Hot avg | 673ms | 704ms | 715ms |
| All iters | [720, 678, 676, 670, 669] | [744, 711, 714, 701, 692] | [821, 706, 710, 728, 717] |
| LC vs Push | | | **0.98x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 1631MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=7.43µs, output_bytes=300.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 585], metrics=[output_rows=107, elapsed_compute=19.44ms, output_bytes=3.1 KB, output_batches=16, row_replacements=267]
    ProjectionExec: expr=[SearchEngineID@0 as SearchEngineID, ClientIP@1 as ClientIP, count(Int64(1))@2 as c, sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth)], metrics=[output_rows=5.73 M, elapsed_compute=1.49ms, output_bytes=10.3 GB, output_batches=704, expr_0_eval_time=184.95µs, expr_1_eval_time=89.58µs, expr_2_eval_time=81.52µs, expr_3_eval_time=69.18µs, expr_4_eval_time=78.83µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchEngineID@0 as SearchEngineID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=5.73 M, elapsed_compute=1.61s, output_bytes=10.3 GB, output_batches=704, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=741.3 M, aggregate_arguments_time=2.11ms, aggregation_time=779.77ms, emitting_time=27.00ms, time_calculating_group_ids=1.14s]
        RepartitionExec: partitioning=Hash([SearchEngineID@0, ClientIP@1], 16), input_partitions=16, metrics=[output_rows=7.90 M, elapsed_compute=86.25ms, output_bytes=289.8 MB, output_batches=976, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=9.70s, repartition_time=262.74ms, send_time=376.15ms]
          AggregateExec: mode=Partial, gby=[SearchEngineID@3 as SearchEngineID, ClientIP@0 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=7.90 M, elapsed_compute=2.65s, output_bytes=25.6 GB, output_batches=974, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=522.3 M, aggregate_arguments_time=71.45ms, aggregation_time=935.33ms, emitting_time=214.88µs, time_calculating_group_ids=2.02s, reduction_factor=60% (7.90 M/13.17 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[ClientIP, IsRefresh, ResolutionWidth, SearchEngineID], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=127.0 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=625.4 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.56ms, metadata_load_time=239.21ms, page_index_eval_time=2.83µs, row_pushdown_eval_time=32ns, statistics_eval_time=499.90µs, time_elapsed_opening=276.93ms, time_elapsed_processing=6.14s, time_elapsed_scanning_total=9.42s, time_elapsed_scanning_until_data=399.86ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 821ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=7.34µs, output_bytes=300.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 585], metrics=[output_rows=96, elapsed_compute=18.18ms, output_bytes=2.8 KB, output_batches=16, row_replacements=203]
    ProjectionExec: expr=[SearchEngineID@0 as SearchEngineID, ClientIP@1 as ClientIP, count(Int64(1))@2 as c, sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth)], metrics=[output_rows=5.73 M, elapsed_compute=1.42ms, output_bytes=10.3 GB, output_batches=704, expr_0_eval_time=139.18µs, expr_1_eval_time=81.64µs, expr_2_eval_time=67.75µs, expr_3_eval_time=61.68µs, expr_4_eval_time=61.68µs]
      AggregateExec: mode=FinalPartitioned, gby=[SearchEngineID@0 as SearchEngineID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=5.73 M, elapsed_compute=1.64s, output_bytes=10.3 GB, output_batches=704, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=741.3 M, aggregate_arguments_time=2.34ms, aggregation_time=807.74ms, emitting_time=24.84ms, time_calculating_group_ids=1.16s]
        RepartitionExec: partitioning=Hash([SearchEngineID@0, ClientIP@1], 16), input_partitions=16, metrics=[output_rows=7.90 M, elapsed_compute=90.67ms, output_bytes=289.8 MB, output_batches=976, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=8.62s, repartition_time=305.98ms, send_time=473.19ms]
          AggregateExec: mode=Partial, gby=[SearchEngineID@3 as SearchEngineID, ClientIP@0 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=7.90 M, elapsed_compute=2.36s, output_bytes=25.6 GB, output_batches=974, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=522.3 M, aggregate_arguments_time=75.71ms, aggregation_time=821.87ms, emitting_time=163.58µs, time_calculating_group_ids=1.79s, reduction_factor=60% (7.90 M/13.17 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[ClientIP, IsRefresh, ResolutionWidth, SearchEngineID], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=127.0 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=659.2 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=4.27ms, metadata_load_time=3.19ms, page_index_eval_time=3.28µs, row_pushdown_eval_time=32ns, statistics_eval_time=461.44µs, time_elapsed_opening=10.90ms, time_elapsed_processing=5.52s, time_elapsed_scanning_total=8.60s, time_elapsed_scanning_until_data=153.72ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 717ms
```
</details>

---

### Q31

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 897ms | 913ms | 1020ms |
| Hot avg | 829ms | 860ms | 934ms |
| All iters | [897, 853, 811, 845, 806] | [913, 880, 869, 836, 857] | [1020, 939, 913, 941, 942] |
| LC vs Push | | | **0.92x** |

**Cache Stats (after last iteration):**
- Entries: 12218 | Memory: 1631MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=7.80µs, output_bytes=360.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 1], metrics=[output_rows=20, elapsed_compute=35.94ms, output_bytes=720.0 B, output_batches=2, row_replacements=20]
    ProjectionExec: expr=[WatchID@0 as WatchID, ClientIP@1 as ClientIP, count(Int64(1))@2 as c, sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth)], metrics=[output_rows=13.17 M, elapsed_compute=3.34ms, output_bytes=56.8 GB, output_batches=1.62 K, expr_0_eval_time=357.50µs, expr_1_eval_time=185.57µs, expr_2_eval_time=190.53µs, expr_3_eval_time=148.12µs, expr_4_eval_time=158.07µs]
      AggregateExec: mode=FinalPartitioned, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=13.17 M, elapsed_compute=3.72s, output_bytes=56.8 GB, output_batches=1.62 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.68 B, aggregate_arguments_time=4.58ms, aggregation_time=1.49s, emitting_time=85.49ms, time_calculating_group_ids=2.83s]
        RepartitionExec: partitioning=Hash([WatchID@0, ClientIP@1], 16), input_partitions=16, metrics=[output_rows=13.17 M, elapsed_compute=385.23ms, output_bytes=555.5 MB, output_batches=1.62 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=8.22s, repartition_time=1.01s, send_time=2.72s]
          AggregateExec: mode=Partial, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=13.17 M, elapsed_compute=610.60ms, output_bytes=1656.4 MB, output_batches=10.15 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=11.56 M, peak_mem_used=107.9 M, aggregate_arguments_time=16.25ms, aggregation_time=135.70ms, emitting_time=294.19µs, time_calculating_group_ids=307.14ms, reduction_factor=100% (1.61 M/1.61 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[WatchID, ClientIP, IsRefresh, ResolutionWidth], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=202.4 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=1.47 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=1.98ms, metadata_load_time=160.55ms, page_index_eval_time=3.08µs, row_pushdown_eval_time=32ns, statistics_eval_time=362.85µs, time_elapsed_opening=190.03ms, time_elapsed_processing=6.56s, time_elapsed_scanning_total=14.43s, time_elapsed_scanning_until_data=557.66ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=24436
  Misses: cache_miss=12218
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 1020ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=9.06µs, output_bytes=360.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 1], metrics=[output_rows=10, elapsed_compute=34.18ms, output_bytes=360.0 B, output_batches=1, row_replacements=10]
    ProjectionExec: expr=[WatchID@0 as WatchID, ClientIP@1 as ClientIP, count(Int64(1))@2 as c, sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth)], metrics=[output_rows=13.17 M, elapsed_compute=3.52ms, output_bytes=56.8 GB, output_batches=1.62 K, expr_0_eval_time=311.55µs, expr_1_eval_time=212.01µs, expr_2_eval_time=180.52µs, expr_3_eval_time=173.28µs, expr_4_eval_time=147.12µs]
      AggregateExec: mode=FinalPartitioned, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=13.17 M, elapsed_compute=3.34s, output_bytes=56.8 GB, output_batches=1.62 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.68 B, aggregate_arguments_time=5.20ms, aggregation_time=1.14s, emitting_time=83.07ms, time_calculating_group_ids=2.62s]
        RepartitionExec: partitioning=Hash([WatchID@0, ClientIP@1], 16), input_partitions=16, metrics=[output_rows=13.17 M, elapsed_compute=389.78ms, output_bytes=555.5 MB, output_batches=1.62 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=7.41s, repartition_time=1.04s, send_time=2.62s]
          AggregateExec: mode=Partial, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=13.17 M, elapsed_compute=533.34ms, output_bytes=1656.4 MB, output_batches=10.15 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=11.56 M, peak_mem_used=107.9 M, aggregate_arguments_time=18.94ms, aggregation_time=66.60ms, emitting_time=256.17µs, time_calculating_group_ids=257.52ms, reduction_factor=100% (1.61 M/1.61 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[WatchID, ClientIP, IsRefresh, ResolutionWidth], file_type=liquid_parquet, metrics=[output_rows=13.17 M, elapsed_compute=16ns, output_bytes=202.4 MB, output_batches=12.14 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 226 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=1.56 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=2.58ms, metadata_load_time=2.62ms, page_index_eval_time=3.59µs, row_pushdown_eval_time=32ns, statistics_eval_time=442.62µs, time_elapsed_opening=8.29ms, time_elapsed_processing=6.20s, time_elapsed_scanning_total=13.56s, time_elapsed_scanning_until_data=304.32ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=12218, mem=1631MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=12218
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 942ms
```
</details>

---

### Q32

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 4514ms | 4309ms | 4495ms |
| Hot avg | 3295ms | 3252ms | 3355ms |
| All iters | [4514, 3702, 3594, 2898, 2986] | [4309, 4082, 3083, 2880, 2961] | [4495, 3929, 3370, 3096, 3025] |
| LC vs Push | | | **0.97x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=8.97µs, output_bytes=360.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 1], metrics=[output_rows=14, elapsed_compute=276.51ms, output_bytes=504.0 B, output_batches=4, row_replacements=14]
    ProjectionExec: expr=[WatchID@0 as WatchID, ClientIP@1 as ClientIP, count(Int64(1))@2 as c, sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth)], metrics=[output_rows=100.00 M, elapsed_compute=22.93ms, output_bytes=3.4 TB, output_batches=12.21 K, expr_0_eval_time=2.56ms, expr_1_eval_time=1.59ms, expr_2_eval_time=1.45ms, expr_3_eval_time=1.17ms, expr_4_eval_time=1.14ms]
      AggregateExec: mode=FinalPartitioned, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=100.00 M, elapsed_compute=56.69s, output_bytes=3.4 TB, output_batches=12.21 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=13.42 B, aggregate_arguments_time=30.38ms, aggregation_time=45.94s, emitting_time=750.95ms, time_calculating_group_ids=34.28s]
        RepartitionExec: partitioning=Hash([WatchID@0, ClientIP@1], 16), input_partitions=16, metrics=[output_rows=100.00 M, elapsed_compute=1.41s, output_bytes=4.1 GB, output_batches=12.21 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=6.60s, repartition_time=5.21s, send_time=23.47s]
          AggregateExec: mode=Partial, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=100.00 M, elapsed_compute=1.22s, output_bytes=5.1 GB, output_batches=12.22 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=98.29 M, peak_mem_used=107.0 M, aggregate_arguments_time=10.78ms, aggregation_time=140.23ms, emitting_time=260.40µs, time_calculating_group_ids=379.09ms, reduction_factor=100% (1.70 M/1.70 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[WatchID, ClientIP, IsRefresh, ResolutionWidth], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1526.9 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=1.10 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=158.16ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=174.18ms, time_elapsed_processing=3.74s, time_elapsed_scanning_total=65.72s, time_elapsed_scanning_until_data=415.60ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 4495ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=11.18µs, output_bytes=360.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 1], metrics=[output_rows=14, elapsed_compute=272.74ms, output_bytes=504.0 B, output_batches=4, row_replacements=14]
    ProjectionExec: expr=[WatchID@0 as WatchID, ClientIP@1 as ClientIP, count(Int64(1))@2 as c, sum(hits.IsRefresh)@3 as sum(hits.IsRefresh), avg(hits.ResolutionWidth)@4 as avg(hits.ResolutionWidth)], metrics=[output_rows=100.00 M, elapsed_compute=20.23ms, output_bytes=3.4 TB, output_batches=12.21 K, expr_0_eval_time=1.86ms, expr_1_eval_time=1.26ms, expr_2_eval_time=1.34ms, expr_3_eval_time=949.90µs, expr_4_eval_time=980.07µs]
      AggregateExec: mode=FinalPartitioned, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=100.00 M, elapsed_compute=35.24s, output_bytes=3.4 TB, output_batches=12.21 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=13.42 B, aggregate_arguments_time=46.56ms, aggregation_time=15.56s, emitting_time=740.33ms, time_calculating_group_ids=25.52s]
        RepartitionExec: partitioning=Hash([WatchID@0, ClientIP@1], 16), input_partitions=16, metrics=[output_rows=100.00 M, elapsed_compute=1.61s, output_bytes=4.1 GB, output_batches=12.21 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=4.48s, repartition_time=4.13s, send_time=14.16s]
          AggregateExec: mode=Partial, gby=[WatchID@0 as WatchID, ClientIP@1 as ClientIP], aggr=[count(Int64(1)), sum(hits.IsRefresh), avg(hits.ResolutionWidth)], metrics=[output_rows=100.00 M, elapsed_compute=1.11s, output_bytes=5.1 GB, output_batches=12.22 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=98.29 M, peak_mem_used=107.0 M, aggregate_arguments_time=8.36ms, aggregation_time=90.34ms, emitting_time=176.53µs, time_calculating_group_ids=257.01ms, reduction_factor=100% (1.70 M/1.70 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[WatchID, ClientIP, IsRefresh, ResolutionWidth], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1526.9 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=1.10 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=2.68ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=3.93ms, time_elapsed_processing=2.95s, time_elapsed_scanning_total=43.10s, time_elapsed_scanning_until_data=233.98ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 3025ms
```
</details>

---

### Q33

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 5334ms | 5355ms | 6704ms |
| Hot avg | 3456ms | 3604ms | 4882ms |
| All iters | [5334, 3986, 3260, 3283, 3297] | [5355, 4591, 3256, 3284, 3283] | [6704, 5363, 4740, 4834, 4592] |
| LC vs Push | | | **0.74x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=10.21µs, output_bytes=482.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@1 DESC], preserve_partitioning=[true], filter=[c@1 IS NULL OR c@1 > 63579], metrics=[output_rows=92, elapsed_compute=28.66ms, output_bytes=4.4 KB, output_batches=16, row_replacements=258]
    ProjectionExec: expr=[URL@0 as URL, count(Int64(1))@1 as c], metrics=[output_rows=18.34 M, elapsed_compute=1.08ms, output_bytes=613.9 GB, output_batches=2.25 K, expr_0_eval_time=174.98µs, expr_1_eval_time=146.67µs]
      AggregateExec: mode=FinalPartitioned, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=18.34 M, elapsed_compute=42.24s, output_bytes=613.9 GB, output_batches=2.25 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=11.28 B, aggregate_arguments_time=5.01ms, aggregation_time=405.55ms, emitting_time=144.57µs, time_calculating_group_ids=41.81s]
        RepartitionExec: partitioning=Hash([URL@0], 16), input_partitions=16, metrics=[output_rows=22.18 M, elapsed_compute=2.38s, output_bytes=3.7 GB, output_batches=2.72 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=53.84s, repartition_time=6.15s, send_time=7.72s]
          AggregateExec: mode=Partial, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=22.18 M, elapsed_compute=32.37s, output_bytes=888.7 GB, output_batches=2.71 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=6.58 B, aggregate_arguments_time=182.72ms, aggregation_time=889.63ms, emitting_time=270.03µs, time_calculating_group_ids=31.21s, reduction_factor=22% (22.18 M/100.00 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=11.3 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=2.65 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=157.19ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=178.17ms, time_elapsed_processing=14.92s, time_elapsed_scanning_total=53.63s, time_elapsed_scanning_until_data=544.10ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 6704ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=12.61µs, output_bytes=482.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@1 DESC], preserve_partitioning=[true], filter=[c@1 IS NULL OR c@1 > 63579], metrics=[output_rows=88, elapsed_compute=35.72ms, output_bytes=4.1 KB, output_batches=16, row_replacements=160]
    ProjectionExec: expr=[URL@0 as URL, count(Int64(1))@1 as c], metrics=[output_rows=18.34 M, elapsed_compute=1.60ms, output_bytes=613.9 GB, output_batches=2.25 K, expr_0_eval_time=274.85µs, expr_1_eval_time=213.98µs]
      AggregateExec: mode=FinalPartitioned, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=18.34 M, elapsed_compute=18.18s, output_bytes=613.9 GB, output_batches=2.25 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=11.28 B, aggregate_arguments_time=5.55ms, aggregation_time=457.19ms, emitting_time=191.02µs, time_calculating_group_ids=17.70s]
        RepartitionExec: partitioning=Hash([URL@0], 16), input_partitions=16, metrics=[output_rows=22.18 M, elapsed_compute=1.95s, output_bytes=3.7 GB, output_batches=2.72 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=47.29s, repartition_time=4.58s, send_time=5.05s]
          AggregateExec: mode=Partial, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=22.18 M, elapsed_compute=29.18s, output_bytes=888.7 GB, output_batches=2.71 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=6.58 B, aggregate_arguments_time=176.52ms, aggregation_time=970.20ms, emitting_time=263.60µs, time_calculating_group_ids=27.95s, reduction_factor=22% (22.18 M/100.00 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=11.3 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=2.65 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=2.37ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=3.30ms, time_elapsed_processing=15.34s, time_elapsed_scanning_total=47.26s, time_elapsed_scanning_until_data=363.82ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 4592ms
```
</details>

---

### Q34

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 5431ms | 5894ms | 7796ms |
| Hot avg | 3414ms | 3320ms | 4718ms |
| All iters | [5431, 3820, 3291, 3252, 3291] | [5894, 3384, 3272, 3294, 3330] | [7796, 5429, 4359, 4634, 4451] |
| LC vs Push | | | **0.70x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=10.00µs, output_bytes=562.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 63579], metrics=[output_rows=97, elapsed_compute=26.91ms, output_bytes=5.4 KB, output_batches=16, row_replacements=209]
    ProjectionExec: expr=[1 as Int64(1), URL@0 as URL, count(Int64(1))@1 as c], metrics=[output_rows=18.34 M, elapsed_compute=15.80ms, output_bytes=614.0 GB, output_batches=2.25 K, expr_0_eval_time=14.42ms, expr_1_eval_time=218.49µs, expr_2_eval_time=155.24µs]
      AggregateExec: mode=FinalPartitioned, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=18.34 M, elapsed_compute=62.02s, output_bytes=613.9 GB, output_batches=2.25 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=11.28 B, aggregate_arguments_time=4.44ms, aggregation_time=812.83ms, emitting_time=136.46µs, time_calculating_group_ids=61.18s]
        RepartitionExec: partitioning=Hash([URL@0], 16), input_partitions=16, metrics=[output_rows=22.18 M, elapsed_compute=3.05s, output_bytes=3.7 GB, output_batches=2.72 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=49.07s, repartition_time=7.45s, send_time=13.00s]
          AggregateExec: mode=Partial, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=22.18 M, elapsed_compute=31.14s, output_bytes=888.7 GB, output_batches=2.71 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=6.58 B, aggregate_arguments_time=191.07ms, aggregation_time=954.62ms, emitting_time=265.47µs, time_calculating_group_ids=29.92s, reduction_factor=22% (22.18 M/100.00 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=11.3 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=2.65 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=163.17ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=170.36ms, time_elapsed_processing=15.34s, time_elapsed_scanning_total=48.88s, time_elapsed_scanning_until_data=524.91ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 7796ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@2 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=10.81µs, output_bytes=562.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@2 DESC], preserve_partitioning=[true], filter=[c@2 IS NULL OR c@2 > 63579], metrics=[output_rows=92, elapsed_compute=33.52ms, output_bytes=5.0 KB, output_batches=16, row_replacements=244]
    ProjectionExec: expr=[1 as Int64(1), URL@0 as URL, count(Int64(1))@1 as c], metrics=[output_rows=18.34 M, elapsed_compute=11.56ms, output_bytes=614.0 GB, output_batches=2.25 K, expr_0_eval_time=9.82ms, expr_1_eval_time=281.63µs, expr_2_eval_time=183.63µs]
      AggregateExec: mode=FinalPartitioned, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=18.34 M, elapsed_compute=17.00s, output_bytes=613.9 GB, output_batches=2.25 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=11.28 B, aggregate_arguments_time=5.64ms, aggregation_time=473.83ms, emitting_time=144.71µs, time_calculating_group_ids=16.47s]
        RepartitionExec: partitioning=Hash([URL@0], 16), input_partitions=16, metrics=[output_rows=22.18 M, elapsed_compute=1.59s, output_bytes=3.7 GB, output_batches=2.72 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=45.67s, repartition_time=4.10s, send_time=6.12s]
          AggregateExec: mode=Partial, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=22.18 M, elapsed_compute=28.28s, output_bytes=888.7 GB, output_batches=2.71 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=6.58 B, aggregate_arguments_time=191.89ms, aggregation_time=928.03ms, emitting_time=269.32µs, time_calculating_group_ids=27.09s, reduction_factor=22% (22.18 M/100.00 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=11.3 GB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=2.65 B, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=2.36ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=3.33ms, time_elapsed_processing=14.55s, time_elapsed_scanning_total=45.65s, time_elapsed_scanning_until_data=368.14ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 4451ms
```
</details>

---

### Q35

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 959ms | 959ms | 1037ms |
| Hot avg | 938ms | 936ms | 956ms |
| All iters | [959, 938, 936, 925, 954] | [959, 937, 933, 937, 938] | [1037, 945, 982, 928, 970] |
| LC vs Push | | | **0.98x** |

**Cache Stats (after last iteration):**
- Entries: 0 | Memory: 0MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [c@4 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=7.21µs, output_bytes=360.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@4 DESC], preserve_partitioning=[true], filter=[c@4 IS NULL OR c@4 > 6208], metrics=[output_rows=68, elapsed_compute=20.88ms, output_bytes=2.4 KB, output_batches=15, row_replacements=167]
    ProjectionExec: expr=[ClientIP@0 as ClientIP, hits.ClientIP - Int64(1)@1 as hits.ClientIP - Int64(1), hits.ClientIP - Int64(2)@2 as hits.ClientIP - Int64(2), hits.ClientIP - Int64(3)@3 as hits.ClientIP - Int64(3), count(Int64(1))@4 as c], metrics=[output_rows=9.76 M, elapsed_compute=1.71ms, output_bytes=42.2 GB, output_batches=1.20 K, expr_0_eval_time=180.90µs, expr_1_eval_time=115.10µs, expr_2_eval_time=97.89µs, expr_3_eval_time=96.67µs, expr_4_eval_time=109.86µs]
      AggregateExec: mode=FinalPartitioned, gby=[ClientIP@0 as ClientIP, hits.ClientIP - Int64(1)@1 as hits.ClientIP - Int64(1), hits.ClientIP - Int64(2)@2 as hits.ClientIP - Int64(2), hits.ClientIP - Int64(3)@3 as hits.ClientIP - Int64(3)], aggr=[count(Int64(1))], metrics=[output_rows=9.76 M, elapsed_compute=3.20s, output_bytes=42.2 GB, output_batches=1.20 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.68 B, aggregate_arguments_time=1.96ms, aggregation_time=236.03ms, emitting_time=83.98µs, time_calculating_group_ids=2.96s]
        RepartitionExec: partitioning=Hash([ClientIP@0, hits.ClientIP - Int64(1)@1, hits.ClientIP - Int64(2)@2, hits.ClientIP - Int64(3)@3], 16), input_partitions=16, metrics=[output_rows=15.78 M, elapsed_compute=131.42ms, output_bytes=544.5 MB, output_batches=1.94 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=10.24s, repartition_time=496.22ms, send_time=768.67ms]
          AggregateExec: mode=Partial, gby=[ClientIP@1 as ClientIP, __common_expr_1@0 - 1 as hits.ClientIP - Int64(1), __common_expr_1@0 - 2 as hits.ClientIP - Int64(2), __common_expr_1@0 - 3 as hits.ClientIP - Int64(3)], aggr=[count(Int64(1))], metrics=[output_rows=15.78 M, elapsed_compute=8.38s, output_bytes=95.4 GB, output_batches=1.94 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.20 B, aggregate_arguments_time=51.84ms, aggregation_time=487.29ms, emitting_time=126.77µs, time_calculating_group_ids=7.66s, reduction_factor=16% (15.78 M/100.00 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CAST(ClientIP@7 AS Int64) as __common_expr_1, ClientIP], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1145.4 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=187.5 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=158.45ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=167.77ms, time_elapsed_processing=882.76ms, time_elapsed_scanning_total=10.06s, time_elapsed_scanning_until_data=161.49ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 1037ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [c@4 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=7.26µs, output_bytes=360.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[c@4 DESC], preserve_partitioning=[true], filter=[c@4 IS NULL OR c@4 > 6208], metrics=[output_rows=82, elapsed_compute=20.53ms, output_bytes=2.9 KB, output_batches=16, row_replacements=183]
    ProjectionExec: expr=[ClientIP@0 as ClientIP, hits.ClientIP - Int64(1)@1 as hits.ClientIP - Int64(1), hits.ClientIP - Int64(2)@2 as hits.ClientIP - Int64(2), hits.ClientIP - Int64(3)@3 as hits.ClientIP - Int64(3), count(Int64(1))@4 as c], metrics=[output_rows=9.76 M, elapsed_compute=1.67ms, output_bytes=42.2 GB, output_batches=1.20 K, expr_0_eval_time=127.12µs, expr_1_eval_time=87.48µs, expr_2_eval_time=88.17µs, expr_3_eval_time=88.91µs, expr_4_eval_time=87.25µs]
      AggregateExec: mode=FinalPartitioned, gby=[ClientIP@0 as ClientIP, hits.ClientIP - Int64(1)@1 as hits.ClientIP - Int64(1), hits.ClientIP - Int64(2)@2 as hits.ClientIP - Int64(2), hits.ClientIP - Int64(3)@3 as hits.ClientIP - Int64(3)], aggr=[count(Int64(1))], metrics=[output_rows=9.76 M, elapsed_compute=3.35s, output_bytes=42.2 GB, output_batches=1.20 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.68 B, aggregate_arguments_time=2.21ms, aggregation_time=255.16ms, emitting_time=74.88µs, time_calculating_group_ids=3.09s]
        RepartitionExec: partitioning=Hash([ClientIP@0, hits.ClientIP - Int64(1)@1, hits.ClientIP - Int64(2)@2, hits.ClientIP - Int64(3)@3], 16), input_partitions=16, metrics=[output_rows=15.78 M, elapsed_compute=150.18ms, output_bytes=544.5 MB, output_batches=1.94 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=9.70s, repartition_time=547.04ms, send_time=902.82ms]
          AggregateExec: mode=Partial, gby=[ClientIP@1 as ClientIP, __common_expr_1@0 - 1 as hits.ClientIP - Int64(1), __common_expr_1@0 - 2 as hits.ClientIP - Int64(2), __common_expr_1@0 - 3 as hits.ClientIP - Int64(3)], aggr=[count(Int64(1))], metrics=[output_rows=15.78 M, elapsed_compute=8.28s, output_bytes=95.4 GB, output_batches=1.94 K, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=1.20 B, aggregate_arguments_time=64.19ms, aggregation_time=507.24ms, emitting_time=115.77µs, time_calculating_group_ids=7.50s, reduction_factor=16% (15.78 M/100.00 M)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[CAST(ClientIP@7 AS Int64) as __common_expr_1, ClientIP], file_type=liquid_parquet, metrics=[output_rows=100.00 M, elapsed_compute=16ns, output_bytes=1145.4 MB, output_batches=12.22 K, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=0 total → 0 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=187.5 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=32ns, metadata_load_time=2.04ms, page_index_eval_time=32ns, row_pushdown_eval_time=32ns, statistics_eval_time=32ns, time_elapsed_opening=2.84ms, time_elapsed_processing=786.26ms, time_elapsed_scanning_total=9.69s, time_elapsed_scanning_until_data=46.74ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=0, mem=0MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=0
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 970ms
```
</details>

---

### Q36

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 196ms | 161ms | 212ms |
| Hot avg | 152ms | 125ms | 75ms |
| All iters | [196, 154, 150, 153, 150] | [161, 127, 125, 124, 124] | [212, 74, 76, 77, 72] |
| LC vs Push | | | **1.67x** |

**Cache Stats (after last iteration):**
- Entries: 860 | Memory: 184MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [pageviews@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=5.11µs, output_bytes=628.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[pageviews@1 DESC], preserve_partitioning=[true], filter=[pageviews@1 IS NULL OR pageviews@1 > 175], metrics=[output_rows=87, elapsed_compute=11.49ms, output_bytes=7.5 KB, output_batches=16, row_replacements=214]
    ProjectionExec: expr=[URL@0 as URL, count(Int64(1))@1 as pageviews], metrics=[output_rows=298.8 K, elapsed_compute=112.52µs, output_bytes=209.9 MB, output_batches=48, expr_0_eval_time=24.60µs, expr_1_eval_time=5.54µs]
      AggregateExec: mode=FinalPartitioned, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=298.8 K, elapsed_compute=215.95ms, output_bytes=209.9 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=179.0 M, aggregate_arguments_time=136.95µs, aggregation_time=8.25ms, emitting_time=217.99µs, time_calculating_group_ids=205.61ms]
        RepartitionExec: partitioning=Hash([URL@0], 16), input_partitions=16, metrics=[output_rows=301.9 K, elapsed_compute=49.10ms, output_bytes=40.4 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=399.89ms, repartition_time=23.17ms, send_time=2.55ms]
          AggregateExec: mode=Partial, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=301.9 K, elapsed_compute=52.32ms, output_bytes=1158.6 MB, output_batches=38, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=63.26 M, aggregate_arguments_time=404.53µs, aggregation_time=1.08ms, emitting_time=11.22µs, time_calculating_group_ids=50.63ms, reduction_factor=45% (301.9 K/671.5 K)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL], file_type=liquid_parquet, metrics=[output_rows=671.5 K, elapsed_compute=16ns, output_bytes=63.0 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=46.49 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=166.64µs, metadata_load_time=160.82ms, page_index_eval_time=3.48µs, row_pushdown_eval_time=32ns, statistics_eval_time=731.86µs, time_elapsed_opening=192.75ms, time_elapsed_processing=190.98ms, time_elapsed_scanning_total=206.68ms, time_elapsed_scanning_until_data=26.05ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=184MB, disk=0MB
  Hits: cache_hit=92, eval_predicate=804
  Misses: cache_miss=172
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 212ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [pageviews@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=5.36µs, output_bytes=628.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[pageviews@1 DESC], preserve_partitioning=[true], filter=[pageviews@1 IS NULL OR pageviews@1 > 175], metrics=[output_rows=103, elapsed_compute=2.05ms, output_bytes=9.0 KB, output_batches=16, row_replacements=143]
    ProjectionExec: expr=[URL@0 as URL, count(Int64(1))@1 as pageviews], metrics=[output_rows=298.8 K, elapsed_compute=106.37µs, output_bytes=209.9 MB, output_batches=48, expr_0_eval_time=20.87µs, expr_1_eval_time=5.06µs]
      AggregateExec: mode=FinalPartitioned, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=298.8 K, elapsed_compute=108.77ms, output_bytes=209.9 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=179.0 M, aggregate_arguments_time=119.57µs, aggregation_time=2.37ms, emitting_time=215.25µs, time_calculating_group_ids=105.48ms]
        RepartitionExec: partitioning=Hash([URL@0], 16), input_partitions=16, metrics=[output_rows=301.9 K, elapsed_compute=17.19ms, output_bytes=40.4 MB, output_batches=48, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=65.74ms, repartition_time=15.20ms, send_time=2.58ms]
          AggregateExec: mode=Partial, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=301.9 K, elapsed_compute=41.36ms, output_bytes=1158.6 MB, output_batches=38, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=63.26 M, aggregate_arguments_time=200.67µs, aggregation_time=941.35µs, emitting_time=11.90µs, time_calculating_group_ids=40.09ms, reduction_factor=45% (301.9 K/671.5 K)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL], file_type=liquid_parquet, metrics=[output_rows=671.5 K, elapsed_compute=16ns, output_bytes=63.0 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=160.82µs, metadata_load_time=3.30ms, page_index_eval_time=3.36µs, row_pushdown_eval_time=32ns, statistics_eval_time=734.31µs, time_elapsed_opening=7.49ms, time_elapsed_processing=24.11ms, time_elapsed_scanning_total=57.99ms, time_elapsed_scanning_until_data=494.76µs, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=184MB, disk=0MB
  Hits: cache_hit=92, eval_predicate=632
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 72ms
```
</details>

---

### Q37

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 130ms | 118ms | 145ms |
| Hot avg | 105ms | 96ms | 32ms |
| All iters | [130, 120, 102, 99, 100] | [118, 104, 94, 93, 93] | [145, 33, 31, 32, 31] |
| LC vs Push | | | **3.02x** |

**Cache Stats (after last iteration):**
- Entries: 860 | Memory: 131MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
SortPreservingMergeExec: [pageviews@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=6.68µs, output_bytes=603.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[pageviews@1 DESC], preserve_partitioning=[true], filter=[pageviews@1 IS NULL OR pageviews@1 > 217], metrics=[output_rows=97, elapsed_compute=1.16ms, output_bytes=6.6 KB, output_batches=16, row_replacements=133]
    ProjectionExec: expr=[Title@0 as Title, count(Int64(1))@1 as pageviews], metrics=[output_rows=42.16 K, elapsed_compute=50.15µs, output_bytes=4.6 MB, output_batches=16, expr_0_eval_time=13.38µs, expr_1_eval_time=2.15µs]
      AggregateExec: mode=FinalPartitioned, gby=[Title@0 as Title], aggr=[count(Int64(1))], metrics=[output_rows=42.16 K, elapsed_compute=55.47ms, output_bytes=4.6 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=14.28 M, aggregate_arguments_time=34.33µs, aggregation_time=258.97µs, emitting_time=87.88µs, time_calculating_group_ids=54.18ms]
        RepartitionExec: partitioning=Hash([Title@0], 16), input_partitions=16, metrics=[output_rows=44.80 K, elapsed_compute=12.91ms, output_bytes=4.4 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=395.52ms, repartition_time=1.36ms, send_time=85.30µs]
          AggregateExec: mode=Partial, gby=[Title@0 as Title], aggr=[count(Int64(1))], metrics=[output_rows=44.80 K, elapsed_compute=20.80ms, output_bytes=26.1 MB, output_batches=7, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=8.95 M, aggregate_arguments_time=373.70µs, aggregation_time=690.85µs, emitting_time=9.41µs, time_calculating_group_ids=19.57ms, reduction_factor=6.8% (44.80 K/660.3 K)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[Title], file_type=liquid_parquet, metrics=[output_rows=660.3 K, elapsed_compute=16ns, output_bytes=40.8 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=17.54 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=200.69µs, metadata_load_time=158.71ms, page_index_eval_time=3.12µs, row_pushdown_eval_time=32ns, statistics_eval_time=880.19µs, time_elapsed_opening=184.67ms, time_elapsed_processing=222.97ms, time_elapsed_scanning_total=210.55ms, time_elapsed_scanning_until_data=40.73ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=131MB, disk=0MB
  Hits: cache_hit=92, eval_predicate=804
  Misses: cache_miss=172
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 145ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
SortPreservingMergeExec: [pageviews@1 DESC], fetch=10, metrics=[output_rows=10, elapsed_compute=5.43µs, output_bytes=603.0 B, output_batches=1]
  SortExec: TopK(fetch=10), expr=[pageviews@1 DESC], preserve_partitioning=[true], filter=[pageviews@1 IS NULL OR pageviews@1 > 217], metrics=[output_rows=104, elapsed_compute=634.20µs, output_bytes=6.8 KB, output_batches=16, row_replacements=131]
    ProjectionExec: expr=[Title@0 as Title, count(Int64(1))@1 as pageviews], metrics=[output_rows=42.16 K, elapsed_compute=37.72µs, output_bytes=4.6 MB, output_batches=16, expr_0_eval_time=9.83µs, expr_1_eval_time=3.59µs]
      AggregateExec: mode=FinalPartitioned, gby=[Title@0 as Title], aggr=[count(Int64(1))], metrics=[output_rows=42.16 K, elapsed_compute=4.89ms, output_bytes=4.6 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=14.28 M, aggregate_arguments_time=21.49µs, aggregation_time=151.98µs, emitting_time=63.65µs, time_calculating_group_ids=4.49ms]
        RepartitionExec: partitioning=Hash([Title@0], 16), input_partitions=16, metrics=[output_rows=44.80 K, elapsed_compute=924.26µs, output_bytes=4.4 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=39.56ms, repartition_time=1.37ms, send_time=75.43µs]
          AggregateExec: mode=Partial, gby=[Title@0 as Title], aggr=[count(Int64(1))], metrics=[output_rows=44.80 K, elapsed_compute=16.91ms, output_bytes=26.1 MB, output_batches=7, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=8.95 M, aggregate_arguments_time=158.81µs, aggregation_time=710.79µs, emitting_time=5.98µs, time_calculating_group_ids=15.92ms, reduction_factor=6.8% (44.80 K/660.3 K)]
            DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[Title], file_type=liquid_parquet, metrics=[output_rows=660.3 K, elapsed_compute=16ns, output_bytes=40.8 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=0, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=207.92µs, metadata_load_time=3.34ms, page_index_eval_time=3.43µs, row_pushdown_eval_time=32ns, statistics_eval_time=843.02µs, time_elapsed_opening=7.74ms, time_elapsed_processing=22.47ms, time_elapsed_scanning_total=31.64ms, time_elapsed_scanning_until_data=572.60µs, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=131MB, disk=0MB
  Hits: cache_hit=92, eval_predicate=632
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 31ms
```
</details>

---

### Q38

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 138ms | 98ms | 116ms |
| Hot avg | 106ms | 73ms | 61ms |
| All iters | [138, 110, 111, 102, 103] | [98, 74, 74, 71, 74] | [116, 61, 63, 61, 60] |
| LC vs Push | | | **1.20x** |

**Cache Stats (after last iteration):**
- Entries: 860 | Memory: 16MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
GlobalLimitExec: skip=1000, fetch=10, metrics=[output_rows=10, elapsed_compute=9.82µs, output_bytes=107.9 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@1 DESC], fetch=1010, metrics=[output_rows=1.01 K, elapsed_compute=211.22µs, output_bytes=107.9 KB, output_batches=1]
    SortExec: TopK(fetch=1010), expr=[pageviews@1 DESC], preserve_partitioning=[true], metrics=[output_rows=13.30 K, elapsed_compute=7.84ms, output_bytes=1884.0 KB, output_batches=16, row_replacements=13.30 K]
      ProjectionExec: expr=[URL@0 as URL, count(Int64(1))@1 as pageviews], metrics=[output_rows=13.30 K, elapsed_compute=61.05µs, output_bytes=2.2 MB, output_batches=16, expr_0_eval_time=17.14µs, expr_1_eval_time=940ns]
        AggregateExec: mode=FinalPartitioned, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=13.30 K, elapsed_compute=34.18ms, output_bytes=2.2 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=5.58 M, aggregate_arguments_time=44.45µs, aggregation_time=165.65µs, emitting_time=106.61µs, time_calculating_group_ids=33.50ms]
          RepartitionExec: partitioning=Hash([URL@0], 16), input_partitions=16, metrics=[output_rows=13.63 K, elapsed_compute=12.96ms, output_bytes=2.8 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=302.51ms, repartition_time=548.67µs, send_time=44.06µs]
            AggregateExec: mode=Partial, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=13.63 K, elapsed_compute=2.21ms, output_bytes=4.9 MB, output_batches=3, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=3.57 M, aggregate_arguments_time=86.52µs, aggregation_time=72.01µs, emitting_time=8.13µs, time_calculating_group_ids=1.89ms, reduction_factor=29% (13.63 K/47.74 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL], file_type=liquid_parquet, metrics=[output_rows=47.74 K, elapsed_compute=16ns, output_bytes=3.5 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=46.49 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=155.21µs, metadata_load_time=155.90ms, page_index_eval_time=3.15µs, row_pushdown_eval_time=32ns, statistics_eval_time=933.07µs, time_elapsed_opening=178.46ms, time_elapsed_processing=147.12ms, time_elapsed_scanning_total=123.78ms, time_elapsed_scanning_until_data=20.63ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=16MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=804
  Misses: cache_miss=172
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 116ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
GlobalLimitExec: skip=1000, fetch=10, metrics=[output_rows=10, elapsed_compute=11.85µs, output_bytes=107.9 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@1 DESC], fetch=1010, metrics=[output_rows=1.01 K, elapsed_compute=69.06µs, output_bytes=107.9 KB, output_batches=1]
    SortExec: TopK(fetch=1010), expr=[pageviews@1 DESC], preserve_partitioning=[true], metrics=[output_rows=13.30 K, elapsed_compute=2.93ms, output_bytes=1884.0 KB, output_batches=16, row_replacements=13.30 K]
      ProjectionExec: expr=[URL@0 as URL, count(Int64(1))@1 as pageviews], metrics=[output_rows=13.30 K, elapsed_compute=28.22µs, output_bytes=2.2 MB, output_batches=16, expr_0_eval_time=6.75µs, expr_1_eval_time=1.45µs]
        AggregateExec: mode=FinalPartitioned, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=13.30 K, elapsed_compute=1.71ms, output_bytes=2.2 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=5.58 M, aggregate_arguments_time=19.14µs, aggregation_time=53.29µs, emitting_time=40.85µs, time_calculating_group_ids=1.47ms]
          RepartitionExec: partitioning=Hash([URL@0], 16), input_partitions=16, metrics=[output_rows=13.63 K, elapsed_compute=499.06µs, output_bytes=2.8 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=77.42ms, repartition_time=512.28µs, send_time=42.90µs]
            AggregateExec: mode=Partial, gby=[URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=13.63 K, elapsed_compute=2.26ms, output_bytes=4.9 MB, output_batches=3, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=3.57 M, aggregate_arguments_time=63.78µs, aggregation_time=67.79µs, emitting_time=7.76µs, time_calculating_group_ids=1.99ms, reduction_factor=29% (13.63 K/47.74 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL], file_type=liquid_parquet, metrics=[output_rows=47.74 K, elapsed_compute=16ns, output_bytes=3.5 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=46.49 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=197.61µs, metadata_load_time=3.23ms, page_index_eval_time=3.52µs, row_pushdown_eval_time=32ns, statistics_eval_time=672.37µs, time_elapsed_opening=7.33ms, time_elapsed_processing=65.84ms, time_elapsed_scanning_total=69.91ms, time_elapsed_scanning_until_data=10.33ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=16MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=632
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 60ms
```
</details>

---

### Q39

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 320ms | 261ms | 344ms |
| Hot avg | 276ms | 221ms | 260ms |
| All iters | [320, 267, 282, 291, 266] | [261, 222, 211, 214, 236] | [344, 265, 246, 275, 253] |
| LC vs Push | | | **0.85x** |

**Cache Stats (after last iteration):**
- Entries: 516 | Memory: 10MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
GlobalLimitExec: skip=1000, fetch=10, metrics=[output_rows=10, elapsed_compute=14.78µs, output_bytes=156.3 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@5 DESC], fetch=1010, metrics=[output_rows=1.01 K, elapsed_compute=83.35µs, output_bytes=156.3 KB, output_batches=1]
    SortExec: TopK(fetch=1010), expr=[pageviews@5 DESC], preserve_partitioning=[true], filter=[pageviews@5 IS NULL OR pageviews@5 > 3], metrics=[output_rows=15.74 K, elapsed_compute=15.48ms, output_bytes=3.0 MB, output_batches=16, row_replacements=32.39 K]
      ProjectionExec: expr=[TraficSourceID@0 as TraficSourceID, SearchEngineID@1 as SearchEngineID, AdvEngineID@2 as AdvEngineID, CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END@3 as src, URL@4 as dst, count(Int64(1))@5 as pageviews], metrics=[output_rows=426.3 K, elapsed_compute=119.07µs, output_bytes=555.9 MB, output_batches=64, expr_0_eval_time=12.11µs, expr_1_eval_time=4.38µs, expr_2_eval_time=4.32µs, expr_3_eval_time=5.02µs, expr_4_eval_time=4.37µs, expr_5_eval_time=5.22µs]
        AggregateExec: mode=FinalPartitioned, gby=[TraficSourceID@0 as TraficSourceID, SearchEngineID@1 as SearchEngineID, AdvEngineID@2 as AdvEngineID, CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END@3 as CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END, URL@4 as URL], aggr=[count(Int64(1))], metrics=[output_rows=426.3 K, elapsed_compute=348.85ms, output_bytes=555.9 MB, output_batches=64, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=309.3 M, aggregate_arguments_time=127.51µs, aggregation_time=17.28ms, emitting_time=86.90µs, time_calculating_group_ids=329.76ms]
          RepartitionExec: partitioning=Hash([TraficSourceID@0, SearchEngineID@1, AdvEngineID@2, CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END@3, URL@4], 16), input_partitions=16, metrics=[output_rows=428.7 K, elapsed_compute=79.88ms, output_bytes=99.4 MB, output_batches=64, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=547.91ms, repartition_time=58.76ms, send_time=1.72ms]
            AggregateExec: mode=Partial, gby=[TraficSourceID@2 as TraficSourceID, SearchEngineID@3 as SearchEngineID, AdvEngineID@4 as AdvEngineID, CASE WHEN SearchEngineID@3 = 0 AND AdvEngineID@4 = 0 THEN Referer@1 ELSE  END as CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END, URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=428.7 K, elapsed_compute=112.33ms, output_bytes=6.1 GB, output_batches=54, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=174.1 M, aggregate_arguments_time=281.30µs, aggregation_time=1.40ms, emitting_time=19.32µs, time_calculating_group_ids=94.07ms, reduction_factor=59% (428.7 K/722.7 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL, Referer, TraficSourceID, SearchEngineID, AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=722.7 K, elapsed_compute=16ns, output_bytes=132.0 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=91.50 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=92.31µs, metadata_load_time=159.20ms, page_index_eval_time=2.90µs, row_pushdown_eval_time=32ns, statistics_eval_time=500.73µs, time_elapsed_opening=189.46ms, time_elapsed_processing=268.37ms, time_elapsed_scanning_total=357.71ms, time_elapsed_scanning_until_data=37.92ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=516, mem=10MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=620
  Misses: cache_miss=172
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 344ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
GlobalLimitExec: skip=1000, fetch=10, metrics=[output_rows=10, elapsed_compute=16.18µs, output_bytes=156.2 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@5 DESC], fetch=1010, metrics=[output_rows=1.01 K, elapsed_compute=88.37µs, output_bytes=156.2 KB, output_batches=1]
    SortExec: TopK(fetch=1010), expr=[pageviews@5 DESC], preserve_partitioning=[true], filter=[pageviews@5 IS NULL OR pageviews@5 > 3], metrics=[output_rows=15.36 K, elapsed_compute=13.91ms, output_bytes=2.9 MB, output_batches=16, row_replacements=28.43 K]
      ProjectionExec: expr=[TraficSourceID@0 as TraficSourceID, SearchEngineID@1 as SearchEngineID, AdvEngineID@2 as AdvEngineID, CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END@3 as src, URL@4 as dst, count(Int64(1))@5 as pageviews], metrics=[output_rows=426.3 K, elapsed_compute=123.54µs, output_bytes=555.9 MB, output_batches=64, expr_0_eval_time=9.87µs, expr_1_eval_time=4.99µs, expr_2_eval_time=5.16µs, expr_3_eval_time=5.27µs, expr_4_eval_time=4.69µs, expr_5_eval_time=5.27µs]
        AggregateExec: mode=FinalPartitioned, gby=[TraficSourceID@0 as TraficSourceID, SearchEngineID@1 as SearchEngineID, AdvEngineID@2 as AdvEngineID, CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END@3 as CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END, URL@4 as URL], aggr=[count(Int64(1))], metrics=[output_rows=426.3 K, elapsed_compute=213.80ms, output_bytes=555.9 MB, output_batches=64, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=309.3 M, aggregate_arguments_time=159.62µs, aggregation_time=3.75ms, emitting_time=78.25µs, time_calculating_group_ids=208.74ms]
          RepartitionExec: partitioning=Hash([TraficSourceID@0, SearchEngineID@1, AdvEngineID@2, CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END@3, URL@4], 16), input_partitions=16, metrics=[output_rows=428.7 K, elapsed_compute=54.07ms, output_bytes=99.4 MB, output_batches=64, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=252.12ms, repartition_time=50.59ms, send_time=751.63µs]
            AggregateExec: mode=Partial, gby=[TraficSourceID@2 as TraficSourceID, SearchEngineID@3 as SearchEngineID, AdvEngineID@4 as AdvEngineID, CASE WHEN SearchEngineID@3 = 0 AND AdvEngineID@4 = 0 THEN Referer@1 ELSE  END as CASE WHEN hits.SearchEngineID = Int64(0) AND hits.AdvEngineID = Int64(0) THEN hits.Referer ELSE Utf8("") END, URL@0 as URL], aggr=[count(Int64(1))], metrics=[output_rows=428.7 K, elapsed_compute=105.93ms, output_bytes=6.1 GB, output_batches=54, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=174.1 M, aggregate_arguments_time=291.26µs, aggregation_time=1.44ms, emitting_time=9.34µs, time_calculating_group_ids=88.21ms, reduction_factor=59% (428.7 K/722.7 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[URL, Referer, TraficSourceID, SearchEngineID, AdvEngineID], file_type=liquid_parquet, metrics=[output_rows=722.7 K, elapsed_compute=16ns, output_bytes=132.0 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=91.50 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=126.89µs, metadata_load_time=2.88ms, page_index_eval_time=3.13µs, row_pushdown_eval_time=32ns, statistics_eval_time=512.78µs, time_elapsed_opening=6.21ms, time_elapsed_processing=129.25ms, time_elapsed_scanning_total=245.44ms, time_elapsed_scanning_until_data=19.44ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=516, mem=10MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=448
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 253ms
```
</details>

---

### Q40

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 72ms | 64ms | 45ms |
| Hot avg | 34ms | 40ms | 20ms |
| All iters | [72, 35, 37, 33, 33] | [64, 44, 39, 40, 38] | [45, 20, 22, 20, 20] |
| LC vs Push | | | **1.96x** |

**Cache Stats (after last iteration):**
- Entries: 860 | Memory: 24MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
GlobalLimitExec: skip=100, fetch=10, metrics=[output_rows=10, elapsed_compute=11.79µs, output_bytes=2.1 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=110, metrics=[output_rows=110, elapsed_compute=13.54µs, output_bytes=2.1 KB, output_batches=1]
    SortExec: TopK(fetch=110), expr=[pageviews@2 DESC], preserve_partitioning=[true], filter=[pageviews@2 IS NULL OR pageviews@2 > 6], metrics=[output_rows=1.37 K, elapsed_compute=4.17ms, output_bytes=26.7 KB, output_batches=16, row_replacements=1.86 K]
      ProjectionExec: expr=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate, count(Int64(1))@2 as pageviews], metrics=[output_rows=41.19 K, elapsed_compute=51.05µs, output_bytes=1089.8 KB, output_batches=16, expr_0_eval_time=12.37µs, expr_1_eval_time=1.92µs, expr_2_eval_time=1.36µs]
        AggregateExec: mode=FinalPartitioned, gby=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.19 K, elapsed_compute=31.28ms, output_bytes=1089.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=5.07 M, aggregate_arguments_time=22.75µs, aggregation_time=182.32µs, emitting_time=67.45µs, time_calculating_group_ids=30.75ms]
          RepartitionExec: partitioning=Hash([URLHash@0, hits.EventDate@1], 16), input_partitions=16, metrics=[output_rows=41.87 K, elapsed_compute=338.33µs, output_bytes=2.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=235.65ms, repartition_time=502.98µs, send_time=59.92µs]
            AggregateExec: mode=Partial, gby=[URLHash@1 as URLHash, CAST(CAST(EventDate@0 AS Int32) AS Date32) as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.87 K, elapsed_compute=4.00ms, output_bytes=5.8 MB, output_batches=6, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.57 M, aggregate_arguments_time=65.53µs, aggregation_time=570.36µs, emitting_time=18.43µs, time_calculating_group_ids=3.13ms, reduction_factor=47% (41.87 K/89.91 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[EventDate, URLHash], file_type=liquid_parquet, metrics=[output_rows=89.91 K, elapsed_compute=16ns, output_bytes=883.4 KB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=15.65 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=89.91 K, pushdown_rows_pruned=6.82 K, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=154.38µs, metadata_load_time=160.42ms, page_index_eval_time=3.08µs, row_pushdown_eval_time=257.11µs, statistics_eval_time=701.76µs, time_elapsed_opening=191.38ms, time_elapsed_processing=69.02ms, time_elapsed_scanning_total=44.02ms, time_elapsed_scanning_until_data=20.20ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=712
  Misses: cache_miss=172
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 45ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
GlobalLimitExec: skip=100, fetch=10, metrics=[output_rows=10, elapsed_compute=11.55µs, output_bytes=2.1 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=110, metrics=[output_rows=110, elapsed_compute=13.95µs, output_bytes=2.1 KB, output_batches=1]
    SortExec: TopK(fetch=110), expr=[pageviews@2 DESC], preserve_partitioning=[true], filter=[pageviews@2 IS NULL OR pageviews@2 > 6], metrics=[output_rows=1.53 K, elapsed_compute=1.23ms, output_bytes=30.0 KB, output_batches=16, row_replacements=3.17 K]
      ProjectionExec: expr=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate, count(Int64(1))@2 as pageviews], metrics=[output_rows=41.19 K, elapsed_compute=25.23µs, output_bytes=1089.8 KB, output_batches=16, expr_0_eval_time=4.48µs, expr_1_eval_time=1.54µs, expr_2_eval_time=1.35µs]
        AggregateExec: mode=FinalPartitioned, gby=[URLHash@0 as URLHash, hits.EventDate@1 as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.19 K, elapsed_compute=2.24ms, output_bytes=1089.8 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=5.07 M, aggregate_arguments_time=12.78µs, aggregation_time=92.65µs, emitting_time=27.32µs, time_calculating_group_ids=1.98ms]
          RepartitionExec: partitioning=Hash([URLHash@0, hits.EventDate@1], 16), input_partitions=16, metrics=[output_rows=41.87 K, elapsed_compute=239.34µs, output_bytes=2.5 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=28.88ms, repartition_time=446.93µs, send_time=54.07µs]
            AggregateExec: mode=Partial, gby=[URLHash@1 as URLHash, CAST(CAST(EventDate@0 AS Int32) AS Date32) as hits.EventDate], aggr=[count(Int64(1))], metrics=[output_rows=41.87 K, elapsed_compute=3.55ms, output_bytes=5.8 MB, output_batches=6, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=2.57 M, aggregate_arguments_time=59.85µs, aggregation_time=258.05µs, emitting_time=6.01µs, time_calculating_group_ids=3.03ms, reduction_factor=47% (41.87 K/89.91 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[EventDate, URLHash], file_type=liquid_parquet, metrics=[output_rows=89.91 K, elapsed_compute=16ns, output_bytes=883.4 KB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=15.65 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=89.91 K, pushdown_rows_pruned=6.82 K, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=240.72µs, metadata_load_time=3.39ms, page_index_eval_time=4.75µs, row_pushdown_eval_time=261.06µs, statistics_eval_time=749.68µs, time_elapsed_opening=8.09ms, time_elapsed_processing=22.45ms, time_elapsed_scanning_total=20.63ms, time_elapsed_scanning_until_data=5.13ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

---

### Q41

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 62ms | 63ms | 43ms |
| Hot avg | 33ms | 36ms | 20ms |
| All iters | [62, 34, 35, 32, 32] | [63, 39, 37, 35, 34] | [43, 22, 20, 20, 20] |
| LC vs Push | | | **1.77x** |

**Cache Stats (after last iteration):**
- Entries: 860 | Memory: 24MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
GlobalLimitExec: skip=10000, fetch=10, metrics=[output_rows=10, elapsed_compute=8.83µs, output_bytes=21.3 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=10010, metrics=[output_rows=10.01 K, elapsed_compute=531.24µs, output_bytes=117.3 KB, output_batches=2]
    SortExec: TopK(fetch=10010), expr=[pageviews@2 DESC], preserve_partitioning=[true], metrics=[output_rows=10.95 K, elapsed_compute=14.55ms, output_bytes=128.3 KB, output_batches=16, row_replacements=10.95 K]
      ProjectionExec: expr=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight, count(Int64(1))@2 as pageviews], metrics=[output_rows=10.95 K, elapsed_compute=71.57µs, output_bytes=149.5 KB, output_batches=16, expr_0_eval_time=18.87µs, expr_1_eval_time=2.26µs, expr_2_eval_time=1.86µs]
        AggregateExec: mode=FinalPartitioned, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=10.95 K, elapsed_compute=24.59ms, output_bytes=149.5 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.06 M, aggregate_arguments_time=28.31µs, aggregation_time=136.57µs, emitting_time=86.13µs, time_calculating_group_ids=24.00ms]
          RepartitionExec: partitioning=Hash([WindowClientWidth@0, WindowClientHeight@1], 16), input_partitions=16, metrics=[output_rows=12.33 K, elapsed_compute=252.90µs, output_bytes=1536.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=219.38ms, repartition_time=181.92µs, send_time=34.53µs]
            AggregateExec: mode=Partial, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=12.33 K, elapsed_compute=2.51ms, output_bytes=386.2 KB, output_batches=3, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=583.4 K, aggregate_arguments_time=275.57µs, aggregation_time=316.31µs, emitting_time=17.55µs, time_calculating_group_ids=1.76ms, reduction_factor=12% (12.33 K/102.7 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[WindowClientWidth, WindowClientHeight], file_type=liquid_parquet, metrics=[output_rows=102.7 K, elapsed_compute=16ns, output_bytes=406.5 KB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=9.85 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=181.86µs, metadata_load_time=160.22ms, page_index_eval_time=3.77µs, row_pushdown_eval_time=32ns, statistics_eval_time=749.61µs, time_elapsed_opening=186.87ms, time_elapsed_processing=63.84ms, time_elapsed_scanning_total=32.26ms, time_elapsed_scanning_until_data=10.43ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=804
  Misses: cache_miss=172
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 43ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
GlobalLimitExec: skip=10000, fetch=10, metrics=[output_rows=10, elapsed_compute=6.83µs, output_bytes=21.3 KB, output_batches=1]
  SortPreservingMergeExec: [pageviews@2 DESC], fetch=10010, metrics=[output_rows=10.01 K, elapsed_compute=338.25µs, output_bytes=117.3 KB, output_batches=2]
    SortExec: TopK(fetch=10010), expr=[pageviews@2 DESC], preserve_partitioning=[true], metrics=[output_rows=10.95 K, elapsed_compute=2.72ms, output_bytes=128.3 KB, output_batches=16, row_replacements=10.95 K]
      ProjectionExec: expr=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight, count(Int64(1))@2 as pageviews], metrics=[output_rows=10.95 K, elapsed_compute=22.08µs, output_bytes=149.5 KB, output_batches=16, expr_0_eval_time=3.57µs, expr_1_eval_time=1.24µs, expr_2_eval_time=1.28µs]
        AggregateExec: mode=FinalPartitioned, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=10.95 K, elapsed_compute=818.58µs, output_bytes=149.5 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=1.06 M, aggregate_arguments_time=11.91µs, aggregation_time=36.69µs, emitting_time=22.44µs, time_calculating_group_ids=657.16µs]
          RepartitionExec: partitioning=Hash([WindowClientWidth@0, WindowClientHeight@1], 16), input_partitions=16, metrics=[output_rows=12.33 K, elapsed_compute=141.58µs, output_bytes=1536.0 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=28.49ms, repartition_time=162.02µs, send_time=28.09µs]
            AggregateExec: mode=Partial, gby=[WindowClientWidth@0 as WindowClientWidth, WindowClientHeight@1 as WindowClientHeight], aggr=[count(Int64(1))], metrics=[output_rows=12.33 K, elapsed_compute=2.42ms, output_bytes=386.2 KB, output_batches=3, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=583.4 K, aggregate_arguments_time=62.32µs, aggregation_time=254.74µs, emitting_time=4.76µs, time_calculating_group_ids=1.98ms, reduction_factor=12% (12.33 K/102.7 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[WindowClientWidth, WindowClientHeight], file_type=liquid_parquet, metrics=[output_rows=102.7 K, elapsed_compute=16ns, output_bytes=406.5 KB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=9.85 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=244.00µs, metadata_load_time=3.47ms, page_index_eval_time=5.03µs, row_pushdown_eval_time=32ns, statistics_eval_time=819.75µs, time_elapsed_opening=8.25ms, time_elapsed_processing=24.00ms, time_elapsed_scanning_total=20.08ms, time_elapsed_scanning_until_data=4.83ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=632
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

---

### Q42

| Metric | No Pushdown | Pushdown | LiquidCache |
|--------|-------------|----------|-------------|
| Cold (iter 0) | 61ms | 57ms | 44ms |
| Hot avg | 30ms | 32ms | 20ms |
| All iters | [61, 32, 28, 32, 29] | [57, 37, 31, 30, 29] | [44, 18, 24, 18, 18] |
| LC vs Push | | | **1.63x** |

**Cache Stats (after last iteration):**
- Entries: 688 | Memory: 13MB | Disk: 0MB
- cache_hit=0, cache_miss=0, eval_predicate=0
- IO: read=0, write=0
- Squeeze: success=0, needs_io=0

<details>
<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>

```
GlobalLimitExec: skip=1000, fetch=10, metrics=[output_rows=10, elapsed_compute=9.66µs, output_bytes=15.8 KB, output_batches=1]
  SortPreservingMergeExec: [date_trunc(minute, m@0) ASC NULLS LAST], fetch=1010, metrics=[output_rows=1.01 K, elapsed_compute=64.22µs, output_bytes=15.8 KB, output_batches=1]
    SortExec: TopK(fetch=1010), expr=[date_trunc(minute, m@0) ASC NULLS LAST], preserve_partitioning=[true], metrics=[output_rows=1.44 K, elapsed_compute=539.43µs, output_bytes=22.5 KB, output_batches=16, row_replacements=1.44 K]
      ProjectionExec: expr=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as m, count(Int64(1))@1 as pageviews], metrics=[output_rows=1.44 K, elapsed_compute=16.23µs, output_bytes=27.2 KB, output_batches=16, expr_0_eval_time=3.06µs, expr_1_eval_time=1.20µs]
        AggregateExec: mode=FinalPartitioned, gby=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=1.44 K, elapsed_compute=368.20µs, output_bytes=27.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=204.3 K, aggregate_arguments_time=10.73µs, aggregation_time=17.75µs, emitting_time=15.81µs, time_calculating_group_ids=103.14µs]
          RepartitionExec: partitioning=Hash([date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0], 16), input_partitions=16, metrics=[output_rows=2.88 K, elapsed_compute=134.34µs, output_bytes=2.0 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=220.90ms, repartition_time=77.34µs, send_time=24.68µs]
            AggregateExec: mode=Partial, gby=[date_trunc(minute, to_timestamp_seconds(EventTime@0)) as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=2.88 K, elapsed_compute=5.54ms, output_bytes=68.7 KB, output_batches=2, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=259.8 K, aggregate_arguments_time=148.69µs, aggregation_time=330.06µs, emitting_time=13.89µs, time_calculating_group_ids=3.59ms, reduction_factor=0.43% (2.88 K/671.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[EventTime], file_type=liquid_parquet, metrics=[output_rows=671.5 K, elapsed_compute=16ns, output_bytes=5.1 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=4.78 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=169.16µs, metadata_load_time=161.51ms, page_index_eval_time=3.19µs, row_pushdown_eval_time=32ns, statistics_eval_time=648.06µs, time_elapsed_opening=188.41ms, time_elapsed_processing=59.20ms, time_elapsed_scanning_total=32.26ms, time_elapsed_scanning_until_data=9.23ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=712
  Misses: cache_miss=172
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 44ms
```
</details>

<details>
<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>

```
GlobalLimitExec: skip=1000, fetch=10, metrics=[output_rows=10, elapsed_compute=10.22µs, output_bytes=15.8 KB, output_batches=1]
  SortPreservingMergeExec: [date_trunc(minute, m@0) ASC NULLS LAST], fetch=1010, metrics=[output_rows=1.01 K, elapsed_compute=62.05µs, output_bytes=15.8 KB, output_batches=1]
    SortExec: TopK(fetch=1010), expr=[date_trunc(minute, m@0) ASC NULLS LAST], preserve_partitioning=[true], metrics=[output_rows=1.44 K, elapsed_compute=432.49µs, output_bytes=22.5 KB, output_batches=16, row_replacements=1.44 K]
      ProjectionExec: expr=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as m, count(Int64(1))@1 as pageviews], metrics=[output_rows=1.44 K, elapsed_compute=14.03µs, output_bytes=27.2 KB, output_batches=16, expr_0_eval_time=2.56µs, expr_1_eval_time=1.34µs]
        AggregateExec: mode=FinalPartitioned, gby=[date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0 as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=1.44 K, elapsed_compute=181.90µs, output_bytes=27.2 KB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, peak_mem_used=204.3 K, aggregate_arguments_time=9.60µs, aggregation_time=15.40µs, emitting_time=14.52µs, time_calculating_group_ids=70.83µs]
          RepartitionExec: partitioning=Hash([date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))@0], 16), input_partitions=16, metrics=[output_rows=2.88 K, elapsed_compute=109.25µs, output_bytes=2.0 MB, output_batches=16, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, fetch_time=26.52ms, repartition_time=45.95µs, send_time=21.27µs]
            AggregateExec: mode=Partial, gby=[date_trunc(minute, to_timestamp_seconds(EventTime@0)) as date_trunc(Utf8("minute"),to_timestamp_seconds(hits.EventTime))], aggr=[count(Int64(1))], metrics=[output_rows=2.88 K, elapsed_compute=5.56ms, output_bytes=68.7 KB, output_batches=2, spill_count=0, spilled_bytes=0.0 B, spilled_rows=0, skipped_aggregation_rows=0, peak_mem_used=259.8 K, aggregate_arguments_time=151.44µs, aggregation_time=340.20µs, emitting_time=2.42µs, time_calculating_group_ids=3.66ms, reduction_factor=0.43% (2.88 K/671.5 K)]
              DataSourceExec: file_groups={16 groups: [[home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:0..923748528], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:923748528..1847497056], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:1847497056..2771245584], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:2771245584..3694994112], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:3694994112..4618742640], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:4618742640..5542491168], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:5542491168..6466239696], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:6466239696..7389988224], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:7389988224..8313736752], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:8313736752..9237485280], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:9237485280..10161233808], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:10161233808..11084982336], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:11084982336..12008730864], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12008730864..12932479392], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:12932479392..13856227920], [home/ec2-user/liquid-cache/benchmark/clickbench/data/hits.parquet:13856227920..14779976446]]}, projection=[EventTime], file_type=liquid_parquet, metrics=[output_rows=671.5 K, elapsed_compute=16ns, output_bytes=5.1 MB, output_batches=92, files_ranges_pruned_statistics=16 total → 16 matched, row_groups_pruned_statistics=226 total → 3 matched, row_groups_pruned_bloom_filter=0 total → 0 matched, page_index_pages_pruned=0 total → 0 matched, page_index_rows_pruned=0 total → 0 matched, limit_pruned_row_groups=0 total → 0 matched, batches_split=0, bytes_scanned=4.78 M, file_open_errors=0, file_scan_errors=0, num_predicate_creation_errors=0, predicate_evaluation_errors=0, pushdown_rows_matched=0, pushdown_rows_pruned=0, predicate_cache_inner_records=0, predicate_cache_records=0, bloom_filter_eval_time=203.34µs, metadata_load_time=3.17ms, page_index_eval_time=6.55µs, row_pushdown_eval_time=32ns, statistics_eval_time=670.53µs, time_elapsed_opening=7.47ms, time_elapsed_processing=19.99ms, time_elapsed_scanning_total=18.90ms, time_elapsed_scanning_until_data=3.16ms, scan_efficiency_ratio=N/A (0/0)]

Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

---
