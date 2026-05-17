#!/bin/bash
set -e

# Concurrent Mixed Query Benchmark — Numeric Filter Cache Performance
# --------------------------------------------------------------------
# Goal: Measure numeric filter cache perf under contention.
# Light queries exercise the numeric cache path (filters, predicates, aggs on numeric cols).
# Heavy queries cause memory pressure / spill and compete for CPU.
# Expected: squeezed liquid cache keeps light queries fast despite contention.

LIGHT_MANIFEST="benchmark/clickbench/manifest_light.json"
HEAVY_MANIFEST="benchmark/clickbench/manifest_heavy.json"
OUTPUT_DIR="outputs/concurrent_mix"
CACHE_DIR="benchmark/data/cache"
MAX_MEMORY_MB=${1:-4096}
ITERATIONS=3

mkdir -p "$OUTPUT_DIR"

echo "=============================================="
echo "Numeric Filter Cache — Concurrent Mix Benchmark"
echo "Max memory: ${MAX_MEMORY_MB}MB"
echo "=============================================="

# ============================================================
# LIGHTWEIGHT QUERIES (manifest_light.json)
# All use numeric filters/predicates — exercise the cache.
# ============================================================
#
# idx 0  c0_range_filter:
#         SELECT COUNT(*) FROM hits
#         WHERE "AdvEngineID" > 0 AND "ResolutionWidth" >= 1024 AND "ResolutionWidth" <= 1920;
#
# idx 1  c1_multi_numeric_pred:
#         SELECT COUNT(*), AVG("ResolutionWidth"), SUM("AdvEngineID") FROM hits
#         WHERE "IsRefresh" = 0 AND "DontCountHits" = 0 AND "CounterID" > 100 AND "CounterID" < 500;
#
# idx 2  c2_point_lookups:
#         SELECT "UserID", "CounterID", "RegionID" FROM hits
#         WHERE "CounterID" = 62 AND "RegionID" = 229 AND "IsRefresh" = 0 LIMIT 100;
#
# idx 3  c3_numeric_group_filter:
#         SELECT "RegionID", COUNT(*), AVG("ResolutionWidth") FROM hits
#         WHERE "AdvEngineID" > 0 AND "IsRefresh" = 0
#         GROUP BY "RegionID" ORDER BY COUNT(*) DESC LIMIT 20;
#
# idx 4  c4_date_range_agg:
#         SELECT "EventDate"::INT::DATE, COUNT(*), SUM("IsRefresh"), AVG("ResolutionWidth") FROM hits
#         WHERE "EventDate"::INT::DATE >= '2013-07-01' AND "EventDate"::INT::DATE <= '2013-07-15'
#           AND "CounterID" > 0
#         GROUP BY "EventDate"::INT::DATE ORDER BY "EventDate"::INT::DATE;
#
# idx 5  c6_selective_numeric:
#         SELECT "UserID", "RegionID", "CounterID" FROM hits
#         WHERE "CounterID" = 62 AND "EventDate"::INT::DATE = '2013-07-15'
#           AND "DontCountHits" = 0 AND "IsRefresh" = 0 AND "TraficSourceID" IN (-1, 6)
#         LIMIT 50;
#
# idx 6  c7_wide_numeric_scan:
#         SELECT AVG("ResolutionWidth"), AVG("ResolutionHeight"), AVG("ClientIP"),
#                AVG("WindowClientWidth"), AVG("WindowClientHeight"), AVG("CounterID"), AVG("RegionID")
#         FROM hits WHERE "AdvEngineID" = 0 AND "IsRefresh" = 0;
#
# idx 7  q1:
#         SELECT COUNT(*) FROM hits WHERE "AdvEngineID" <> 0;
#
# idx 8  q7:
#         SELECT "AdvEngineID", COUNT(*) FROM hits
#         WHERE "AdvEngineID" <> 0 GROUP BY "AdvEngineID" ORDER BY COUNT(*) DESC;
#
# idx 9  q40:
#         SELECT "URLHash", "EventDate"::INT::DATE, COUNT(*) FROM hits
#         WHERE "CounterID" = 62 AND "EventDate" >= '2013-07-01' AND <= '2013-07-31'
#           AND "IsRefresh" = 0 AND "TraficSourceID" IN (-1, 6)
#           AND "RefererHash" = 3594120000172545465
#         GROUP BY "URLHash", "EventDate"::INT::DATE ORDER BY ... LIMIT 10 OFFSET 100;
#
# idx 10 q41:
#         SELECT "WindowClientWidth", "WindowClientHeight", COUNT(*) FROM hits
#         WHERE "CounterID" = 62 AND date range AND "IsRefresh" = 0 AND "DontCountHits" = 0
#           AND "URLHash" = 2868770270353813622
#         GROUP BY ... LIMIT 10 OFFSET 10000;
#
# idx 11 q42:
#         SELECT DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) AS M, COUNT(*) FROM hits
#         WHERE "CounterID" = 62 AND "EventDate" between '2013-07-14' and '2013-07-15'
#           AND "IsRefresh" = 0 AND "DontCountHits" = 0
#         GROUP BY M ORDER BY M LIMIT 10 OFFSET 1000;

