#!/bin/bash
set -e

# Concurrent Mixed Query Benchmark — Numeric Filter Cache Performance
# --------------------------------------------------------------------
# Runs light (numeric-filter) queries across multiple memory configs,
# both alone and under contention from heavy (spill-inducing) queries.
# Uses min(iterations) as the metric. Prints query SQL and explain-analyze.
#
# ============================================================
# LIGHTWEIGHT QUERIES (manifest_light.json) — numeric filter cache beneficiaries
# ============================================================
#
# idx 0  c0_range_filter:
#         SELECT COUNT(*) FROM hits
#         WHERE "AdvEngineID" > 0 AND "ResolutionWidth" >= 1024 AND "ResolutionWidth" <= 1920;
#         → Tests: range predicate on two numeric cols
#
# idx 1  c1_multi_numeric_pred:
#         SELECT COUNT(*), AVG("ResolutionWidth"), SUM("AdvEngineID") FROM hits
#         WHERE "IsRefresh" = 0 AND "DontCountHits" = 0 AND "CounterID" > 100 AND "CounterID" < 500;
#         → Tests: 4 numeric predicates combined, narrow band
#
# idx 2  c2_point_lookups:
#         SELECT "UserID", "CounterID", "RegionID" FROM hits
#         WHERE "CounterID" = 62 AND "RegionID" = 229 AND "IsRefresh" = 0 LIMIT 100;
#         → Tests: equality predicates, early termination via LIMIT
#
# idx 3  c3_numeric_group_filter:
#         SELECT "RegionID", COUNT(*), AVG("ResolutionWidth") FROM hits
#         WHERE "AdvEngineID" > 0 AND "IsRefresh" = 0
#         GROUP BY "RegionID" ORDER BY COUNT(*) DESC LIMIT 20;
#         → Tests: numeric filter + low-cardinality GROUP BY (~230 regions)
#
# idx 4  c4_date_range_agg:
#         SELECT "EventDate"::INT::DATE, COUNT(*), SUM("IsRefresh"), AVG("ResolutionWidth") FROM hits
#         WHERE "EventDate"::INT::DATE >= '2013-07-01' AND "EventDate"::INT::DATE <= '2013-07-15'
#           AND "CounterID" > 0
#         GROUP BY "EventDate"::INT::DATE ORDER BY "EventDate"::INT::DATE;
#         → Tests: date range filter, numeric aggs, low-card grouping (15 days)
#
# idx 5  c6_selective_numeric:
#         SELECT "UserID", "RegionID", "CounterID" FROM hits
#         WHERE "CounterID" = 62 AND "EventDate"::INT::DATE = '2013-07-15'
#           AND "DontCountHits" = 0 AND "IsRefresh" = 0 AND "TraficSourceID" IN (-1, 6)
#         LIMIT 50;
#         → Tests: highly selective multi-predicate, 5 numeric filters
#
# idx 6  c7_wide_numeric_scan:
#         SELECT AVG("ResolutionWidth"), AVG("ResolutionHeight"), AVG("ClientIP"),
#                AVG("WindowClientWidth"), AVG("WindowClientHeight"), AVG("CounterID"), AVG("RegionID")
#         FROM hits WHERE "AdvEngineID" = 0 AND "IsRefresh" = 0;
#         → Tests: 7 numeric col aggregation with 2 numeric filters (wide read)
#
# idx 7  q1:
#         SELECT COUNT(*) FROM hits WHERE "AdvEngineID" <> 0;
#         → Tests: single numeric inequality filter, full scan
#
# idx 8  q7:
#         SELECT "AdvEngineID", COUNT(*) FROM hits
#         WHERE "AdvEngineID" <> 0 GROUP BY "AdvEngineID" ORDER BY COUNT(*) DESC;
#         → Tests: numeric filter + tiny GROUP BY (~20 engine IDs)
#
# idx 9  q40:
#         SELECT "URLHash", "EventDate"::INT::DATE, COUNT(*) FROM hits
#         WHERE "CounterID" = 62 AND date range AND "IsRefresh" = 0
#           AND "TraficSourceID" IN (-1, 6) AND "RefererHash" = 3594120000172545465
#         GROUP BY "URLHash", "EventDate"::INT::DATE ORDER BY ... LIMIT 10 OFFSET 100;
#         → Tests: 5 numeric predicates, stats-pruned to ~3 row groups
#
# idx 10 q41:
#         SELECT "WindowClientWidth", "WindowClientHeight", COUNT(*) FROM hits
#         WHERE "CounterID" = 62 AND date range AND "IsRefresh" = 0 AND "DontCountHits" = 0
#           AND "URLHash" = 2868770270353813622
#         GROUP BY ... LIMIT 10 OFFSET 10000;
#         → Tests: 5 numeric predicates + hash equality, very selective
#
# idx 11 q42:
#         SELECT DATE_TRUNC('minute', to_timestamp_seconds("EventTime")) AS M, COUNT(*) FROM hits
#         WHERE "CounterID" = 62 AND "EventDate" between '2013-07-14' and '2013-07-15'
#           AND "IsRefresh" = 0 AND "DontCountHits" = 0
#         GROUP BY M ORDER BY M LIMIT 10 OFFSET 1000;
#         → Tests: narrow 2-day window, 4 numeric predicates, time-bucketed agg
#
# ============================================================
# HEAVYWEIGHT QUERIES (manifest_heavy.json) — spill-inducing, NOT cache beneficiaries
# ============================================================
#
# idx 0  q4:   SELECT COUNT(DISTINCT "UserID") FROM hits;
#              → ~17M distinct Int64 values, massive hash table
# idx 1  q15:  SELECT "UserID", COUNT(*) FROM hits GROUP BY "UserID" ORDER BY COUNT(*) DESC LIMIT 10;
#              → GROUP BY on 17M unique Int64 UserIDs
# idx 2  q8:   SELECT "RegionID", COUNT(DISTINCT "UserID") FROM hits GROUP BY "RegionID" ORDER BY u DESC LIMIT 10;
#              → DISTINCT inside GROUP BY, high memory (all numeric)
# idx 3  q32:  SELECT "WatchID", "ClientIP", COUNT(*), SUM("IsRefresh"), AVG("ResolutionWidth")
#              FROM hits GROUP BY "WatchID", "ClientIP" ORDER BY c DESC LIMIT 10;
#              → Cartesian GROUP BY on two high-cardinality numeric cols
# idx 4  c5:   SELECT "CounterID", SUM("AdvEngineID"), AVG("ResolutionWidth"), MIN/MAX("ClientIP"), COUNT(*)
#              FROM hits WHERE "IsRefresh" = 0 GROUP BY "CounterID" HAVING COUNT(*)>100
#              → high-cardinality numeric GROUP BY

