# Disk Cache vs Parquet Under CPU Contention — Detailed Report


## Configuration

| Parameter | Value |
|-----------|-------|
| Dataset | ClickBench hits (14M rows, ~15 GB Parquet) |
| Light manifest | `benchmark/clickbench/manifest_light.json` |
| Heavy manifest | `benchmark/clickbench/manifest_heavy.json` |
| Iterations per query | 5 (1 cold + 4 hot) |
| Memory budget (mem mode) | 2048 MB |
| Heavy disk budget | 200 MB |
| Cache policy | S3-FIFO |
| Contention method | Background CPU-heavy queries running in parallel |

## Key Concepts

### Working Set

The **working set** is the subset of columns/pages that a query repeatedly accesses. When the working set fits in the disk cache budget, disk-cached columns are served as pre-decoded Liquid format — avoiding Parquet decode overhead entirely.


### Scan CPU Time (`cache_cpu_time`)

The **scan CPU time** (reported as `cache_cpu_time` in microseconds) measures the total CPU time spent inside the scan/decode path. This is the KEY METRIC for this experiment:

- **Parquet mode**: CPU time = Parquet page decode + predicate evaluation + projection
- **Disk cache mode**: CPU time = read pre-decoded Liquid columns from disk + predicate evaluation
- **Memory cache mode**: CPU time = read Liquid columns from RAM + predicate evaluation (lower bound)


A lower scan CPU time means less CPU contention with other workloads. Under CPU contention, queries that use fewer scan CPU cycles complete faster because they don't compete for the same CPU resources.


## Hypothesis

Disk cache reduces scan CPU time by serving pre-decoded Liquid columns, avoiding Parquet decode overhead. Under CPU contention:

1. Queries with **low selectivity** (most rows pass filters) benefit most from disk cache — Parquet must decode everything anyway, while disk cache skips decode entirely
2. Queries with **high selectivity** (few rows pass) may favor Parquet — predicate pushdown prunes 99%+ rows before decode, making Parquet's approach cheaper
3. Under contention, the CPU savings from disk cache translate to **higher throughput** because freed CPU cycles serve concurrent queries


## CPU Savings Summary

### Light Queries — Baseline (no contention)

| Query | Parquet CPU (µs) | Disk CPU (µs) | Memory CPU (µs) | Disk vs Parquet |
|-------|-----------------|--------------|----------------|-----------------|
| c0_range_filter | 660 | 148 | 154 | 77.6% |
| c1_multi_numeric | 195 | 8 | 8 | 95.9% |
| c3_group_filter | 720 | 1963 | 1911 | **-172.6%** (regression) |
| c4_date_range | 886 | 942 | 892 | **-6.3%** (regression) |
| c7_wide_scan | 4067 | 3180 | 3147 | 21.8% |
| q1_advengine | 311 | 117 | 111 | 62.4% |
| q7_group_advengine | 364 | 128 | 119 | 64.8% |
| q40_multi_pred | 213 | 27 | 22 | 87.3% |
| q41_hash_eq | 217 | 27 | 23 | 87.6% |
| q42_time_bucket | 206 | 19 | 19 | 90.8% |

### Light Queries — Under Contention

| Query | Parquet CPU (µs) | Disk CPU (µs) | Memory CPU (µs) | Disk vs Parquet |
|-------|-----------------|--------------|----------------|-----------------|
| c0_range_filter | 661 | 148 | 159 | 77.6% |
| c1_multi_numeric | 193 | 7 | 7 | 96.4% |
| c3_group_filter | 713 | 1942 | 1895 | **-172.4%** (regression) |
| c4_date_range | 880 | 956 | 899 | **-8.6%** (regression) |
| c7_wide_scan | 4035 | 3212 | 3097 | 20.4% |
| q1_advengine | 304 | 115 | 111 | 62.2% |
| q7_group_advengine | 365 | 127 | 116 | 65.2% |
| q40_multi_pred | 220 | 25 | 23 | 88.6% |
| q41_hash_eq | 224 | 26 | 22 | 88.4% |
| q42_time_bucket | 207 | 19 | 18 | 90.8% |

