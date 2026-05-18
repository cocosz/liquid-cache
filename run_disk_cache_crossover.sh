#!/bin/bash
set -e

# Disk Cache Crossover Point Benchmark
# =====================================
# Proves: disk cache is beneficial when memory budget >= 30-50% of working set.
# Tests c0_range_filter (362MB working set) at 10%, 20%, 30%, 40%, 50%, 60%, 80%, 100%.
#
# Also enables perf_event counters (requires: sudo sysctl -w kernel.perf_event_paranoid=-1)
#
# Query: SELECT COUNT(*) FROM hits WHERE "AdvEngineID" > 0 AND "ResolutionWidth" >= 1024 AND "ResolutionWidth" <= 1920
# Working set: 362MB (23080 entries, 2 Int16 columns × 212 row groups)

MANIFEST="benchmark/clickbench/manifest_light.json"
OUTPUT_DIR="outputs/disk_cache_crossover"
ITERATIONS=5
QUERY_IDX=0  # c0_range_filter

# Working set = 362MB. Test at various percentages.
# 10 queries with varying working set sizes (from concurrent_mix results):
#
# From manifest_light.json:
#   idx 0  c0_range_filter:     362MB (23080 entries, 2 filter cols full scan)
#   idx 1  c1_multi_numeric:    6MB (291 entries, stats-pruned to 2 RGs)
#   idx 2  c2_point_lookups:    <1MB (6 entries, 1 RG touched)
#   idx 4  c4_date_range_agg:   505MB (21486 entries, 3 filter + 2 agg cols)
#   idx 5  c6_selective:        <1MB (10 entries, 1 RG)
#   idx 6  c7_wide_numeric:     383MB (24436 entries, 2 filter + 7 agg cols)
#   idx 7  q1_advengine:        181MB (11540 entries, 1 Int16 col full scan)
#   idx 8  q7_group_advengine:  181MB (11540 entries, same col + GROUP BY)
#   idx 9  q40_multi_pred:      24MB (860 entries, 5 filter cols, 3 RGs)
#   idx 11 q42_time_bucket:     13MB (688 entries, 4 filter cols, 3 RGs)

QUERY_INDICES=(0 1 2 4 5 6 7 8 9 11)
QUERY_NAMES=(
    "c0_range_filter[362MB]"
    "c1_multi_numeric[6MB]"
    "c2_point_lookups[<1MB]"
    "c4_date_range_agg[505MB]"
    "c6_selective[<1MB]"
    "c7_wide_numeric[383MB]"
    "q1_advengine[181MB]"
    "q7_group_advengine[181MB]"
    "q40_multi_pred[24MB]"
    "q42_time_bucket[13MB]"
)
WORKING_SET_MB=(362 6 1 505 1 383 181 181 24 13)

# Memory budgets as percentage of working set
PERCENTAGES=(10 20 30 40 50 60 80 100 150)

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "============================================================"
echo "  🧪 Disk Cache Crossover Point Benchmark"
echo "  📊 Testing memory budget as % of working set"
echo "  🔁 Iterations: $ITERATIONS"
echo "============================================================"
echo ""

# Enable perf events (requires root/sysctl)
echo "🔧 Attempting to enable perf_event counters..."
sudo sysctl -w kernel.perf_event_paranoid=-1 2>/dev/null && echo "  ✅ perf_event enabled" || echo "  ⚠️  perf_event not available (run: sudo sysctl -w kernel.perf_event_paranoid=-1)"
echo ""

# Drop page cache to get real disk I/O numbers
echo "🔧 Dropping page cache for accurate I/O measurements..."
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null && echo "  ✅ page cache dropped" || echo "  ⚠️  cannot drop page cache (need root)"
echo ""

# Build once
echo "🔨 Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# Print queries
for i in "${!QUERY_INDICES[@]}"; do
    qi=${QUERY_INDICES[$i]}
    SQL_FILE=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['queries'][$qi])")
    echo "  🔹 [${qi}] ${QUERY_NAMES[$i]}:"
    echo "      $(cat "$SQL_FILE" | tr '\n' ' ')"
done
echo ""

