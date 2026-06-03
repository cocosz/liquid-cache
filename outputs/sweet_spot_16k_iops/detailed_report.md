# Sweet Spot Detailed Analysis

## Configuration

| Parameter | Value |
|---|---|
| Instance | c6a.4xlarge |
| Dataset | ClickBench hits.parquet (~14.8 GB) |
| Iterations | 5 |
| Cache policy | S3-FIFO (LiquidPolicy) |
| Squeeze policy | TranscodeSqueezeEvict |
| Hydration | NoHydration |
| Strategy | Numeric predicate-only caching |

---

## Q19

```sql
SELECT "UserID" FROM hits WHERE "UserID" = 435090932899640449;
```

**Pushdown baseline:** 86ms

### Performance vs Memory Budget

| Budget | Cold (ms) | Hot avg (ms) | All iters | Speedup | Entries | Mem | Disk | IO r/w | eval_pred | cache_hit |
|--------|-----------|-------------|-----------|---------|---------|-----|------|--------|-----------|----------|
| 8MB | 18305 | 682 | [18305, 685, 681, 679, 685] | 0.13x | 10668 | 7MB | 619MB | 0/0 | 0 | 0 |
| 16MB | 18147 | 630 | [18147, 624, 629, 633, 635] | 0.14x | 10668 | 15MB | 620MB | 0/0 | 0 | 0 |
| 32MB | 18230 | 603 | [18230, 600, 607, 607, 599] | 0.14x | 10668 | 31MB | 620MB | 0/0 | 0 | 0 |
| 64MB | 18223 | 509 | [18223, 506, 509, 510, 510] | 0.17x | 10668 | 63MB | 619MB | 0/0 | 0 | 0 |
| 128MB | 18141 | 364 | [18141, 368, 362, 364, 364] | 0.23x | 10668 | 127MB | 620MB | 0/0 | 0 | 0 |
| 256MB | 18145 | 168 | [18145, 168, 169, 168, 169] | 0.51x | 10668 | 255MB | 620MB | 0/0 | 0 | 0 |
| 384MB | 13792 | 33 | [13792, 35, 32, 32, 33] | 2.59x | 10668 | 383MB | 470MB | 0/0 | 0 | 0 |
| 512MB | 6542 | 27 | [6542, 26, 27, 29, 27] | 3.14x | 10668 | 511MB | 216MB | 0/0 | 0 | 0 |
| 768MB | 166 | 21 | [166, 22, 21, 21, 21] | 4.02x | 10668 | 668MB | 0MB | 0/0 | 0 | 0 |
| 1024MB | 164 | 21 | [164, 22, 21, 21, 20] | 4.07x | 10668 | 668MB | 0MB | 0/0 | 0 | 0 |
| 2048MB | 167 | 21 | [167, 21, 20, 22, 21] | 4.07x | 10668 | 668MB | 0MB | 0/0 | 0 | 0 |

### Cache Stats (last iteration, per config)

<details>
<summary>8MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=7MB, disk=619MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=10400, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 685ms
```
</details>

<details>
<summary>16MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=15MB, disk=620MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=10126, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 635ms
```
</details>

<details>
<summary>32MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=31MB, disk=620MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=9574, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 599ms
```
</details>

<details>
<summary>64MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=63MB, disk=619MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=8451, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 510ms
```
</details>

<details>
<summary>128MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=127MB, disk=620MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=6270, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 364ms
```
</details>

<details>
<summary>256MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=255MB, disk=620MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=1871, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=2
Time: 169ms
```
</details>

<details>
<summary>384MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=383MB, disk=470MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=3, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=2
Time: 33ms
```
</details>

<details>
<summary>512MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=511MB, disk=216MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 27ms
```
</details>