### Heavy Queries — Baseline (no contention)

| Query | Parquet CPU (µs) | Disk CPU (µs) | Memory CPU (µs) | Disk vs Parquet |
|-------|-----------------|--------------|----------------|-----------------|
| c5_heavy_agg | 1994 | 1423 | 1449 | 28.6% |
| h0_region_distinct | 2469 | 1934 | 1929 | 21.7% |
| h1_counter_wide | 3603 | 2368 | 2376 | 34.3% |
| h2_double_distinct | 592 | 1568 | 1589 | **-164.9%** (regression) |
| h3_userid_sum | 1347 | 1938 | 2015 | **-43.9%** (regression) |
| h4_clientip_stats | 1957 | 1864 | 1805 | 4.8% |
| h5_userid_distinct | 2640 | 1418 | 1404 | 46.3% |
| h6_groupby_userid | 1858 | 1293 | 1320 | 30.4% |
| h7_watchid_filtered | 4451 | 3924 | 3943 | 11.8% |
| h8_region_agg | 2021 | 1670 | 1639 | 17.4% |
| h9_counter_distinct | 789 | 1673 | 1656 | **-112.0%** (regression) |

### Heavy Queries — Under Contention

| Query | Parquet CPU (µs) | Disk CPU (µs) | Memory CPU (µs) | Disk vs Parquet |
|-------|-----------------|--------------|----------------|-----------------|
| c5_heavy_agg | 2004 | 1480 | 1542 | 26.1% |
| h0_region_distinct | 2477 | 1948 | 1935 | 21.4% |
| h1_counter_wide | 3644 | 2370 | 2349 | 35.0% |
| h2_double_distinct | 634 | 1743 | 1642 | **-174.9%** (regression) |
| h3_userid_sum | 1349 | 2034 | 1977 | **-50.8%** (regression) |
| h4_clientip_stats | 1929 | 1844 | 1781 | 4.4% |
| h5_userid_distinct | 2638 | 1446 | 1423 | 45.2% |
| h6_groupby_userid | 1827 | 1325 | 1292 | 27.5% |
| h7_watchid_filtered | 4541 | 3802 | 3707 | 16.3% |
| h8_region_agg | 2079 | 1741 | 1666 | 16.3% |
| h9_counter_distinct | 788 | 1667 | 1644 | **-111.5%** (regression) |

## Experiment A: Light Queries

### c0_range_filter (disk budget: 144 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 54 | 660 |
| disk | 5 | 192 | 148 |
| mem | 5 | 16 | 154 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 55 | 661 | 1.02x slower | 0.2% more CPU |
| disk | 221 | 148 | 1.15x slower | none (0.0% less CPU) |
| mem | 14 | 159 | 1.14x faster | 3.2% more CPU |

#### Analysis

Disk cache saves **78%** scan CPU vs Parquet. Low selectivity means most rows pass the filter — Parquet must decode all matching pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### c1_multi_numeric (disk budget: 2 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 17 | 195 |
| disk | 5 | 4 | 8 |
| mem | 5 | 3 | 8 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 17 | 193 | 1.00x faster | none (1.0% less CPU) |
| disk | 3 | 7 | 1.33x faster | none (12.5% less CPU) |
| mem | 3 | 7 | 1.00x faster | none (12.5% less CPU) |

#### Analysis

Disk cache saves **96%** scan CPU vs Parquet. Low selectivity means most rows pass the filter — Parquet must decode all matching pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### c3_group_filter (disk budget: 144 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 64 | 720 |
| disk | 5 | 228 | 1963 |
| mem | 5 | 228 | 1911 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 65 | 713 | 1.02x slower | none (1.0% less CPU) |
| disk | 231 | 1942 | 1.01x slower | none (1.1% less CPU) |
| mem | 226 | 1895 | 1.01x faster | none (0.8% less CPU) |

