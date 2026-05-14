#!/bin/bash
set -e

MEMORY_MB=${1:-2048}
ITERATIONS=${2:-5}
OUTPUT_DIR="outputs/predicate_only_bench"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# All 43 ClickBench queries (0-42)
QUERIES=$(seq 0 42)

echo "========================================================"
echo "  3-Way Comparison: DF No-Pushdown vs DF Pushdown vs LC"
echo "  Memory: ${MEMORY_MB}MB, Iterations: ${ITERATIONS}"
echo "========================================================"
echo ""

# Build once upfront
echo ">>> Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# --- 1. Vanilla DataFusion WITHOUT pushdown ---
echo ">>> [1/3] Running vanilla DataFusion WITHOUT pushdown..."
for Q in $QUERIES; do
    echo -n "  Q${Q}..."
    if timeout 300 target/release/in_process \
        --manifest benchmark/clickbench/manifest.json \
        --bench-mode datafusion-default \
        --query-index $Q \
        --iteration $ITERATIONS \
        --output "$OUTPUT_DIR/q${Q}_no_pushdown.json" > /dev/null 2>&1; then
        echo " done"
    else
        echo " FAILED/TIMEOUT"
    fi
done
echo ""

# --- 2. Vanilla DataFusion WITH pushdown ---
echo ">>> [2/3] Running vanilla DataFusion WITH pushdown..."
for Q in $QUERIES; do
    echo -n "  Q${Q}..."
    if timeout 300 target/release/in_process \
        --manifest benchmark/clickbench/manifest.json \
        --bench-mode parquet \
        --query-index $Q \
        --iteration $ITERATIONS \
        --output "$OUTPUT_DIR/q${Q}_pushdown.json" > /dev/null 2>&1; then
        echo " done"
    else
        echo " FAILED/TIMEOUT"
    fi
done
echo ""

# --- 3. LiquidCache (predicate-only, filters cached) with explain-analyze ---
echo ">>> [3/3] Running LiquidCache (predicate-only, ${MEMORY_MB}MB) with EXPLAIN ANALYZE..."
for Q in $QUERIES; do
    echo -n "  Q${Q}..."
    if timeout 300 target/release/in_process \
        --manifest benchmark/clickbench/manifest.json \
        --bench-mode liquid \
        --max-memory-mb $MEMORY_MB \
        --query-index $Q \
        --iteration $ITERATIONS \
        --explain-analyze \
        --output "$OUTPUT_DIR/q${Q}_liquid.json" > "$OUTPUT_DIR/q${Q}_explain.log" 2>&1; then
        echo " done"
    else
        echo " FAILED/TIMEOUT"
    fi
done
echo ""

# --- Generate full report with explain-analyze and cache stats ---
echo ">>> Generating full report..."
python3 - "$OUTPUT_DIR" "$MEMORY_MB" "$ITERATIONS" <<'PYEOF'
import json, sys, os, re

output_dir = sys.argv[1]
memory_mb = sys.argv[2]
iterations = int(sys.argv[3])

