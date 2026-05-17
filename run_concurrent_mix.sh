#!/bin/bash
set -e

# Concurrent Mixed Query Benchmark — Numeric Filter Cache Performance
# --------------------------------------------------------------------
# Goal: Measure numeric filter cache perf under contention.
# Light queries exercise the numeric cache path (filters, predicates, aggs on numeric cols).
# Heavy queries cause memory pressure / spill and compete for CPU.
# Expected: squeezed liquid cache keeps light queries fast despite contention.
#
# ============================================================
# LIGHTWEIGHT QUERIES (manifest_light.json) — numeric filter cache beneficiaries
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
#
# ============================================================
# HEAVYWEIGHT QUERIES (manifest_heavy.json) — spill-inducing, NOT cache beneficiaries
# ============================================================
#
# idx 0  q4:   SELECT COUNT(DISTINCT "UserID") FROM hits;
# idx 1  q5:   SELECT COUNT(DISTINCT "SearchPhrase") FROM hits;
# idx 2  q15:  SELECT "UserID", COUNT(*) FROM hits GROUP BY "UserID" ORDER BY COUNT(*) DESC LIMIT 10;
# idx 3  q8:   SELECT "RegionID", COUNT(DISTINCT "UserID") FROM hits GROUP BY "RegionID" ORDER BY u DESC LIMIT 10;
# idx 4  q32:  SELECT "WatchID", "ClientIP", COUNT(*), SUM("IsRefresh"), AVG("ResolutionWidth") FROM hits GROUP BY "WatchID", "ClientIP" ORDER BY c DESC LIMIT 10;
# idx 5  q33:  SELECT "URL", COUNT(*) AS c FROM hits GROUP BY "URL" ORDER BY c DESC LIMIT 10;
# idx 6  c5:   SELECT "CounterID", SUM("AdvEngineID"), AVG("ResolutionWidth"), MIN/MAX("ClientIP"), COUNT(*) FROM hits WHERE "IsRefresh" = 0 GROUP BY "CounterID" HAVING COUNT(*)>100 ORDER BY COUNT(*) DESC LIMIT 50;

LIGHT_MANIFEST="benchmark/clickbench/manifest_light.json"
HEAVY_MANIFEST="benchmark/clickbench/manifest_heavy.json"
MAX_MEMORY_MB=${1:-4096}
ITERATIONS=5
OUTPUT_DIR="outputs/concurrent_mix"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/flamegraphs"

echo "============================================================"
echo "  Numeric Cache Concurrent Mix Benchmark"
echo "  Max memory: ${MAX_MEMORY_MB}MB"
echo "  Iterations: $ITERATIONS"
echo "============================================================"
echo ""

# Build once
echo ">>> Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# ============================================================
# Phase 1: DataFusion baseline (no liquid cache)
# ============================================================
echo ">>> Phase 1: DataFusion baseline (no cache)..."
echo -n "  Light queries..."
timeout 600 target/release/in_process \
    --manifest "$LIGHT_MANIFEST" \
    --bench-mode datafusion-default \
    --iteration $ITERATIONS \
    --output "$OUTPUT_DIR/datafusion_baseline.json" > "$OUTPUT_DIR/datafusion_baseline.log" 2>&1 && echo " done" || echo " FAILED"
echo ""

# ============================================================
# Phase 2: Warm cache then measure cache-hot baseline
# ============================================================
echo ">>> Phase 2: Warm cache + cache-hot baseline..."
echo -n "  Warming..."
timeout 600 target/release/in_process \
    --manifest "$LIGHT_MANIFEST" \
    --bench-mode liquid \
    --max-memory-mb $MAX_MEMORY_MB \
    --iteration 1 \
    --explain-analyze \
    --output "$OUTPUT_DIR/warmup.json" > "$OUTPUT_DIR/warmup.log" 2>&1 && echo " done" || echo " FAILED"

echo -n "  Cache-hot baseline..."
timeout 600 target/release/in_process \
    --manifest "$LIGHT_MANIFEST" \
    --bench-mode liquid \
    --max-memory-mb $MAX_MEMORY_MB \
    --iteration $ITERATIONS \
    --explain-analyze \
    --flamegraph-dir "$OUTPUT_DIR/flamegraphs/baseline" \
    --output "$OUTPUT_DIR/baseline_light.json" > "$OUTPUT_DIR/baseline_light.log" 2>&1 && echo " done" || echo " FAILED"
echo ""