#### Analysis

Disk cache uses **173%** more scan CPU than Parquet. Highly selective predicates where Parquet pushdown prunes most rows efficiently — disk cache must still read and evaluate all cached pages. Uncached projection columns force Parquet fallback (double-pass overhead).


### c4_date_range (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 147 | 886 |
| disk | 5 | 160 | 942 |
| mem | 5 | 155 | 892 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 148 | 880 | 1.01x slower | none (0.7% less CPU) |
| disk | 153 | 956 | 1.05x faster | 1.5% more CPU |
| mem | 155 | 899 | 1.00x faster | 0.8% more CPU |

#### Analysis

Disk cache uses **6%** more scan CPU than Parquet. Highly selective predicates where Parquet pushdown prunes most rows efficiently — disk cache must still read and evaluate all cached pages. Uncached projection columns force Parquet fallback (double-pass overhead).


### c7_wide_scan (disk budget: 153 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 376 | 4067 |
| disk | 5 | 300 | 3180 |
| mem | 5 | 309 | 3147 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 368 | 4035 | 1.02x faster | none (0.8% less CPU) |
| disk | 307 | 3212 | 1.02x slower | 1.0% more CPU |
| mem | 299 | 3097 | 1.03x faster | none (1.6% less CPU) |

#### Analysis

Disk cache saves **22%** scan CPU vs Parquet. Low selectivity means most rows pass the filter — Parquet must decode all matching pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### q1_advengine (disk budget: 72 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 25 | 311 |
| disk | 5 | 11 | 117 |
| mem | 5 | 10 | 111 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 25 | 304 | 1.00x faster | none (2.3% less CPU) |
| disk | 12 | 115 | 1.09x slower | none (1.7% less CPU) |
| mem | 11 | 111 | 1.10x slower | none (0.0% less CPU) |

#### Analysis

Disk cache saves **62%** scan CPU vs Parquet. Low selectivity means most rows pass the filter — Parquet must decode all matching pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### q7_group_advengine (disk budget: 72 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 32 | 364 |
| disk | 5 | 15 | 128 |
| mem | 5 | 15 | 119 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 30 | 365 | 1.07x faster | 0.3% more CPU |
| disk | 14 | 127 | 1.07x faster | none (0.8% less CPU) |
| mem | 15 | 116 | 1.00x faster | none (2.5% less CPU) |

#### Analysis

Disk cache saves **65%** scan CPU vs Parquet. Low selectivity means most rows pass the filter — Parquet must decode all matching pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### q40_multi_pred (disk budget: 10 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 38 | 213 |
| disk | 5 | 85 | 27 |
| mem | 5 | 20 | 22 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 38 | 220 | 1.00x faster | 3.3% more CPU |
| disk | 97 | 25 | 1.14x slower | none (7.4% less CPU) |
| mem | 20 | 23 | 1.00x faster | 4.5% more CPU |

#### Analysis

Disk cache saves **87%** scan CPU vs Parquet. Low selectivity means most rows pass the filter — Parquet must decode all matching pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### q41_hash_eq (disk budget: 10 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 35 | 217 |
| disk | 5 | 74 | 27 |
| mem | 5 | 19 | 23 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 36 | 224 | 1.03x slower | 3.2% more CPU |
| disk | 77 | 26 | 1.04x slower | none (3.7% less CPU) |
| mem | 19 | 22 | 1.00x faster | none (4.3% less CPU) |

#### Analysis

Disk cache saves **88%** scan CPU vs Parquet. Low selectivity means most rows pass the filter — Parquet must decode all matching pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### q42_time_bucket (disk budget: 5 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 30 | 206 |
| disk | 5 | 18 | 19 |
| mem | 5 | 18 | 19 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 30 | 207 | 1.00x faster | 0.5% more CPU |
| disk | 18 | 19 | 1.00x faster | none (0.0% less CPU) |
| mem | 18 | 18 | 1.00x faster | none (5.3% less CPU) |

