# Sweet Spot Analysis (LRU Policy): Memory Budget vs Performance

## Configuration

| Parameter | Value |
|---|---|
| Cache policy | **LRU** |
| Iterations | 5 |
| Squeeze policy | TranscodeSqueezeEvict |
| Hydration | NoHydration |
| Strategy | Numeric predicate-only caching |

---

## Q19

```sql
SELECT "UserID" FROM hits WHERE "UserID" = 435090932899640449;
```

**Pushdown baseline:** 81ms (min hot), all: [120, 87, 89, 82, 81]

### Performance Table (LRU)

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Speedup | Entries | Mem (MB) | Disk (MB) | Scan CPU (µs) | Zone |
|--------|--------------|--------|--------|--------|--------|---------|---------|---------|----------|-----------|---------------|------|
| 8MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 16MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 32MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 64MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 128MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 256MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 384MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 512MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 768MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 1024MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 2048MB | - | - | - | - | - | - | - | - | - | - | - | - |
| Pushdown | 120 | 87 | 89 | 82 | 81 | 81 | 1.00x | — | — | — | — | — |

---

## Q7

```sql
SELECT "AdvEngineID", COUNT(*) FROM hits WHERE "AdvEngineID" <> 0 GROUP BY "AdvEngineID" ORDER BY COUNT(*) DESC;
```

**Pushdown baseline:** 32ms (min hot), all: [64, 32, 32, 33, 33]

### Performance Table (LRU)

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Speedup | Entries | Mem (MB) | Disk (MB) | Scan CPU (µs) | Zone |
|--------|--------------|--------|--------|--------|--------|---------|---------|---------|----------|-----------|---------------|------|
| 8MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 16MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 32MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 64MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 128MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 256MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 384MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 512MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 768MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 1024MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 2048MB | - | - | - | - | - | - | - | - | - | - | - | - |
| Pushdown | 64 | 32 | 32 | 33 | 33 | 32 | 1.00x | — | — | — | — | — |

---

## Q40

```sql
SELECT "URLHash", "EventDate"::INT::DATE, COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-01' AND "EventDate"::INT::DATE <= '2013-07-31' AND "IsRefresh" = 0 AND "TraficSourceID" IN (-1, 6) AND "RefererHash" = 3594120000172545465 GROUP BY "URLHash", "EventDate"::INT::DATE ORDER BY PageViews DESC LIMIT 10 OFFSET 100;
```

**Pushdown baseline:** 38ms (min hot), all: [63, 40, 41, 38, 38]

### Performance Table (LRU)

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Speedup | Entries | Mem (MB) | Disk (MB) | Scan CPU (µs) | Zone |
|--------|--------------|--------|--------|--------|--------|---------|---------|---------|----------|-----------|---------------|------|
| 8MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 16MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 32MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 64MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 128MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 256MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 384MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 512MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 768MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 1024MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 2048MB | - | - | - | - | - | - | - | - | - | - | - | - |
| Pushdown | 63 | 40 | 41 | 38 | 38 | 38 | 1.00x | — | — | — | — | — |

---

## Q42

```sql
SELECT DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) AS M, COUNT(*) AS PageViews FROM hits WHERE "CounterID" = 62 AND "EventDate"::INT::DATE >= '2013-07-14' AND "EventDate"::INT::DATE <= '2013-07-15' AND "IsRefresh" = 0 AND "DontCountHits" = 0 GROUP BY DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) ORDER BY DATE_TRUNC('minute', M) LIMIT 10 OFFSET 1000;
```

**Pushdown baseline:** 30ms (min hot), all: [55, 32, 32, 36, 30]

### Performance Table (LRU)

| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Speedup | Entries | Mem (MB) | Disk (MB) | Scan CPU (µs) | Zone |
|--------|--------------|--------|--------|--------|--------|---------|---------|---------|----------|-----------|---------------|------|
| 8MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 16MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 32MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 64MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 128MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 256MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 384MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 512MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 768MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 1024MB | - | - | - | - | - | - | - | - | - | - | - | - |
| 2048MB | - | - | - | - | - | - | - | - | - | - | - | - |
| Pushdown | 55 | 32 | 32 | 36 | 30 | 30 | 1.00x | — | — | — | — | — |