LIGHT_MANIFEST="benchmark/clickbench/manifest_light.json"
HEAVY_MANIFEST="benchmark/clickbench/manifest_heavy.json"
MEMORY_CONFIGS="64 128 256 512 1024 2048"
ITERATIONS=5
OUTPUT_DIR="outputs/concurrent_mix"

# Query names for printing
LIGHT_NAMES=(
    "c0_range_filter"
    "c1_multi_numeric_pred"
    "c2_point_lookups"
    "c3_numeric_group_filter"
    "c4_date_range_agg"
    "c6_selective_numeric"
    "c7_wide_numeric_scan"
    "q1_advengine_ne0"
    "q7_group_advengine"
    "q40_multi_pred_selective"
    "q41_hash_equality"
    "q42_time_bucket"
)

HEAVY_NAMES=(
    "q4_count_distinct_userid"
    "q15_groupby_userid"
    "q8_distinct_in_groupby"
    "q32_cartesian_groupby"
    "c5_heavy_numeric_agg"
)

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/flamegraphs"

echo "============================================================"
echo "  🧪 Numeric Cache Concurrent Mix Benchmark"
echo "  💾 Memory configs: $MEMORY_CONFIGS MB"
echo "  🔁 Iterations: $ITERATIONS (report uses min)"
echo "============================================================"
echo ""

# Build once
echo "🔨 Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