# ============================================================
# Phase 3: Heavy queries alone (establish spill baseline)
# ============================================================
echo ">>> Phase 3: Heavy queries alone..."
NUM_HEAVY=$(python3 -c "import json; print(len(json.load(open('$HEAVY_MANIFEST'))['queries']))")
for idx in $(seq 0 $((NUM_HEAVY - 1))); do
    echo -n "  Heavy idx ${idx}..."
    timeout 600 target/release/in_process \
        --manifest "$HEAVY_MANIFEST" \
        --bench-mode liquid \
        --max-memory-mb $MAX_MEMORY_MB \
        --iteration 1 \
        --query-index $idx \
        --output "$OUTPUT_DIR/heavy_alone_idx${idx}.json" > "$OUTPUT_DIR/heavy_alone_idx${idx}.log" 2>&1 && echo " done" || echo " FAILED/TIMEOUT"
done
echo ""

# ============================================================
# Phase 4: Concurrent — heavy background + light foreground
# ============================================================
echo ">>> Phase 4: Concurrent mix (heavy bg + light fg)..."
for idx in $(seq 0 $((NUM_HEAVY - 1))); do
    echo -n "  Heavy idx ${idx} bg + light fg..."

    # Launch heavy in background
    target/release/in_process \
        --manifest "$HEAVY_MANIFEST" \
        --bench-mode liquid \
        --max-memory-mb $MAX_MEMORY_MB \
        --iteration 1 \
        --query-index $idx \
        --output "$OUTPUT_DIR/concurrent_heavy_idx${idx}.json" > "$OUTPUT_DIR/concurrent_heavy_idx${idx}.log" 2>&1 &
    HEAVY_PID=$!

    # Run light queries in foreground while heavy runs
    timeout 600 target/release/in_process \
        --manifest "$LIGHT_MANIFEST" \
        --bench-mode liquid \
        --max-memory-mb $MAX_MEMORY_MB \
        --iteration 1 \
        --explain-analyze \
        --flamegraph-dir "$OUTPUT_DIR/flamegraphs/concurrent_heavy${idx}" \
        --output "$OUTPUT_DIR/concurrent_light_during_heavy${idx}.json" > "$OUTPUT_DIR/concurrent_light_during_heavy${idx}.log" 2>&1 || true

    wait $HEAVY_PID 2>/dev/null || true
    echo " done"
done
echo ""

# ============================================================
# Phase 5: Generate report
# ============================================================
echo ">>> Generating report..."
python3 - "$OUTPUT_DIR" "$ITERATIONS" "$LIGHT_MANIFEST" "$HEAVY_MANIFEST" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
iterations = int(sys.argv[2])
light_manifest = sys.argv[3]
heavy_manifest = sys.argv[4]

with open(light_manifest) as f:
    light_queries = json.load(f)["queries"]
with open(heavy_manifest) as f:
    heavy_queries = json.load(f)["queries"]

num_light = len(light_queries)
num_heavy = len(heavy_queries)

def load_results(filepath):
    """Load all query results from a benchmark output."""
    try:
        with open(filepath) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None

def get_query_times(data, query_idx=None):
    """Get time_millis for a query (or all queries). Returns list of per-iteration times."""
    if data is None:
        return []
    results = data.get("results", [])
    if query_idx is not None:
        if query_idx >= len(results):
            return []
        return [r["time_millis"] for r in results[query_idx]["iteration_results"]]
    # All queries, return list of hot-avg per query
    out = []
    for qr in results:
        times = [r["time_millis"] for r in qr["iteration_results"]]
        hot = times[1:] if len(times) > 1 else times
        out.append(sum(hot) / len(hot) if hot else 0)
    return out

def get_cache_stats_last(data, query_idx=0):
    """Get cache_stats from last iteration of a query."""
    try:
        results = data["results"][query_idx]["iteration_results"]
        return results[-1].get("cache_stats")
    except (TypeError, KeyError, IndexError):
        return None

# Load data
df_baseline = load_results(f"{output_dir}/datafusion_baseline.json")
baseline_light = load_results(f"{output_dir}/baseline_light.json")
concurrent_lights = {}
for idx in range(num_heavy):
    concurrent_lights[idx] = load_results(f"{output_dir}/concurrent_light_during_heavy{idx}.json")