<details>
<summary>768MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=668MB, disk=0MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 21ms
```
</details>

<details>
<summary>1024MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=668MB, disk=0MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

<details>
<summary>2048MB cache stats (hot)</summary>

```
Cache: entries=10668, mem=668MB, disk=0MB
  Hits: cache_hit=1, eval_predicate=10668
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 21ms
```
</details>

### Flamegraphs

- **8MB:** 5 flamegraphs in `flamegraphs/q19_8mb/`
- **16MB:** 5 flamegraphs in `flamegraphs/q19_16mb/`
- **32MB:** 5 flamegraphs in `flamegraphs/q19_32mb/`
- **64MB:** 5 flamegraphs in `flamegraphs/q19_64mb/`
- **128MB:** 5 flamegraphs in `flamegraphs/q19_128mb/`
- **256MB:** 5 flamegraphs in `flamegraphs/q19_256mb/`
- **384MB:** 5 flamegraphs in `flamegraphs/q19_384mb/`
- **512MB:** 5 flamegraphs in `flamegraphs/q19_512mb/`
- **768MB:** 5 flamegraphs in `flamegraphs/q19_768mb/`
- **1024MB:** 5 flamegraphs in `flamegraphs/q19_1024mb/`
- **2048MB:** 5 flamegraphs in `flamegraphs/q19_2048mb/`

---

## Q7

```sql
SELECT "AdvEngineID", COUNT(*) FROM hits WHERE "AdvEngineID" <> 0 GROUP BY "AdvEngineID" ORDER BY COUNT(*) DESC;
```

**Pushdown baseline:** 32ms

### Performance vs Memory Budget

| Budget | Cold (ms) | Hot avg (ms) | All iters | Speedup | Entries | Mem | Disk | IO r/w | eval_pred | cache_hit |
|--------|-----------|-------------|-----------|---------|---------|-----|------|--------|-----------|----------|
| 8MB | 9290 | 560 | [9290, 560, 565, 557, 558] | 0.06x | 11540 | 7MB | 17MB | 0/0 | 0 | 0 |
| 16MB | 4938 | 345 | [4938, 345, 347, 344, 345] | 0.09x | 11540 | 15MB | 10MB | 0/0 | 0 | 0 |
| 32MB | 55 | 16 | [55, 16, 15, 17, 15] | 2.00x | 11540 | 31MB | 0MB | 0/0 | 0 | 0 |
| 64MB | 62 | 16 | [62, 15, 15, 15, 18] | 2.00x | 11540 | 63MB | 0MB | 0/0 | 0 | 0 |
| 128MB | 64 | 16 | [64, 17, 17, 16, 15] | 1.94x | 11540 | 127MB | 0MB | 0/0 | 0 | 0 |
| 256MB | 62 | 15 | [62, 13, 15, 14, 17] | 2.14x | 11540 | 181MB | 0MB | 0/0 | 0 | 0 |
| 384MB | 62 | 15 | [62, 18, 14, 14, 15] | 2.07x | 11540 | 181MB | 0MB | 0/0 | 0 | 0 |
| 512MB | 60 | 15 | [60, 16, 16, 14, 15] | 2.07x | 11540 | 181MB | 0MB | 0/0 | 0 | 0 |
| 768MB | 61 | 16 | [61, 15, 17, 17, 16] | 1.94x | 11540 | 181MB | 0MB | 0/0 | 0 | 0 |
| 1024MB | 63 | 16 | [63, 15, 15, 16, 16] | 2.03x | 11540 | 181MB | 0MB | 0/0 | 0 | 0 |
| 2048MB | 63 | 16 | [63, 15, 17, 17, 15] | 1.97x | 11540 | 181MB | 0MB | 0/0 | 0 | 0 |

### Cache Stats (last iteration, per config)

<details>
<summary>8MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=7MB, disk=17MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=11939, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 558ms
```
</details>

<details>
<summary>16MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=15MB, disk=10MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=6347, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 345ms
```
</details>

<details>
<summary>32MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=31MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 15ms
```
</details>

<details>
<summary>64MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=63MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>128MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=127MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 15ms
```
</details>

<details>
<summary>256MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 17ms
```
</details>

<details>
<summary>384MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 15ms
```
</details>

<details>
<summary>512MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 15ms
```
</details>

<details>
<summary>768MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 16ms
```
</details>

<details>
<summary>1024MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 16ms
```
</details>

<details>
<summary>2048MB cache stats (hot)</summary>

```
Cache: entries=11540, mem=181MB, disk=0MB
  Hits: cache_hit=5868, eval_predicate=11540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 15ms
```
</details>

### Flamegraphs