NUM_LIGHT=${#LIGHT_NAMES[@]}
NUM_HEAVY=${#HEAVY_NAMES[@]}

# Print the SQL for each light query
echo "🪶 Light queries being tested:"
for qi in $(seq 0 $((NUM_LIGHT - 1))); do
    SQL_FILE=$(python3 -c "import json; print(json.load(open('$LIGHT_MANIFEST'))['queries'][$qi])")
    echo "  [$qi] ${LIGHT_NAMES[$qi]}:"
    echo "      $(cat "$SQL_FILE" | tr '\n' ' ')"
done
echo ""

echo "🏋️ Heavy queries (contention generators):"
for hi in $(seq 0 $((NUM_HEAVY - 1))); do
    SQL_FILE=$(python3 -c "import json; print(json.load(open('$HEAVY_MANIFEST'))['queries'][$hi])")
    echo "  [$hi] ${HEAVY_NAMES[$hi]}:"
    echo "      $(cat "$SQL_FILE" | tr '\n' ' ')"
done
echo ""

# ============================================================
# Phase 1: DataFusion baseline (no liquid cache, no memory constraint)
# ============================================================
echo "📊 Phase 1: DataFusion baseline (no cache)..."
for qi in $(seq 0 $((NUM_LIGHT - 1))); do
    echo -n "  🔹 [${qi}] ${LIGHT_NAMES[$qi]}..."
    timeout 600 target/release/in_process \
        --manifest "$LIGHT_MANIFEST" \
        --bench-mode datafusion-default \
        --iteration $ITERATIONS \
        --query-index $qi \
        --explain-analyze \
        --output "$OUTPUT_DIR/df_q${qi}.json" > "$OUTPUT_DIR/df_q${qi}.log" 2>&1 && echo " ✅" || echo " ❌ FAILED"
done
echo ""

# ============================================================
# Phase 2: Per-query, per-memory-config baseline (cache-hot, no contention)
# ============================================================
echo "🚀 Phase 2: Light queries across memory configs (no contention)..."
for MEM in $MEMORY_CONFIGS; do
    echo "  ═══ 💾 ${MEM}MB ═══"

    # Run each query individually for detailed per-query stats
    for qi in $(seq 0 $((NUM_LIGHT - 1))); do
        echo -n "    🔹 [${qi}] ${LIGHT_NAMES[$qi]} (${ITERATIONS} iters)..."
        FLAMEGRAPH_DIR="$OUTPUT_DIR/flamegraphs/light_q${qi}_${MEM}mb"
        mkdir -p "$FLAMEGRAPH_DIR"
        timeout 600 target/release/in_process \
            --manifest "$LIGHT_MANIFEST" \
            --bench-mode liquid \
            --max-memory-mb $MEM \
            --iteration $ITERATIONS \
            --query-index $qi \
            --explain-analyze \
            --flamegraph-dir "$FLAMEGRAPH_DIR" \
            --output "$OUTPUT_DIR/baseline_q${qi}_${MEM}mb.json" > "$OUTPUT_DIR/baseline_q${qi}_${MEM}mb.log" 2>&1 && echo " ✅" || echo " ❌ FAILED/TIMEOUT"
    done
    echo ""
done

# ============================================================
# Phase 3: Heavy queries alone (establish spill timing)
# ============================================================
echo "🏋️ Phase 3: Heavy queries alone (spill baseline)..."
for MEM in $MEMORY_CONFIGS; do
    echo "  ═══ 💾 ${MEM}MB ═══"
    for idx in $(seq 0 $((NUM_HEAVY - 1))); do
        echo -n "    🔸 [${idx}] ${HEAVY_NAMES[$idx]}..."
        timeout 900 target/release/in_process \
            --manifest "$HEAVY_MANIFEST" \
            --bench-mode liquid \
            --max-memory-mb $MEM \
            --iteration 1 \
            --query-index $idx \
            --explain-analyze \
            --output "$OUTPUT_DIR/heavy_alone_idx${idx}_${MEM}mb.json" > "$OUTPUT_DIR/heavy_alone_idx${idx}_${MEM}mb.log" 2>&1 && echo " ✅" || echo " ❌ FAILED/TIMEOUT"
    done
    echo ""
done

# ============================================================
# Phase 4: Concurrent — heavy background + light foreground per memory config
# ============================================================
echo "⚡ Phase 4: Concurrent mix (heavy bg + light fg)..."
for MEM in $MEMORY_CONFIGS; do
    echo "  ═══ 💾 ${MEM}MB ═══"

    for heavy_idx in $(seq 0 $((NUM_HEAVY - 1))); do
        echo -n "    🔸⚔️ [bg: ${HEAVY_NAMES[$heavy_idx]}] + all light fg..."

        # Launch heavy in background
        target/release/in_process \
            --manifest "$HEAVY_MANIFEST" \
            --bench-mode liquid \
            --max-memory-mb $MEM \
            --iteration 1 \
            --query-index $heavy_idx \
            --explain-analyze \
            --output "$OUTPUT_DIR/conc_heavy${heavy_idx}_${MEM}mb.json" > "$OUTPUT_DIR/conc_heavy${heavy_idx}_${MEM}mb.log" 2>&1 &
        HEAVY_PID=$!

        # Run all light queries in foreground with explain-analyze
        timeout 600 target/release/in_process \
            --manifest "$LIGHT_MANIFEST" \
            --bench-mode liquid \
            --max-memory-mb $MEM \
            --iteration 1 \
            --explain-analyze \
            --output "$OUTPUT_DIR/conc_light_during_heavy${heavy_idx}_${MEM}mb.json" > "$OUTPUT_DIR/conc_light_during_heavy${heavy_idx}_${MEM}mb.log" 2>&1 || true

        wait $HEAVY_PID 2>/dev/null || true
        echo " ✅"
    done
    echo ""
done

# ============================================================
# Phase 5: Generate detailed report (uses min of iterations)
# ============================================================
echo "📝 Generating detailed report..."
python3 - "$OUTPUT_DIR" "$ITERATIONS" "$LIGHT_MANIFEST" "$HEAVY_MANIFEST" "$MEMORY_CONFIGS" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
iterations = int(sys.argv[2])
light_manifest_path = sys.argv[3]
heavy_manifest_path = sys.argv[4]
memory_configs = [int(x) for x in sys.argv[5].split()]

with open(light_manifest_path) as f:
    light_data = json.load(f)
    light_queries = light_data["queries"]
with open(heavy_manifest_path) as f:
    heavy_data = json.load(f)
    heavy_queries = heavy_data["queries"]

num_light = len(light_queries)
num_heavy = len(heavy_queries)

light_names = [
    "c0_range_filter",
    "c1_multi_numeric_pred",
    "c2_point_lookups",
    "c3_numeric_group_filter",
    "c4_date_range_agg",
    "c6_selective_numeric",
    "c7_wide_numeric_scan",
    "q1_advengine_ne0",
    "q7_group_advengine",
    "q40_multi_pred_selective",
    "q41_hash_equality",
    "q42_time_bucket",
]

light_purposes = [
    "Range filter on 2 numeric cols",
    "4 numeric predicates, narrow band",
    "Equality predicates + early termination",
    "Numeric filter + low-card GROUP BY (~230 groups)",
    "Date range + numeric aggs, 15 groups",
    "Highly selective, 5 combined numeric filters",
    "Wide numeric read, 7 cols aggregated",
    "Single numeric inequality, full scan",
    "Numeric filter + tiny GROUP BY (~20 groups)",
    "5 numeric predicates, stats-pruned to ~3 RGs",
    "5 numeric predicates + hash equality, very selective",
    "4 numeric predicates, narrow 2-day window, time-bucketed",
]

heavy_names = [
    "q4_count_distinct_userid",
    "q15_groupby_userid",
    "q8_distinct_in_groupby",
    "q32_cartesian_groupby",
    "c5_heavy_numeric_agg",
]

heavy_purposes = [
    "17M distinct Int64 values hash table",
    "GROUP BY on 17M unique Int64 UserIDs",
    "DISTINCT inside GROUP BY, all numeric",
    "Cartesian GROUP BY on two high-cardinality numeric cols",
    "High-cardinality numeric GROUP BY",
]

def load_json(filepath):
    try:
        with open(filepath) as f:
            return json.load(f)
    except:
        return None

def get_times(data, query_idx=0):
    """Get all time_millis for a query."""
    try:
        return [r["time_millis"] for r in data["results"][query_idx]["iteration_results"]]
    except:
        return []

def hot_min(times):
    """Min of hot iterations (skip first cold run)."""
    hot = times[1:] if len(times) > 1 else times
    return min(hot) if hot else 0

def get_cache_stats(data, query_idx=0):
    try:
        results = data["results"][query_idx]["iteration_results"]
        return results[-1].get("cache_stats")
    except:
        return None

# ================================================================
# Write detailed report
# ================================================================
report_path = f"{output_dir}/detailed_report.md"
with open(report_path, "w") as f:
    f.write("# Numeric Filter Cache — Concurrent Mix Detailed Report\n\n")
    f.write("## Configuration\n\n")
    f.write("| Parameter | Value |\n|---|---|\n")
    f.write(f"| Memory configs | {memory_configs} MB |\n")
    f.write(f"| Iterations | {iterations} (metric: min of hot runs) |\n")
    f.write("| Cache policy | S3-FIFO (LiquidPolicy) |\n")
    f.write("| Squeeze policy | TranscodeSqueezeEvict |\n")
    f.write("| Hydration | NoHydration |\n")
    f.write("| Strategy | Numeric predicate-only caching |\n\n")

    # --- Per light query detailed section ---
    f.write("---\n\n## Per-Query Analysis\n\n")

    for qi in range(num_light):
        name = light_names[qi] if qi < len(light_names) else f"q{qi}"
        purpose = light_purposes[qi] if qi < len(light_purposes) else ""
        sql_path = light_queries[qi]
        try:
            with open(sql_path) as sq:
                sql = sq.read().strip()
        except:
            sql = "N/A"

        f.write(f"### [{qi}] {name}\n\n")
        f.write(f"**Purpose:** {purpose}\n\n")
        f.write(f"```sql\n{sql}\n```\n\n")

        # DataFusion baseline
        df_data = load_json(f"{output_dir}/df_q{qi}.json")
        df_times = get_times(df_data, 0) if df_data else []
        df_min = hot_min(df_times)

        f.write(f"**DataFusion baseline:** {df_min}ms (min of hot), all iterations: {df_times}\n\n")

        # Memory config table
        f.write("#### Performance vs Memory Budget (min of hot iterations)\n\n")
        f.write("| Budget | Cold | Min hot | All iters | Speedup | Entries | Cache mem | Disk | cache_hit | eval_pred | squeezed_ok | IO r/w |\n")
        f.write("|--------|------|---------|-----------|---------|---------|-----------|------|-----------|-----------|-------------|--------|\n")

        for mem in memory_configs:
            data = load_json(f"{output_dir}/baseline_q{qi}_{mem}mb.json")
            if data is None:
                f.write(f"| {mem}MB | - | - | - | - | - | - | - | - | - | - | - |\n")
                continue
            times = get_times(data, 0)
            cold = times[0] if times else 0
            hmin = hot_min(times)
            speedup = df_min / hmin if hmin > 0 and df_min > 0 else 0
            stats = get_cache_stats(data, 0)
            if stats:
                rt = stats.get("runtime", {})
                entries = stats.get("total_entries", 0)
                cache_mem = stats.get("memory_usage_bytes", 0) // (1024*1024)
                disk_mb = stats.get("disk_usage_bytes", 0) // (1024*1024)
                c_hit = rt.get("cache_hit", 0)
                eval_p = rt.get("eval_predicate", 0)
                sq_ok = rt.get("get_squeezed_success", 0)
                io_r = rt.get("read_io_count", 0)
                io_w = rt.get("write_io_count", 0)
            else:
                entries = cache_mem = disk_mb = c_hit = eval_p = sq_ok = io_r = io_w = 0

            f.write(f"| {mem}MB | {cold}ms | {hmin}ms | {times} | {speedup:.2f}x | {entries} | {cache_mem}MB | {disk_mb}MB | {c_hit} | {eval_p} | {sq_ok} | {io_r}/{io_w} |\n")

        f.write("\n")

        # Concurrent regression table
        f.write("#### Latency Under Contention\n\n")
        f.write("| Budget | Baseline min (ms) | ")
        for hi in range(num_heavy):
            hname = heavy_names[hi] if hi < len(heavy_names) else f"h{hi}"
            f.write(f"During {hname} | ")
        f.write("Worst regression |\n")

        f.write("|--------|-------------------| ")
        for _ in range(num_heavy):
            f.write("---| ")
        f.write("---|\n")

        for mem in memory_configs:
            bl_data = load_json(f"{output_dir}/baseline_q{qi}_{mem}mb.json")
            bl_times = get_times(bl_data, 0) if bl_data else []
            bl_min = hot_min(bl_times)

            conc_times = []
            for hi in range(num_heavy):
                cd = load_json(f"{output_dir}/conc_light_during_heavy{hi}_{mem}mb.json")
                ct = get_times(cd, qi) if cd else []
                conc_times.append(ct[0] if ct else 0)

            max_conc = max(conc_times) if conc_times else 0
            regression = ((max_conc - bl_min) / bl_min * 100) if bl_min > 0 else 0

            f.write(f"| {mem}MB | {bl_min} | ")
            for ct in conc_times:
                f.write(f"{ct} | ")
            f.write(f"{regression:+.0f}% |\n")

        f.write("\n")

        # Explain-analyze excerpt (largest memory config, last iteration)
        last_mem = memory_configs[-1]
        log_path = f"{output_dir}/baseline_q{qi}_{last_mem}mb.log"
        if os.path.exists(log_path):
            with open(log_path) as lf:
                content = lf.read()
            blocks = content.split("=== EXPLAIN ANALYZE")
            if len(blocks) >= 2:
                last_block = blocks[-1][:4000]
                f.write(f"<details>\n<summary>EXPLAIN ANALYZE ({last_mem}MB, last iteration)</summary>\n\n```\n")
                f.write("=== EXPLAIN ANALYZE" + last_block.strip())
                f.write("\n```\n</details>\n\n")

        f.write("---\n\n")

    # --- Heavy queries timing ---
    f.write("## Heavy Query Timings (spill baseline)\n\n")
    f.write("| Query | Description | ")
    for mem in memory_configs:
        f.write(f"{mem}MB | ")
    f.write("\n|-------|-------------| ")
    for _ in memory_configs:
        f.write("---| ")
    f.write("\n")

    for hi in range(num_heavy):
        hname = heavy_names[hi] if hi < len(heavy_names) else f"h{hi}"
        hpurpose = heavy_purposes[hi] if hi < len(heavy_purposes) else ""
        f.write(f"| {hname} | {hpurpose} | ")
        for mem in memory_configs:
            hd = load_json(f"{output_dir}/heavy_alone_idx{hi}_{mem}mb.json")
            ht = get_times(hd, 0) if hd else []
            f.write(f"{ht[0] if ht else '-'}ms | ")
        f.write("\n")

    f.write("\n")

    # --- Summary ---
    f.write("## Summary: Best Speedup per Query (min of hot)\n\n")
    f.write("| Query | Purpose | DF min (ms) | Best config | Best min (ms) | Speedup | eval_pred | squeezed_ok | Worst conc regression |\n")
    f.write("|-------|---------|-------------|-------------|---------------|---------|-----------|-------------|----------------------|\n")
    for qi in range(num_light):
        name = light_names[qi] if qi < len(light_names) else f"q{qi}"
        purpose = light_purposes[qi] if qi < len(light_purposes) else ""

        df_data = load_json(f"{output_dir}/df_q{qi}.json")
        df_times = get_times(df_data, 0) if df_data else []
        df_min = hot_min(df_times)

        best_speedup = 0
        best_mem = 0
        best_min_val = 0
        best_eval_p = 0
        best_sq_ok = 0
        worst_regression = 0

        for mem in memory_configs:
            data = load_json(f"{output_dir}/baseline_q{qi}_{mem}mb.json")
            if data is None:
                continue
            times = get_times(data, 0)
            hmin = hot_min(times)
            speedup = df_min / hmin if hmin > 0 and df_min > 0 else 0
            if speedup > best_speedup:
                best_speedup = speedup
                best_mem = mem
                best_min_val = hmin
                stats = get_cache_stats(data, 0)
                if stats:
                    rt = stats.get("runtime", {})
                    best_eval_p = rt.get("eval_predicate", 0)
                    best_sq_ok = rt.get("get_squeezed_success", 0)

            # Check concurrent regression
            for hi in range(num_heavy):
                cd = load_json(f"{output_dir}/conc_light_during_heavy{hi}_{mem}mb.json")
                ct = get_times(cd, qi) if cd else []
                conc_val = ct[0] if ct else 0
                if hmin > 0 and conc_val > 0:
                    reg = (conc_val - hmin) / hmin * 100
                    worst_regression = max(worst_regression, reg)

        f.write(f"| {name} | {purpose} | {df_min} | {best_mem}MB | {best_min_val} | {best_speedup:.2f}x | {best_eval_p} | {best_sq_ok} | {worst_regression:+.0f}% |\n")

    f.write("\n## Key Metrics Explained\n\n")
    f.write("- **Min hot:** Minimum of iteration times excluding the first (cold) run. Best case for cache-hot.\n")
    f.write("- **cache_hit**: Row group served entirely from cache (no Parquet decode)\n")
    f.write("- **eval_predicate**: Predicate evaluated directly on cached/squeezed column data\n")
    f.write("- **squeezed_success**: Data served from transcoded (squeezed) representation\n")
    f.write("- **IO r/w**: Disk I/O operations (read=hydration from disk, write=spill)\n")
    f.write("- **Regression**: How much light query slows down when heavy query runs concurrently\n")
    f.write("- **Speedup**: DF_min / Cache_min — how much faster cache is vs plain DataFusion\n")

print(f"Detailed report: {report_path}")

# ================================================================
# Console summary
# ================================================================
print("\n" + "=" * 110)
print("  CONCURRENT MIX SUMMARY (metric: min of hot iterations)")
print("=" * 110)

print(f"\n  {'Query':<28}{'DF':<7}", end="")
for mem in memory_configs:
    print(f"{mem}MB".rjust(8), end="")
print(f"  {'Best↑':<8}{'Regr'}")
print(f"  {'-'*105}")

for qi in range(num_light):
    name = (light_names[qi] if qi < len(light_names) else f"q{qi}")[:27]
    df_data = load_json(f"{output_dir}/df_q{qi}.json")
    df_times = get_times(df_data, 0) if df_data else []
    df_min = hot_min(df_times)
    print(f"  {name:<28}{df_min:<7}", end="")

    best_speedup = 0
    worst_regression = 0
    for mem in memory_configs:
        data = load_json(f"{output_dir}/baseline_q{qi}_{mem}mb.json")
        times = get_times(data, 0) if data else []
        hmin = hot_min(times)
        speedup = df_min / hmin if hmin > 0 and df_min > 0 else 0
        best_speedup = max(best_speedup, speedup)
        print(f"{hmin:>8}", end="")

        for hi in range(num_heavy):
            cd = load_json(f"{output_dir}/conc_light_during_heavy{hi}_{mem}mb.json")
            ct = get_times(cd, qi) if cd else []
            conc_val = ct[0] if ct else 0
            if hmin > 0 and conc_val > 0:
                reg = (conc_val - hmin) / hmin * 100
                worst_regression = max(worst_regression, reg)

    print(f"  {best_speedup:<8.2f}{worst_regression:+.0f}%")

print("\n" + "=" * 110)
PYEOF

echo ""
echo "🎉 === Done! ==="
echo "  📄 Detailed report: $OUTPUT_DIR/detailed_report.md"
echo "  📋 Logs (explain-analyze + cache stats): $OUTPUT_DIR/*.log"
echo "  🔥 Flamegraphs: $OUTPUT_DIR/flamegraphs/"
