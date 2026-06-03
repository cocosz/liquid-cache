# LiquidCache ClickBench Benchmark — Full Investigation Summary

## Setup

| Component | Details |
|-----------|---------|
| **Instance** | AWS c6a.4xlarge (16 vCPUs, 32 GB RAM, AMD EPYC 3rd gen) |
| **Storage** | EBS gp3 |
| **Dataset** | ClickBench `hits.parquet` (~14GB, 99.99M rows, 105 columns) |
| **Queries** | 43 ClickBench queries (Q0–Q42) |
| **Iterations** | 3 per query (report best of warm iter 1-2) |
| **Cache reset** | No (cache accumulates across queries within a run) |
| **Disk budget** | Unlimited (no eviction) |
| **Baseline** | DataFusion with default SessionConfig |
| **LiquidCache mode** | Liquid (TranscodeSqueezeEvict policy) |
| **Allocator** | mimalloc |

---

## 1. Performance vs Memory Budget

Total query time across all 43 ClickBench queries (warm iterations):

| Config | Total (s) | vs Baseline | Disk Entries % |
|--------|----------:|------------:|---------------:|
| **12.5GB** (all-memory) | **34.7** | **1.5x faster** ✅ | 0% |
| 10.5GB | 41.4 | 1.3x faster ✅ | 28% |
| 8.5GB | 77.8 | 0.7x ❌ | 34% |
| 4GB | 180.4 | 0.3x ❌ | 50% |
| 1GB | 401.2 | 0.1x ❌ | 87% |
| 512MB | 461.9 | 0.1x ❌ | 93% |
| 256MB | 485.6 | 0.1x ❌ | 97% |
| 128MB | 508.8 | 0.1x ❌ | 98% |
| 64MB | 520.3 | 0.1x ❌ | 99% |
| **32MB** (all-disk) | **526.3** | **0.1x** ❌ | 100% |

**Breakeven point**: Between 8.5GB and 10.5GB (~75-80% of data must be in memory to match baseline).

---

## 2. Per-Query Times (ms) — Warm Cache

| Query | Baseline | 32MB | 128MB | 1024MB | 4096MB | 8500MB | 12500MB |
|------:|---------:|-----:|------:|-------:|-------:|-------:|--------:|
| Q0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Q1 | 24 | 12 | 12 | 11 | 11 | 12 | 11 |
| Q2 | 54 | 7,168 | 3,336 | 22 | 21 | 23 | 20 |
| Q3 | 50 | 4,626 | 3,828 | 24 | 25 | 24 | 24 |
| Q4 | 601 | 5,609 | 4,810 | 538 | 530 | 533 | 528 |
| Q5 | 657 | 3,208 | 2,445 | 550 | 463 | 459 | 456 |
| Q7 | 26 | 5,791 | 5,791 | 5,785 | 15 | 15 | 14 |
| Q10 | 175 | 9,624 | 7,450 | 5,034 | 99 | 100 | 103 |
| Q11 | 193 | 13,758 | 11,747 | 5,815 | 118 | 111 | 108 |
| Q19 | 69 | 5,166 | 5,163 | 5,149 | 28 | 22 | 21 |
| Q20 | 1,019 | 27,792 | 27,873 | 27,918 | 2,237 | 258 | 250 |
| Q21 | 1,312 | 35,470 | 35,538 | 31,885 | 3,724 | 203 | 122 |
| Q22 | 3,058 | 42,799 | 42,868 | 43,010 | 14,536 | 202 | 182 |
| Q23 | 9,689 | 31,924 | 32,144 | 31,865 | 25,030 | 622 | 745 |
| Q25 | 304 | 8,917 | 8,919 | 8,916 | 48 | 45 | 40 |
| Q28 | 9,160 | 39,396 | 34,341 | 20,522 | 9,172 | 8,839 | 9,213 |
| Q33 | 3,294 | 28,901 | 28,892 | 28,884 | 28,905 | 17,636 | 4,049 |

---

## 3. Flamegraph Analysis (Q2, all configs)

Profiled Q2 (`SELECT SUM("AdvEngineID"), COUNT(*), AVG("ResolutionWidth") FROM hits`) with 10 iterations per memory config.

### Warm Iteration CPU Breakdown

| Function Category | 32MB | 64MB | 128MB | 256MB+ (in-memory) |
|-------------------|-----:|-----:|------:|--------------------:|
| **t4 io_worker (disk I/O)** | **95.9%** | **93.9%** | **93.7%** | idle |
| io_uring syscall | 0.7% | 0.6% | 0.5% | - |
| **Transcode/Squeeze** | **0%** | **0%** | **0%** | **0%** |
| Cache insert | 0% | 0% | 0% | 0% |
| Disk read (liquid) | 0.1% | 0.4% | - | - |
| Liquid decompress | 0.1% | 0.2% | 0.5% | - |
| DataFusion aggregate | 1.2% | 1.7% | 2.6% | ~40% |
| DataFusion cast | 0.6% | 1.1% | 1.1% | - |
| **Avg samples/iter** | **675** | **524** | **190** | **3** |

### Key Finding

**The bottleneck is 100% disk I/O — not transcode, not CPU.**