- **8MB:** 5 flamegraphs in `flamegraphs/q7_8mb/`
- **16MB:** 5 flamegraphs in `flamegraphs/q7_16mb/`
- **32MB:** 5 flamegraphs in `flamegraphs/q7_32mb/`
- **64MB:** 5 flamegraphs in `flamegraphs/q7_64mb/`
- **128MB:** 5 flamegraphs in `flamegraphs/q7_128mb/`
- **256MB:** 5 flamegraphs in `flamegraphs/q7_256mb/`
- **384MB:** 5 flamegraphs in `flamegraphs/q7_384mb/`
- **512MB:** 5 flamegraphs in `flamegraphs/q7_512mb/`
- **768MB:** 5 flamegraphs in `flamegraphs/q7_768mb/`
- **1024MB:** 5 flamegraphs in `flamegraphs/q7_1024mb/`
- **2048MB:** 5 flamegraphs in `flamegraphs/q7_2048mb/`

---

## Q40

```sql
SELECT "URLHash", "EventDate"::INT::DATE, COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-01' AND "EventDate"::INT::DATE <= '2013-07-31' AND "IsRefresh" = 0 AND "TraficSourceID" IN (-1, 6) AND "RefererHash" = 3594120000172545465 GROUP BY "URLHash", "EventDate"::INT::DATE ORDER BY PageViews DESC LIMIT 10 OFFSET 100;
```

**Pushdown baseline:** 40ms

### Performance vs Memory Budget

| Budget | Cold (ms) | Hot avg (ms) | All iters | Speedup | Entries | Mem | Disk | IO r/w | eval_pred | cache_hit |
|--------|-----------|-------------|-----------|---------|---------|-----|------|--------|-----------|----------|
| 8MB | 930 | 190 | [930, 191, 189, 190, 192] | 0.21x | 860 | 7MB | 7MB | 0/0 | 0 | 0 |
| 16MB | 48 | 22 | [48, 25, 20, 20, 21] | 1.85x | 860 | 15MB | 0MB | 0/0 | 0 | 0 |
| 32MB | 46 | 20 | [46, 19, 20, 20, 20] | 2.01x | 860 | 24MB | 0MB | 0/0 | 0 | 0 |
| 64MB | 49 | 20 | [49, 20, 20, 20, 20] | 1.99x | 860 | 24MB | 0MB | 0/0 | 0 | 0 |
| 128MB | 44 | 22 | [44, 21, 20, 26, 20] | 1.83x | 860 | 24MB | 0MB | 0/0 | 0 | 0 |
| 256MB | 46 | 20 | [46, 20, 21, 20, 21] | 1.94x | 860 | 24MB | 0MB | 0/0 | 0 | 0 |
| 384MB | 44 | 20 | [44, 19, 20, 21, 20] | 1.99x | 860 | 24MB | 0MB | 0/0 | 0 | 0 |
| 512MB | 45 | 20 | [45, 21, 20, 20, 20] | 1.96x | 860 | 24MB | 0MB | 0/0 | 0 | 0 |
| 768MB | 46 | 20 | [46, 20, 20, 19, 20] | 2.01x | 860 | 24MB | 0MB | 0/0 | 0 | 0 |
| 1024MB | 49 | 21 | [49, 20, 20, 24, 21] | 1.87x | 860 | 24MB | 0MB | 0/0 | 0 | 0 |
| 2048MB | 48 | 20 | [48, 20, 19, 20, 21] | 1.99x | 860 | 24MB | 0MB | 0/0 | 0 | 0 |

### Cache Stats (last iteration, per config)

<details>
<summary>8MB cache stats (hot)</summary>

```
Cache: entries=860, mem=7MB, disk=7MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=409, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=53
Time: 192ms
```
</details>

<details>
<summary>16MB cache stats (hot)</summary>

```
Cache: entries=860, mem=15MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 21ms
```
</details>

<details>
<summary>32MB cache stats (hot)</summary>

```
Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

<details>
<summary>64MB cache stats (hot)</summary>

```
Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

<details>
<summary>128MB cache stats (hot)</summary>

```
Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

<details>
<summary>256MB cache stats (hot)</summary>

```
Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 21ms
```
</details>

<details>
<summary>384MB cache stats (hot)</summary>

```
Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

<details>
<summary>512MB cache stats (hot)</summary>

```
Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

<details>
<summary>768MB cache stats (hot)</summary>

```
Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 20ms
```
</details>

<details>
<summary>1024MB cache stats (hot)</summary>

```
Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 21ms
```
</details>

<details>
<summary>2048MB cache stats (hot)</summary>

```
Cache: entries=860, mem=24MB, disk=0MB
  Hits: cache_hit=184, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 21ms