# Generate report
report_path = f"{output_dir}/report.md"
with open(report_path, "w") as f:
    f.write("# Numeric Filter Cache — Concurrent Mix Benchmark\n\n")
    f.write("## Configuration\n\n")
    f.write("| Parameter | Value |\n|---|---|\n")
    f.write(f"| Iterations | {iterations} |\n")
    f.write("| Cache policy | S3-FIFO (LiquidPolicy) |\n")
    f.write("| Squeeze policy | TranscodeSqueezeEvict |\n")
    f.write("| Hydration | NoHydration |\n")
    f.write("| Strategy | Numeric predicate-only caching |\n\n")

    # Summary table: per light query, compare baseline vs concurrent vs datafusion
    f.write("## Per-Query Latency Comparison\n\n")
    f.write("| Query | DataFusion (ms) | Cache baseline (ms) | ")
    for idx in range(num_heavy):
        f.write(f"During heavy{idx} (ms) | ")
    f.write("Max regression | Speedup vs DF |\n")

    f.write("|-------|-----------------|--------------------| ")
    for _ in range(num_heavy):
        f.write("---| ")
    f.write("---| ---|\n")

    for qi in range(num_light):
        qname = os.path.basename(light_queries[qi]).replace(".sql", "")

        # DataFusion baseline
        df_times = get_query_times(df_baseline, qi) if df_baseline else []
        df_hot = df_times[1:] if len(df_times) > 1 else df_times
        df_avg = sum(df_hot) / len(df_hot) if df_hot else 0

        # Cache-hot baseline
        bl_times = get_query_times(baseline_light, qi) if baseline_light else []
        bl_hot = bl_times[1:] if len(bl_times) > 1 else bl_times
        bl_avg = sum(bl_hot) / len(bl_hot) if bl_hot else 0

        # Concurrent
        conc_avgs = []
        for idx in range(num_heavy):
            cd = concurrent_lights.get(idx)
            ct = get_query_times(cd, qi) if cd else []
            conc_avgs.append(ct[0] if ct else 0)

        max_conc = max(conc_avgs) if conc_avgs else 0
        regression = ((max_conc - bl_avg) / bl_avg * 100) if bl_avg > 0 else 0
        speedup = df_avg / bl_avg if bl_avg > 0 else 0

        f.write(f"| {qname} | {df_avg:.0f} | {bl_avg:.0f} | ")
        for ca in conc_avgs:
            f.write(f"{ca:.0f} | ")
        f.write(f"{regression:+.0f}% | {speedup:.2f}x |\n")

    # Cache stats summary
    f.write("\n## Cache Stats (baseline, last iteration)\n\n")
    f.write("| Query | Entries | Mem (MB) | Disk (MB) | cache_hit | eval_predicate | squeezed_success |\n")
    f.write("|-------|---------|----------|-----------|-----------|----------------|------------------|\n")
    for qi in range(num_light):
        qname = os.path.basename(light_queries[qi]).replace(".sql", "")
        stats = get_cache_stats_last(baseline_light, qi)
        if stats:
            rt = stats.get("runtime", {})
            f.write(f"| {qname} | {stats.get('total_entries', 0)} | "
                    f"{stats.get('memory_usage_bytes', 0)//(1024*1024)} | "
                    f"{stats.get('disk_usage_bytes', 0)//(1024*1024)} | "
                    f"{rt.get('cache_hit', 0)} | "
                    f"{rt.get('eval_predicate', 0)} | "
                    f"{rt.get('get_squeezed_success', 0)} |\n")
        else:
            f.write(f"| {qname} | - | - | - | - | - | - |\n")

    f.write("\n## Key Findings\n\n")
    f.write("- **Numeric cache baseline vs DataFusion:** Shows benefit of caching numeric predicates\n")
    f.write("- **Concurrent regression:** How much light queries slow down when heavy queries compete\n")
    f.write("- **Expected:** Low regression = squeezed numeric data stays hot in cache, independent of spill pressure\n")

print(f"Report: {report_path}")

# Console summary
print("\n" + "=" * 80)
print("  CONCURRENT MIX SUMMARY")
print("=" * 80)

if baseline_light and df_baseline:
    print(f"\n  {'Query':<25}{'DF(ms)':<10}{'Cache(ms)':<12}{'Speedup':<10}{'Max conc(ms)':<14}{'Regression'}")
    print(f"  {'-'*75}")
    for qi in range(num_light):
        qname = os.path.basename(light_queries[qi]).replace(".sql", "")[:24]
        df_times = get_query_times(df_baseline, qi)
        df_hot = df_times[1:] if len(df_times) > 1 else df_times
        df_avg = sum(df_hot) / len(df_hot) if df_hot else 0

        bl_times = get_query_times(baseline_light, qi)
        bl_hot = bl_times[1:] if len(bl_times) > 1 else bl_times
        bl_avg = sum(bl_hot) / len(bl_hot) if bl_hot else 0

        conc_avgs = []
        for idx in range(num_heavy):
            cd = concurrent_lights.get(idx)
            ct = get_query_times(cd, qi) if cd else []
            conc_avgs.append(ct[0] if ct else 0)
        max_conc = max(conc_avgs) if conc_avgs else 0
        regression = ((max_conc - bl_avg) / bl_avg * 100) if bl_avg > 0 else 0
        speedup = df_avg / bl_avg if bl_avg > 0 else 0

        print(f"  {qname:<25}{df_avg:<10.0f}{bl_avg:<12.0f}{speedup:<10.2f}{max_conc:<14.0f}{regression:+.0f}%")

print("\n" + "=" * 80)
PYEOF

echo ""
echo "=== Done! ==="
echo "  Report: $OUTPUT_DIR/report.md"
echo "  Flamegraphs: $OUTPUT_DIR/flamegraphs/"