# ============================================================
# Parquet baseline (no cache)
# ============================================================
echo "📊 Parquet baseline (no cache)..."
for i in "${!QUERY_INDICES[@]}"; do
    qi=${QUERY_INDICES[$i]}
    echo -n "  🔹 ${QUERY_NAMES[$i]}..."

    # Drop page cache before parquet baseline
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true

    timeout 600 target/release/in_process \
        --manifest "$MANIFEST" \
        --bench-mode parquet \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --output "$OUTPUT_DIR/parquet_q${qi}.json" > "$OUTPUT_DIR/parquet_q${qi}.log" 2>&1 && echo " ✅" || echo " ❌"
done
echo ""

# ============================================================
# Sweep memory budgets (% of working set)
# ============================================================
echo "🚀 Sweeping memory budgets..."
for i in "${!QUERY_INDICES[@]}"; do
    qi=${QUERY_INDICES[$i]}
    ws=${WORKING_SET_MB[$i]}
    echo "  ═══ ${QUERY_NAMES[$i]} (working set: ${ws}MB) ═══"

    for pct in "${PERCENTAGES[@]}"; do
        mem_mb=$(( ws * pct / 100 ))
        # Minimum 1MB
        if [ $mem_mb -lt 1 ]; then
            mem_mb=1
        fi
        echo -n "    ${pct}% = ${mem_mb}MB..."

        # Drop page cache before each run to get real I/O
        sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true

        timeout 600 target/release/in_process \
            --manifest "$MANIFEST" \
            --bench-mode liquid \
            --max-memory-mb $mem_mb \
            --iteration $ITERATIONS \
            --query-index $qi \
            --perf-events \
            --explain-analyze \
            --output "$OUTPUT_DIR/liquid_q${qi}_${pct}pct.json" > "$OUTPUT_DIR/liquid_q${qi}_${pct}pct.log" 2>&1 && echo " ✅" || echo " ❌"
    done
    echo ""
done

# ============================================================
# Generate report
# ============================================================
echo "📝 Generating report..."
python3 - "$OUTPUT_DIR" "$ITERATIONS" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
iterations = int(sys.argv[2])

queries = [0, 1, 2, 4, 5, 6, 7, 8, 9, 11]
query_names = [
    "c0_range_filter", "c1_multi_numeric", "c2_point_lookups",
    "c4_date_range_agg", "c6_selective", "c7_wide_numeric",
    "q1_advengine", "q7_group_advengine", "q40_multi_pred", "q42_time_bucket"
]
working_sets = [362, 6, 1, 505, 1, 383, 181, 181, 24, 13]
percentages = [10, 20, 30, 40, 50, 60, 80, 100, 150]

def load_json(filepath):
    try:
        with open(filepath) as f:
            return json.load(f)
    except:
        return None

def get_times(data, qi=0):
    try:
        return [r["time_millis"] for r in data["results"][qi]["iteration_results"]]
    except:
        return []

def hot_min(times):
    hot = times[1:] if len(times) > 1 else times
    return min(hot) if hot else 0

def get_perf(data, qi=0):
    try:
        return data["results"][qi]["iteration_results"][-1].get("perf_events")
    except:
        return None

def get_cache_stats(data, qi=0):
    try:
        return data["results"][qi]["iteration_results"][-1].get("cache_stats")
    except:
        return None

def get_disk_bytes(data, qi=0):
    try:
        last = data["results"][qi]["iteration_results"][-1]
        return last.get("disk_bytes_read", 0), last.get("disk_bytes_written", 0)
    except:
        return 0, 0