```
</details>

### Flamegraphs

- **8MB:** 5 flamegraphs in `flamegraphs/q40_8mb/`
- **16MB:** 5 flamegraphs in `flamegraphs/q40_16mb/`
- **32MB:** 5 flamegraphs in `flamegraphs/q40_32mb/`
- **64MB:** 5 flamegraphs in `flamegraphs/q40_64mb/`
- **128MB:** 5 flamegraphs in `flamegraphs/q40_128mb/`
- **256MB:** 5 flamegraphs in `flamegraphs/q40_256mb/`
- **384MB:** 5 flamegraphs in `flamegraphs/q40_384mb/`
- **512MB:** 5 flamegraphs in `flamegraphs/q40_512mb/`
- **768MB:** 5 flamegraphs in `flamegraphs/q40_768mb/`
- **1024MB:** 5 flamegraphs in `flamegraphs/q40_1024mb/`
- **2048MB:** 5 flamegraphs in `flamegraphs/q40_2048mb/`

---

## Q42

```sql
SELECT DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) AS M, COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-14' AND "EventDate"::INT::DATE <= '2013-07-15' AND "IsRefresh" = 0 AND "DontCountHits" = 0 GROUP BY DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) ORDER BY DATE_TRUNC('minute', M) LIMIT 10 OFFSET 1000;
```

**Pushdown baseline:** 32ms

### Performance vs Memory Budget

| Budget | Cold (ms) | Hot avg (ms) | All iters | Speedup | Entries | Mem | Disk | IO r/w | eval_pred | cache_hit |
|--------|-----------|-------------|-----------|---------|---------|-----|------|--------|-----------|----------|
| 8MB | 39 | 18 | [39, 20, 18, 18, 18] | 1.74x | 688 | 7MB | 0MB | 0/0 | 0 | 0 |
| 16MB | 39 | 18 | [39, 18, 18, 18, 19] | 1.77x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |
| 32MB | 39 | 18 | [39, 18, 18, 19, 18] | 1.77x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |
| 64MB | 42 | 19 | [42, 20, 20, 18, 18] | 1.70x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |
| 128MB | 38 | 18 | [38, 18, 18, 18, 18] | 1.79x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |
| 256MB | 39 | 20 | [39, 18, 18, 24, 18] | 1.65x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |
| 384MB | 39 | 19 | [39, 20, 19, 18, 18] | 1.72x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |
| 512MB | 43 | 18 | [43, 20, 18, 18, 18] | 1.74x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |
| 768MB | 39 | 18 | [39, 18, 18, 20, 18] | 1.74x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |
| 1024MB | 43 | 18 | [43, 20, 18, 18, 18] | 1.74x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |
| 2048MB | 43 | 18 | [43, 18, 18, 18, 18] | 1.79x | 688 | 13MB | 0MB | 0/0 | 0 | 0 |

### Cache Stats (last iteration, per config)

<details>
<summary>8MB cache stats (hot)</summary>

```
Cache: entries=688, mem=7MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>16MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 19ms
```
</details>

<details>
<summary>32MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>64MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>128MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>256MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>384MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>512MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>768MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>1024MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

<details>
<summary>2048MB cache stats (hot)</summary>

```
Cache: entries=688, mem=13MB, disk=0MB
  Hits: cache_hit=0, eval_predicate=540
  Misses: cache_miss=0
  IO: read=0, write=0
  Squeeze: squeezed_success=0, squeezed_needs_io=0
Time: 18ms
```
</details>

### Flamegraphs

- **8MB:** 5 flamegraphs in `flamegraphs/q42_8mb/`
- **16MB:** 5 flamegraphs in `flamegraphs/q42_16mb/`
- **32MB:** 5 flamegraphs in `flamegraphs/q42_32mb/`
- **64MB:** 5 flamegraphs in `flamegraphs/q42_64mb/`
- **128MB:** 5 flamegraphs in `flamegraphs/q42_128mb/`
- **256MB:** 5 flamegraphs in `flamegraphs/q42_256mb/`
- **384MB:** 5 flamegraphs in `flamegraphs/q42_384mb/`
- **512MB:** 5 flamegraphs in `flamegraphs/q42_512mb/`
- **768MB:** 5 flamegraphs in `flamegraphs/q42_768mb/`
- **1024MB:** 5 flamegraphs in `flamegraphs/q42_1024mb/`
- **2048MB:** 5 flamegraphs in `flamegraphs/q42_2048mb/`