# ============================================================
# HEAVYWEIGHT QUERIES (manifest_heavy.json)
# These trigger spill / compete for memory. NOT numeric cache beneficiaries.
# ============================================================
#
# idx 0  q4:
#         SELECT COUNT(DISTINCT "UserID") FROM hits;
#         → ~17M distinct values, huge hash table
#
# idx 1  q5:
#         SELECT COUNT(DISTINCT "SearchPhrase") FROM hits;
#         → massive string hash table
#
# idx 2  q15:
#         SELECT "UserID", COUNT(*) FROM hits GROUP BY "UserID" ORDER BY COUNT(*) DESC LIMIT 10;
#         → GROUP BY on 17M unique UserIDs
#
# idx 3  q8:
#         SELECT "RegionID", COUNT(DISTINCT "UserID") AS u FROM hits GROUP BY "RegionID" ORDER BY u DESC LIMIT 10;
#         → DISTINCT inside GROUP BY, high memory
#
# idx 4  q32:
#         SELECT "WatchID", "ClientIP", COUNT(*) AS c, SUM("IsRefresh"), AVG("ResolutionWidth")
#         FROM hits GROUP BY "WatchID", "ClientIP" ORDER BY c DESC LIMIT 10;
#         → Cartesian-ish GROUP BY on two high-cardinality cols
#
# idx 5  q33:
#         SELECT "URL", COUNT(*) AS c FROM hits GROUP BY "URL" ORDER BY c DESC LIMIT 10;
#         → GROUP BY on huge string column
#
# idx 6  c5_heavy_numeric_agg:
#         SELECT "CounterID", SUM("AdvEngineID"), AVG("ResolutionWidth"), MIN("ClientIP"),
#                MAX("ClientIP"), COUNT(*) FROM hits
#         WHERE "IsRefresh" = 0 GROUP BY "CounterID" HAVING COUNT(*) > 100
#         ORDER BY COUNT(*) DESC LIMIT 50;
#         → Many numeric aggs but high-cardinality GROUP BY → large hash table

# ============================================================
# Phase 1: Warm cache with light queries
# ============================================================
echo ""
echo "=== Phase 1: Warm numeric cache ==="
cargo run --release --bin in_process -- \
  --manifest "$LIGHT_MANIFEST" \
  --bench-mode liquid \
  --max-memory-mb "$MAX_MEMORY_MB" \
  --iteration 1 \
  --cache-dir "$CACHE_DIR" \
  --explain-analyze \
  --output "$OUTPUT_DIR/warmup.json" \
  2>/dev/null
echo "  Cache warmed."

# ============================================================
# Phase 2: Light queries alone — numeric cache hit baseline
# ============================================================
echo ""
echo "=== Phase 2: Light queries (cache-hot, no contention) ==="
cargo run --release --bin in_process -- \
  --manifest "$LIGHT_MANIFEST" \
  --bench-mode liquid \
  --max-memory-mb "$MAX_MEMORY_MB" \
  --iteration "$ITERATIONS" \
  --cache-dir "$CACHE_DIR" \
  --explain-analyze \
  --output "$OUTPUT_DIR/baseline_light.json" \
  2>/dev/null
echo "  Done."

# ============================================================
# Phase 3: Concurrent — heavy in background, light in foreground
# ============================================================
echo ""
echo "=== Phase 3: Concurrent (heavy background + light foreground) ==="

NUM_HEAVY=$(python3 -c "import json; print(len(json.load(open('$HEAVY_MANIFEST'))['queries']))")

for heavy_idx in $(seq 0 $((NUM_HEAVY - 1))); do
  echo "  Starting heavy idx ${heavy_idx} in background..."
  cargo run --release --bin in_process -- \
    --manifest "$HEAVY_MANIFEST" \
    --bench-mode liquid \
    --max-memory-mb "$MAX_MEMORY_MB" \
    --iteration 1 \
    --query-index "$heavy_idx" \
    --cache-dir "$CACHE_DIR" \
    --output "$OUTPUT_DIR/concurrent_heavy_idx${heavy_idx}.json" \
    2>/dev/null &
  HEAVY_PID=$!

  # Run all light queries while heavy is active
  cargo run --release --bin in_process -- \
    --manifest "$LIGHT_MANIFEST" \
    --bench-mode liquid \
    --max-memory-mb "$MAX_MEMORY_MB" \
    --iteration 1 \
    --cache-dir "$CACHE_DIR" \
    --explain-analyze \
    --output "$OUTPUT_DIR/concurrent_light_during_heavy_idx${heavy_idx}.json" \
    2>/dev/null

  wait $HEAVY_PID 2>/dev/null || true
  echo "  Heavy idx ${heavy_idx} finished."
done

# ============================================================
# Phase 4: DataFusion baseline (no liquid cache)
# ============================================================
echo ""
echo "=== Phase 4: DataFusion baseline (no numeric cache) ==="
cargo run --release --bin in_process -- \
  --manifest "$LIGHT_MANIFEST" \
  --bench-mode datafusion-default \
  --iteration "$ITERATIONS" \
  --output "$OUTPUT_DIR/datafusion_baseline.json" \
  2>/dev/null
echo "  Done."

# ============================================================
# Summary
# ============================================================
echo ""
echo "=============================================="
echo "Done. Results in $OUTPUT_DIR/"
echo "=============================================="
echo ""
echo "Files:"
echo "  baseline_light.json                       — numeric cache, no contention"
echo "  concurrent_light_during_heavy_idx*.json   — numeric cache under pressure"
echo "  datafusion_baseline.json                  — no liquid cache"
echo ""
echo "Key metrics:"
echo "  - time_millis: latency of light queries"
echo "  - cache_stats.runtime.cache_hit / cache_miss"
echo "  - cache_stats.runtime.eval_predicate (numeric predicate from cache)"
echo "  - cache_stats.runtime.get_squeezed_success (served squeezed)"