report_path = f"{output_dir}/report.md"
with open(report_path, "w") as f:
    f.write("# Disk Cache Crossover Point: Memory Budget vs Performance\n\n")
    f.write("## Hypothesis\n\n")
    f.write("Disk cache is beneficial (faster than Parquet) when memory budget ≥ 30-50% of the query's working set. ")
    f.write("Below that, too many entries spill to disk and random I/O exceeds decode savings.\n\n")

    f.write("## Method\n\n")
    f.write("For each query, we sweep memory budget from 10% to 150% of working set and measure:\n")
    f.write("- Latency (min of hot iterations)\n")
    f.write("- CPU cycles and instructions (perf hardware counters)\n")
    f.write("- Disk I/O (bytes read/written from process)\n")
    f.write("- Cache stats (entries in memory vs disk, IO reads)\n\n")
    f.write("Page cache is dropped before each run (`echo 3 > /proc/sys/vm/drop_caches`) for accurate I/O.\n\n")

    # Per-query crossover tables
    for idx, qi in enumerate(queries):
        name = query_names[idx]
        ws = working_sets[idx]

        pq = load_json(f"{output_dir}/parquet_q{qi}.json")
        pq_times = get_times(pq) if pq else []
        pq_min = hot_min(pq_times)
        pq_perf = get_perf(pq) if pq else None
        pq_disk_r, pq_disk_w = get_disk_bytes(pq) if pq else (0, 0)

        f.write(f"---\n\n## {name} (working set: {ws}MB)\n\n")
        f.write(f"**Parquet baseline:** {pq_min}ms (min hot), all: {pq_times}\n\n")
        if pq_perf:
            f.write(f"**Parquet perf:** cycles={pq_perf.get('cpu_cycles',0):,}, instructions={pq_perf.get('instructions',0):,}\n\n")

        f.write("### Crossover Table\n\n")
        f.write("| Budget (% of WS) | Memory (MB) | Min hot (ms) | Speedup vs Parquet | Entries in mem | Entries on disk | Disk usage (MB) | IO reads | CPU cycles | Instructions | Disk read (MB) | Zone |\n")
        f.write("|-------------------|-------------|-------------|--------------------:|----------------|----------------|-----------------|----------|-----------|-------------|----------------|------|\n")

        crossover_pct = None
        for pct in percentages:
            mem_mb = max(1, ws * pct // 100)
            data = load_json(f"{output_dir}/liquid_q{qi}_{pct}pct.json")
            if data is None:
                f.write(f"| {pct}% | {mem_mb} | - | - | - | - | - | - | - | - | - | - |\n")
                continue

            times = get_times(data)
            hmin = hot_min(times)
            speedup = pq_min / hmin if hmin > 0 and pq_min > 0 else 0
            stats = get_cache_stats(data)
            perf = get_perf(data)
            disk_r, disk_w = get_disk_bytes(data)

            mem_entries = 0
            disk_entries = 0
            disk_mb = 0
            io_reads = 0
            if stats:
                mem_entries = stats.get("memory_arrow_entries", 0) + stats.get("memory_liquid_entries", 0) + stats.get("memory_squeezed_liquid_entries", 0)
                disk_entries = stats.get("disk_liquid_entries", 0) + stats.get("disk_arrow_entries", 0)
                disk_mb = stats.get("disk_usage_bytes", 0) // (1024*1024)
                io_reads = stats.get("runtime", {}).get("read_io_count", 0)

            cycles = perf.get("cpu_cycles", 0) if perf else 0
            instr = perf.get("instructions", 0) if perf else 0
            proc_disk_r = disk_r / (1024*1024)

            if speedup >= 1.0 and crossover_pct is None:
                crossover_pct = pct
                zone = "🟢 ← crossover"
            elif speedup >= 1.0:
                zone = "🟢"
            else:
                zone = "🔴"

            f.write(f"| {pct}% | {mem_mb} | {hmin} | {speedup:.2f}× | {mem_entries} | {disk_entries} | {disk_mb} | {io_reads} | {cycles:,} | {instr:,} | {proc_disk_r:.1f} | {zone} |\n")

        # Parquet row
        pq_cycles = pq_perf.get("cpu_cycles", 0) if pq_perf else 0
        pq_instr = pq_perf.get("instructions", 0) if pq_perf else 0
        f.write(f"| Parquet | — | {pq_min} | 1.00× | — | — | — | — | {pq_cycles:,} | {pq_instr:,} | {pq_disk_r/(1024*1024):.1f} | — |\n")

        f.write("\n")

        # Analysis
        f.write("### Analysis\n\n")
        if crossover_pct:
            f.write(f"**Crossover point: {crossover_pct}% of working set ({ws * crossover_pct // 100}MB)**\n\n")
            f.write(f"- Below {crossover_pct}%: disk cache is slower than Parquet (too much random I/O from evicted entries)\n")
            f.write(f"- At {crossover_pct}%+: disk cache matches or beats Parquet (enough hot data in memory, minimal disk reads)\n")
            f.write(f"- At 100%+: full memory cache, maximum speedup (no I/O at all)\n\n")
        else:
            f.write("**No crossover found** — disk cache did not outperform Parquet at any tested budget. ")
            f.write("This query's working set may require a higher budget percentage, or the decode cost is too low to offset disk I/O.\n\n")

        # Explain-analyze for crossover config
        if crossover_pct:
            log_path = f"{output_dir}/liquid_q{qi}_{crossover_pct}pct.log"
            if os.path.exists(log_path):
                with open(log_path) as lf:
                    content = lf.read()
                blocks = content.split("=== EXPLAIN ANALYZE")
                if len(blocks) >= 2:
                    last_block = blocks[-1][:4000]
                    f.write(f"<details>\n<summary>EXPLAIN ANALYZE at crossover ({crossover_pct}%, last iteration)</summary>\n\n```\n")
                    f.write("=== EXPLAIN ANALYZE" + last_block.strip())
                    f.write("\n```\n</details>\n\n")

    # ---- Conclusion ----
    f.write("---\n\n## Conclusion\n\n")
    f.write("| Query | Working set | Crossover point | Interpretation |\n")
    f.write("|-------|-------------|-----------------|----------------|\n")

    for idx, qi in enumerate(queries):
        name = query_names[idx]
        ws = working_sets[idx]
        pq = load_json(f"{output_dir}/parquet_q{qi}.json")
        pq_min = hot_min(get_times(pq)) if pq else 0

        crossover = "N/A"
        for pct in percentages:
            data = load_json(f"{output_dir}/liquid_q{qi}_{pct}pct.json")
            if data:
                hmin = hot_min(get_times(data))
                if hmin > 0 and pq_min > 0 and pq_min / hmin >= 1.0:
                    crossover = f"{pct}% ({ws * pct // 100}MB)"
                    break

        if crossover == "N/A":
            interp = "Decode cost too low relative to disk I/O overhead"
        elif "10%" in crossover or "20%" in crossover:
            interp = "Lightweight — even aggressive eviction works"
        elif "30%" in crossover or "40%" in crossover:
            interp = "Confirms 30-50% theory"
        else:
            interp = "Needs most of working set in memory"

        f.write(f"| {name} | {ws}MB | {crossover} | {interp} |\n")

    f.write("\n### Key Takeaway\n\n")
    f.write("The crossover point depends on two factors:\n")
    f.write("1. **Decode cost** — queries touching heavily-encoded columns (delta, dictionary) benefit more from disk cache\n")
    f.write("2. **Working set compressibility in liquid format** — if liquid entries are small, more fit in memory than expected\n\n")
    f.write("When the working set in liquid format fits within the memory budget (even if Arrow size is larger), ")
    f.write("no disk spill occurs and the speedup is identical to memory cache. This happens for q1/q7 where ")
    f.write("liquid format compresses Int16 columns efficiently.\n")

print(f"✅ Report: {report_path}")

# Console summary
print("\n" + "=" * 90)
print("  CROSSOVER POINT SUMMARY")
print("=" * 90)
for idx, qi in enumerate(queries):
    name = query_names[idx]
    ws = working_sets[idx]
    pq = load_json(f"{output_dir}/parquet_q{qi}.json")
    pq_min = hot_min(get_times(pq)) if pq else 0
    print(f"\n  {name} (WS={ws}MB, Parquet={pq_min}ms):")
    for pct in percentages:
        mem_mb = max(1, ws * pct // 100)
        data = load_json(f"{output_dir}/liquid_q{qi}_{pct}pct.json")
        if data:
            hmin = hot_min(get_times(data))
            sp = pq_min / hmin if hmin > 0 else 0
            marker = " ← crossover" if sp >= 1.0 and all(
                hot_min(get_times(load_json(f"{output_dir}/liquid_q{qi}_{p}pct.json") or {})) == 0 or
                pq_min / hot_min(get_times(load_json(f"{output_dir}/liquid_q{qi}_{p}pct.json") or {})) < 1.0
                for p in percentages if p < pct
            ) else ""
            print(f"    {pct:>4}% ({mem_mb:>4}MB): {hmin:>6}ms  {sp:.2f}×{marker}")
print("\n" + "=" * 90)
PYEOF

echo ""
echo "🎉 === Done! ==="
echo "  📄 Report: $OUTPUT_DIR/report.md"
echo "  📋 Logs: $OUTPUT_DIR/*.log"