def get_times(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        times = [r["time_millis"] for r in data["results"][0]["iteration_results"]]
        return times
    except (FileNotFoundError, KeyError, IndexError):
        return None

def get_cache_stats(filepath):
    """Extract cache stats from the last iteration in the JSON."""
    try:
        with open(filepath) as f:
            data = json.load(f)
        last_iter = data["results"][0]["iteration_results"][-1]
        stats = last_iter.get("cache_stats")
        return stats
    except (FileNotFoundError, KeyError, IndexError):
        return None

def parse_explain_log(filepath):
    """Parse explain-analyze log to get cold (iter 0) and hot (last iter) plans."""
    try:
        with open(filepath) as f:
            content = f.read()
    except FileNotFoundError:
        return None, None

    # Find all EXPLAIN ANALYZE blocks
    blocks = re.split(r'=== EXPLAIN ANALYZE \(Query \d+, Iteration (\d+)\) ===', content)
    cold_plan = None
    hot_plan = None

    i = 1
    while i < len(blocks) - 1:
        iter_num = int(blocks[i])
        plan_text = blocks[i + 1].strip()
        # Trim at the next result table (starts with +---)
        table_start = plan_text.find("+---")
        if table_start > 0:
            plan_text = plan_text[:table_start].strip()

        if iter_num == 0:
            cold_plan = plan_text
        hot_plan = plan_text  # last one will be the hot plan
        i += 2

    return cold_plan, hot_plan

# --- Build summary table ---
report_lines = []
report_lines.append(f"# 3-Way Benchmark: DF vs DF+Pushdown vs LiquidCache (Predicate-Only)\n")
report_lines.append(f"**Config:** LiquidCache {memory_mb}MB, {iterations} iterations\n")
report_lines.append(f"**Metric:** Hot average (skip first cold iteration)\n\n")

report_lines.append("## Summary Table\n")
report_lines.append("| Query | No Pushdown (ms) | Pushdown (ms) | LiquidCache (ms) | Push vs NP | LC vs Push | LC vs NP |")
report_lines.append("|-------|-----------------|--------------|-----------------|-----------|-----------|----------|")

results = []
for q in range(43):
    np_times = get_times(f"{output_dir}/q{q}_no_pushdown.json")
    pu_times = get_times(f"{output_dir}/q{q}_pushdown.json")
    lc_times = get_times(f"{output_dir}/q{q}_liquid.json")

    if np_times is None or pu_times is None or lc_times is None:
        report_lines.append(f"| Q{q} | — | — | — | — | — | — |")
        continue

    np_hot = np_times[1:] if len(np_times) > 1 else np_times
    pu_hot = pu_times[1:] if len(pu_times) > 1 else pu_times
    lc_hot = lc_times[1:] if len(lc_times) > 1 else lc_times

    np_avg = sum(np_hot) / len(np_hot)
    pu_avg = sum(pu_hot) / len(pu_hot)
    lc_avg = sum(lc_hot) / len(lc_hot)

    pvn = np_avg / pu_avg if pu_avg > 0 else 0
    lvp = pu_avg / lc_avg if lc_avg > 0 else 0
    lvn = np_avg / lc_avg if lc_avg > 0 else 0

    report_lines.append(f"| Q{q} | {np_avg:.0f} | {pu_avg:.0f} | {lc_avg:.0f} | {pvn:.2f}x | {lvp:.2f}x | {lvn:.2f}x |")
    results.append({
        "q": q,
        "np_avg": np_avg, "pu_avg": pu_avg, "lc_avg": lc_avg,
        "np_times": np_times, "pu_times": pu_times, "lc_times": lc_times,
        "pvn": pvn, "lvp": lvp, "lvn": lvn,
    })

report_lines.append("")

# --- Aggregated stats ---
if results:
    lc_faster = [r for r in results if r["lvp"] > 1.05]
    lc_slower = [r for r in results if r["lvp"] < 0.95]
    lc_neutral = [r for r in results if 0.95 <= r["lvp"] <= 1.05]

    report_lines.append("## Aggregate Summary\n")
    report_lines.append(f"- **LC faster than Pushdown:** {len(lc_faster)} queries")
    report_lines.append(f"- **LC neutral vs Pushdown:** {len(lc_neutral)} queries")
    report_lines.append(f"- **LC slower than Pushdown:** {len(lc_slower)} queries")
    if lc_faster:
        avg = sum(r["lvp"] for r in lc_faster) / len(lc_faster)
        report_lines.append(f"- **Avg LC speedup (faster):** {avg:.2f}x")
    if lc_slower:
        qs = ", ".join(f"Q{r['q']}" for r in lc_slower)
        report_lines.append(f"- **Slower queries:** {qs}")
    report_lines.append("")

# --- Per-query details with explain-analyze and cache stats ---
report_lines.append("---\n")
report_lines.append("## Per-Query Details\n")

for r in results:
    q = r["q"]
    report_lines.append(f"### Q{q}\n")
    report_lines.append(f"| Metric | No Pushdown | Pushdown | LiquidCache |")
    report_lines.append(f"|--------|-------------|----------|-------------|")
    report_lines.append(f"| Cold (iter 0) | {r['np_times'][0]}ms | {r['pu_times'][0]}ms | {r['lc_times'][0]}ms |")
    hot_np = r["np_times"][1:] if len(r["np_times"]) > 1 else r["np_times"]
    hot_pu = r["pu_times"][1:] if len(r["pu_times"]) > 1 else r["pu_times"]
    hot_lc = r["lc_times"][1:] if len(r["lc_times"]) > 1 else r["lc_times"]
    report_lines.append(f"| Hot avg | {sum(hot_np)/len(hot_np):.0f}ms | {sum(hot_pu)/len(hot_pu):.0f}ms | {sum(hot_lc)/len(hot_lc):.0f}ms |")
    report_lines.append(f"| All iters | {r['np_times']} | {r['pu_times']} | {r['lc_times']} |")
    report_lines.append(f"| LC vs Push | | | **{r['lvp']:.2f}x** |")
    report_lines.append("")

    # Cache stats
    stats = get_cache_stats(f"{output_dir}/q{q}_liquid.json")
    if stats:
        rt = stats.get("runtime", {})
        report_lines.append(f"**Cache Stats (after last iteration):**")
        report_lines.append(f"- Entries: {stats.get('total_entries', 0)} | Memory: {stats.get('memory_usage_bytes', 0) // (1024*1024)}MB | Disk: {stats.get('disk_usage_bytes', 0) // (1024*1024)}MB")
        report_lines.append(f"- cache_hit={rt.get('cache_hit', 0)}, cache_miss={rt.get('cache_miss', 0)}, eval_predicate={rt.get('eval_predicate', 0)}")
        report_lines.append(f"- IO: read={rt.get('read_io_count', 0)}, write={rt.get('write_io_count', 0)}")
        report_lines.append(f"- Squeeze: success={rt.get('get_squeezed_success', 0)}, needs_io={rt.get('get_squeezed_needs_io', 0)}")
        report_lines.append("")

    # Explain analyze plans (cold + hot)
    cold_plan, hot_plan = parse_explain_log(f"{output_dir}/q{q}_explain.log")
    if cold_plan:
        report_lines.append("<details>")
        report_lines.append(f"<summary>EXPLAIN ANALYZE — Cold (Iteration 0)</summary>\n")
        report_lines.append("```")
        report_lines.append(cold_plan)
        report_lines.append("```")
        report_lines.append("</details>\n")
    if hot_plan:
        report_lines.append("<details>")
        report_lines.append(f"<summary>EXPLAIN ANALYZE — Hot (Last Iteration)</summary>\n")
        report_lines.append("```")
        report_lines.append(hot_plan)
        report_lines.append("```")
        report_lines.append("</details>\n")

    report_lines.append("---\n")

# Write report
report_path = f"{output_dir}/report.md"
with open(report_path, "w") as f:
    f.write("\n".join(report_lines))

# Print summary to console
print("=" * 90)
print(f"  3-WAY COMPARISON: DF(no push) vs DF(pushdown) vs LiquidCache({memory_mb}MB)")
print("=" * 90)
print(f"{'Query':<7}{'NoPush':<10}{'Push':<10}{'LC':<10}{'Push/NP':<10}{'LC/Push':<10}{'LC/NP'}")
print("-" * 90)
for r in results:
    print(f"Q{r['q']:<6}{r['np_avg']:<10.0f}{r['pu_avg']:<10.0f}{r['lc_avg']:<10.0f}"
          f"{r['pvn']:<10.2f}{r['lvp']:<10.2f}{r['lvn']:.2f}")
print("-" * 90)
if results:
    print(f"\nLC faster: {len(lc_faster)} | Neutral: {len(lc_neutral)} | Slower: {len(lc_slower)}")
print(f"\nFull report: {report_path}")
print("=" * 90)
PYEOF

echo ""
echo "=== All done! ==="