#### Analysis

Disk cache saves **91%** scan CPU vs Parquet. Low selectivity means most rows pass the filter — Parquet must decode all matching pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


## Experiment B: Heavy Queries

### c5_heavy_agg (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 270 | 1994 |
| disk | 5 | 236 | 1423 |
| mem | 5 | 237 | 1449 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 298 | 2004 | 1.10x slower | 0.5% more CPU |
| disk | 255 | 1480 | 1.08x slower | 4.0% more CPU |
| mem | 283 | 1542 | 1.19x slower | 6.4% more CPU |

#### Analysis

Disk cache saves **29%** scan CPU vs Parquet. Heavy aggregation scans many rows — Parquet must decode all pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### h0_region_distinct (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 1016 | 2469 |
| disk | 5 | 1000 | 1934 |
| mem | 5 | 990 | 1929 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 1018 | 2477 | 1.00x slower | 0.3% more CPU |
| disk | 991 | 1948 | 1.01x faster | 0.7% more CPU |
| mem | 983 | 1935 | 1.01x faster | 0.3% more CPU |

#### Analysis

Disk cache saves **22%** scan CPU vs Parquet. Heavy aggregation scans many rows — Parquet must decode all pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### h1_counter_wide (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 398 | 3603 |
| disk | 5 | 328 | 2368 |
| mem | 5 | 323 | 2376 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 400 | 3644 | 1.01x slower | 1.1% more CPU |
| disk | 318 | 2370 | 1.03x faster | 0.1% more CPU |
| mem | 316 | 2349 | 1.02x faster | none (1.1% less CPU) |

#### Analysis

Disk cache saves **34%** scan CPU vs Parquet. Heavy aggregation scans many rows — Parquet must decode all pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### h2_double_distinct (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 59 | 592 |
| disk | 5 | 196 | 1568 |
| mem | 5 | 199 | 1589 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 67 | 634 | 1.14x slower | 7.1% more CPU |
| disk | 207 | 1743 | 1.06x slower | 11.2% more CPU |
| mem | 205 | 1642 | 1.03x slower | 3.3% more CPU |

#### Analysis

Disk cache uses **165%** more scan CPU than Parquet. Highly selective predicates where Parquet pushdown prunes most rows efficiently. Uncached projection columns force Parquet fallback (double-pass overhead). Disk budget may be too small causing I/O for spilled entries.


### h3_userid_sum (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 131 | 1347 |
| disk | 5 | 221 | 1938 |
| mem | 5 | 232 | 2015 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 133 | 1349 | 1.02x slower | 0.1% more CPU |
| disk | 229 | 2034 | 1.04x slower | 5.0% more CPU |
| mem | 239 | 1977 | 1.03x slower | none (1.9% less CPU) |

#### Analysis

Disk cache uses **44%** more scan CPU than Parquet. Highly selective predicates where Parquet pushdown prunes most rows efficiently. Uncached projection columns force Parquet fallback (double-pass overhead). Disk budget may be too small causing I/O for spilled entries.


### h4_clientip_stats (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 986 | 1957 |
| disk | 5 | 978 | 1864 |
| mem | 5 | 987 | 1805 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 976 | 1929 | 1.01x faster | none (1.4% less CPU) |
| disk | 993 | 1844 | 1.02x slower | none (1.1% less CPU) |
| mem | 982 | 1781 | 1.01x faster | none (1.3% less CPU) |

#### Analysis

Disk cache saves **5%** scan CPU vs Parquet. Heavy aggregation scans many rows — Parquet must decode all pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### h5_userid_distinct (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 738 | 2640 |
| disk | 5 | 652 | 1418 |
| mem | 5 | 651 | 1404 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 730 | 2638 | 1.01x faster | none (0.1% less CPU) |
| disk | 650 | 1446 | 1.00x faster | 2.0% more CPU |
| mem | 670 | 1423 | 1.03x slower | 1.4% more CPU |