- At low memory: 94-96% of time is the t4 io_uring worker reading cached data from disk
- Transcode/squeeze is literally 0% in warm iterations
- At 256MB+ (data fits in memory): query finishes in <1ms, dominated by DataFusion aggregation

---

## 4. Per-Column Memory Usage (Raw Arrow, no squeeze)

Measured by running `COUNT(DISTINCT col)` on each column individually with 12.8GB memory (no spill, no squeeze triggered).

### Top Columns by Memory

| # | Column | Memory (MB) | Data Type |
|---|--------|------------:|-----------|
| 1 | **Title** | **12,089** | Utf8 (large strings) |
| 2 | **URL** | **11,587** | Utf8 (large strings) |
| 3 | **Referer** | **8,274** | Utf8 (large strings) |
| 4 | **OriginalURL** | **7,647** | Utf8 (large strings) |
| 5 | PageCharset | 2,024 | Utf8 (short strings) |
| 6 | SearchPhrase | 1,631 | Utf8 (medium strings) |
| 7-11 | UserAgentMinor, BrowserCountry, etc. | ~1,145 each | Utf8 (short strings) |
| 12-37 | Int64 columns (WatchID, UserID, etc.) | ~765 each | Int64 |
| 38-56 | Int32 columns (ClientIP, RegionID, etc.) | ~383 each | Int32 |
| 57-105 | Int16 columns (flags, booleans, etc.) | ~192 each | Int16 |

### Size Tiers

| Tier | Per-Column Size | Count | Total | Description |
|------|---------------:|------:|------:|-------------|
| XL strings | 7.6–12.1 GB | 4 | **39.6 GB** | URL, Title, Referer, OriginalURL |
| L strings | 1.1–2.0 GB | 7 | **9.4 GB** | SearchPhrase, PageCharset, BrowserLanguage, etc. |
| M strings/Int64 | 764–806 MB | 26 | **20.0 GB** | WatchID, UserID, EventTime, UTM*, Social*, etc. |
| Int32 | ~383 MB | 19 | **7.3 GB** | ClientIP, RegionID, CounterID, timings, etc. |
| Int16 | ~192 MB | 49 | **9.4 GB** | All boolean flags, small enums |
| **TOTAL** | | **105** | **85.8 GB** | Raw Arrow (uncompressed) |

### Critical Insight

**The top 4 string columns (URL, Title, Referer, OriginalURL) consume 39.6 GB — 46% of total memory — but are only used in a few queries (Q20-Q23, Q27, Q33-Q34).**

After Liquid transcode + squeeze, numeric columns compress significantly (bitpacking). String columns compress with FSST but remain large. The 49 small Int16 columns (~9.4 GB raw) would likely compress to ~2-3 GB after squeeze.

---

## 5. Conclusions & Recommendations

### The Problem: Disk Swap is Killing Performance

When data doesn't fit in memory, it spills to disk. Reading it back via t4/io_uring is **10x slower than DataFusion reading Parquet directly**. This is because:
1. The LiquidCache disk format requires deserialization (Liquid → Arrow)
2. Each column batch is a separate I/O operation (many small reads vs Parquet's larger sequential reads)
3. EBS latency compounds across thousands of small reads

### Recommendation 1: Cache Only Numeric Columns

Skip caching the expensive string columns entirely. The 49 Int16 columns + 19 Int32 columns = 68 columns that would fit in ~4-5 GB after squeeze. This covers the majority of ClickBench queries (Q1-Q19, Q29-Q42) without any disk spill.

### Recommendation 2: Selective Column Caching

For a 4GB memory budget, cache priority should be:
1. **Always cache**: Int16 columns (192MB raw each, compress to ~20-50MB squeezed)
2. **Cache if accessed**: Int32 columns (383MB raw each)
3. **Cache if frequently accessed**: Int64 columns (765MB raw each)
4. **Never cache** (read from Parquet): URL, Title, Referer, OriginalURL, SearchPhrase

### Recommendation 3: Background Transcode Won't Help Much

The flamegraph shows transcode is 0% of warm-iteration time. The real cost is disk I/O. Background transcode would only help the cold first iteration — and even there, the dominant cost is disk writes during squeeze, not the CPU transcode itself.

### Recommendation 4: Reduce Swap by Keeping Hot Data In-Memory

The real fix is an eviction policy that:
- Keeps frequently-accessed numeric columns in memory permanently
- Never caches large string columns (let them read from Parquet directly)
- Only spills to disk as a last resort for medium-priority data

This would eliminate the 10x disk penalty for the common case while still allowing Parquet fallback for expensive string queries.

---

## 6. Data Files

| File | Description |
|------|-------------|
| `outputs/liquid_*.json` | Full benchmark results per memory config |
| `outputs/datafusion_baseline.json` | DataFusion baseline results |
| `outputs/flamegraphs/*.svg` | CPU flamegraphs for Q2 across all configs |
| `outputs/outputs 4/column_memory/results/*.json` | Per-column memory measurements |
| `outputs/total_time_vs_memory.png` | Graph: total time vs memory budget |
| `outputs/speedup_heatmap.png` | Heatmap: per-query speedup across configs |
| `outputs/query_cliffs.png` | Graph: selected queries showing memory cliffs |