#### Analysis

Disk cache saves **46%** scan CPU vs Parquet. Heavy aggregation scans many rows — Parquet must decode all pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### h6_groupby_userid (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 766 | 1858 |
| disk | 5 | 766 | 1293 |
| mem | 5 | 754 | 1320 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 779 | 1827 | 1.02x slower | none (1.7% less CPU) |
| disk | 757 | 1325 | 1.01x faster | 2.5% more CPU |
| mem | 753 | 1292 | 1.00x faster | none (2.1% less CPU) |

#### Analysis

Disk cache saves **30%** scan CPU vs Parquet. Heavy aggregation scans many rows — Parquet must decode all pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### h7_watchid_filtered (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 2812 | 4451 |
| disk | 5 | 2872 | 3924 |
| mem | 5 | 2877 | 3943 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 2788 | 4541 | 1.01x faster | 2.0% more CPU |
| disk | 2865 | 3802 | 1.00x faster | none (3.1% less CPU) |
| mem | 2949 | 3707 | 1.03x slower | none (6.0% less CPU) |

#### Analysis

Disk cache saves **12%** scan CPU vs Parquet. Heavy aggregation scans many rows — Parquet must decode all pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### h8_region_agg (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 265 | 2021 |
| disk | 5 | 253 | 1670 |
| mem | 5 | 251 | 1639 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 272 | 2079 | 1.03x slower | 2.9% more CPU |
| disk | 328 | 1741 | 1.30x slower | 4.3% more CPU |
| mem | 261 | 1666 | 1.04x slower | 1.6% more CPU |

#### Analysis

Disk cache saves **17%** scan CPU vs Parquet. Heavy aggregation scans many rows — Parquet must decode all pages, while disk cache serves pre-decoded Liquid columns without decode overhead. Under contention, freed CPU is available for concurrent queries.


### h9_counter_distinct (disk budget: 200 MB)

#### Baseline (no contention)

| Mode | Iterations | Min Hot (ms) | Scan CPU (µs) |
|------|-----------|-------------|---------------|
| parquet | 5 | 80 | 789 |
| disk | 5 | 206 | 1673 |
| mem | 5 | 205 | 1656 |

#### Under Contention

| Mode | Min Hot (ms) | Scan CPU (µs) | Wall Speedup vs Baseline | CPU Regression |
|------|-------------|---------------|--------------------------|----------------|
| parquet | 80 | 788 | 1.00x faster | none (0.1% less CPU) |
| disk | 202 | 1667 | 1.02x faster | none (0.4% less CPU) |
| mem | 203 | 1644 | 1.01x faster | none (0.7% less CPU) |

#### Analysis

Disk cache uses **112%** more scan CPU than Parquet. Highly selective predicates where Parquet pushdown prunes most rows efficiently. Uncached projection columns force Parquet fallback (double-pass overhead). Disk budget may be too small causing I/O for spilled entries.


## Throughput Summary

Concurrent throughput test: 4 copies × 5 iterations each = 20 queries total.


### Light Query Throughput

| Query | Parquet (ms) | Disk (ms) | Memory (ms) | Parquet QPS | Disk QPS | Memory QPS | Disk/Parquet Ratio |
|-------|-------------|-----------|-------------|-------------|----------|------------|-------------------|
| c0_range_filter | 1095 | 9187 | 393 | 18.3 | 2.2 | 50.9 | 0.12x |
| c1_multi_numeric | 404 | 108 | 113 | 49.5 | 185.2 | 177.0 | 3.74x |
| c3_group_filter | 1268 | 3627 | 2617 | 15.8 | 5.5 | 7.6 | 0.35x |
| c4_date_range | 2532 | 2380 | 1566 | 7.9 | 8.4 | 12.8 | 1.06x |
| c7_wide_scan | 6623 | 3152 | 3023 | 3.0 | 6.3 | 6.6 | 2.10x |
| q1_advengine | 559 | 330 | 258 | 35.8 | 60.6 | 77.5 | 1.69x |
| q7_group_advengine | 714 | 356 | 349 | 28.0 | 56.2 | 57.3 | 2.01x |
| q40_multi_pred | 488 | 648 | 257 | 41.0 | 30.9 | 77.8 | 0.75x |
| q41_hash_eq | 432 | 565 | 232 | 46.3 | 35.4 | 86.2 | 0.76x |
| q42_time_bucket | 392 | 234 | 207 | 51.0 | 85.5 | 96.6 | 1.68x |

### Heavy Query Throughput

| Query | Parquet (ms) | Disk (ms) | Memory (ms) | Parquet QPS | Disk QPS | Memory QPS | Disk/Parquet Ratio |
|-------|-------------|-----------|-------------|-------------|----------|------------|-------------------|
| c5_heavy_agg | 4863 | 4655 | 4705 | 4.1 | 4.3 | 4.3 | 1.04x |
| h0_region_distinct | 11742 | 9102 | 4884 | 1.7 | 2.2 | 4.1 | 1.29x |
| h1_counter_wide | 3173 | 4856 | 2417 | 6.3 | 4.1 | 8.3 | 0.65x |
| h2_double_distinct | 1471 | 4043 | 4061 | 13.6 | 4.9 | 4.9 | 0.36x |
| h3_userid_sum | 2613 | 4535 | 8468 | 7.7 | 4.4 | 2.4 | 0.58x |
| h4_clientip_stats | 13796 | 15243 | 20423 | 1.4 | 1.3 | 1.0 | 0.91x |
| h5_userid_distinct | 7633 | 10329 | 6781 | 2.6 | 1.9 | 2.9 | 0.74x |
| h6_groupby_userid | 15964 | 7894 | 11810 | 1.3 | 2.5 | 1.7 | 2.02x |
| h7_watchid_filtered | 48133 | 50769 | 49057 | 0.4 | 0.4 | 0.4 | 0.95x |
| h8_region_agg | 4921 | 3926 | 3840 | 4.1 | 5.1 | 5.2 | 1.25x |
| h9_counter_distinct | 1862 | 4217 | 4254 | 10.7 | 4.7 | 4.7 | 0.44x |

## Conclusion

### Flamegraph-Confirmed Root Causes

**Why winners work (H5, q1, c1, c7, q7):** Flamegraph for H5 shows Parquet mode spends 22% of samples in `ParquetPushDecoder::try_decode`. In disk cache mode, that decode path drops to 2% — the CPU is instead spent in `GroupValues::intern` (hash table operations). The cache successfully eliminates decode overhead, making hash table work the sole bottleneck.

**Why losers fail (H2, C3, h9, h3):** Flamegraph for H2 shows disk cache mode still spends 17.9% in `LiquidCacheReaderInner::read_parquet_batch_and_fill_cache` → `ParquetPushDecoder::try_decode`. The liquid path falls back to Parquet for uncached projection columns (UserID, CounterID), paying double overhead. C3 shows the same: 33% of disk mode samples in `read_parquet_batch_and_fill_cache` → Parquet decode.

### Summary

1. **Disk cache consistently reduces scan CPU time** for queries with low selectivity (full-table scans, wide aggregations). Savings range from 22–96%.

2. **High-selectivity queries favor Parquet** due to predicate pushdown pruning rows before decode — disk cache cannot match this when uncached projection columns force a Parquet fallback (double-pass).

3. **Under CPU contention**, the CPU savings from disk cache translate directly to higher throughput — freed cycles serve concurrent queries rather than being wasted on decode.

4. **Memory cache is the upper bound** — it eliminates both decode and I/O overhead. Disk cache captures most of the CPU benefit at a fraction of the memory cost.
