#!/bin/bash
set -e

# Queries that benefit from numeric predicate caching with different working set sizes:
# Q19: UserID Int64 (668MB working set) - high-card, needs more memory
# Q7:  AdvEngineID Int16 (31MB working set) - low-card, tiny memory
# Q40: Multi-predicate, 3 RGs (15MB working set) - stats-pruned
# Q42: Multi-predicate, 3 RGs (7MB working set) - smallest

QUERIES="19 7 40 42"
MEMORY_CONFIGS="8 16 32 64 128 256 384 512 768 1024 2048"
ITERATIONS=5
OUTPUT_DIR="outputs/sweet_spot"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/flamegraphs"

echo "============================================================"
echo "  Sweet Spot Finder: Memory vs Performance + Flamegraphs"
echo "  Queries: $QUERIES"
echo "  Memory configs: $MEMORY_CONFIGS MB"
echo "============================================================"
echo ""

# Build once
echo ">>> Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# Run baselines (pushdown, no cache)
echo ">>> Running pushdown baselines..."
for Q in $QUERIES; do
    echo -n "  Q${Q} baseline..."
    timeout 300 target/release/in_process \
        --manifest benchmark/clickbench/manifest.json \
        --bench-mode parquet \
        --query-index $Q \
        --iteration $ITERATIONS \
        --output "$OUTPUT_DIR/q${Q}_baseline.json" > /dev/null 2>&1 && echo " done" || echo " FAILED"
done
echo ""

# Run each query at each memory config with explain-analyze + flamegraph
for Q in $QUERIES; do
    echo ">>> Q${Q}: running across memory configs..."
    for MEM in $MEMORY_CONFIGS; do
        echo -n "  ${MEM}MB..."
        FLAMEGRAPH_DIR="$OUTPUT_DIR/flamegraphs/q${Q}_${MEM}mb"
        mkdir -p "$FLAMEGRAPH_DIR"
        if timeout 600 target/release/in_process \
            --manifest benchmark/clickbench/manifest.json \
            --bench-mode liquid \
            --max-memory-mb $MEM \
            --query-index $Q \
            --iteration $ITERATIONS \
            --explain-analyze \
            --flamegraph-dir "$FLAMEGRAPH_DIR" \
            --output "$OUTPUT_DIR/q${Q}_${MEM}mb.json" > "$OUTPUT_DIR/q${Q}_${MEM}mb_explain.log" 2>&1; then
            echo " done"
        else
            echo " FAILED/TIMEOUT"
        fi
    done
    echo ""
done

# Generate summary
echo ">>> Generating summary..."
python3 - "$OUTPUT_DIR" "$ITERATIONS" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
iterations = int(sys.argv[2])

queries = [19, 7, 40, 42]
memory_configs = [8, 16, 32, 64, 128, 256, 384, 512, 768, 1024, 2048]

def get_hot_avg(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        times = [r["time_millis"] for r in data["results"][0]["iteration_results"]]
        hot = times[1:] if len(times) > 1 else times
        return sum(hot) / len(hot) if hot else None
    except (FileNotFoundError, KeyError, IndexError):
        return None

def get_cache_stats(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        stats = data["results"][0]["iteration_results"][-1].get("cache_stats")
        return stats
    except (FileNotFoundError, KeyError, IndexError):
        return None

print("=" * 100)
print("  SWEET SPOT ANALYSIS: Memory Budget vs Hot Query Latency")
print("=" * 100)

# Per-query table
for q in queries:
    baseline = get_hot_avg(f"{output_dir}/q{q}_baseline.json")
    baseline_str = f"{baseline:.0f}ms" if baseline else "N/A"
    print(f"\n{'─'*100}")
    print(f"  Q{q} (Pushdown baseline: {baseline_str})")
    print(f"{'─'*100}")
    print(f"  {'Budget':<10}{'Hot(ms)':<10}{'Speedup':<10}{'Cache mem':<12}{'Disk':<10}{'IO reads':<10}{'IO writes':<12}{'Status'}")
    print(f"  {'-'*90}")

    for mem in memory_configs:
        hot = get_hot_avg(f"{output_dir}/q{q}_{mem}mb.json")
        stats = get_cache_stats(f"{output_dir}/q{q}_{mem}mb.json")

        if hot is None:
            print(f"  {mem:<10}{'SKIP':<10}")
            continue

        speedup = baseline / hot if baseline and hot > 0 else 0
        cache_mem = f"{stats['memory_usage_bytes']//(1024*1024)}MB" if stats else "?"
        disk = f"{stats['disk_usage_bytes']//(1024*1024)}MB" if stats else "?"
        rt = stats.get("runtime", {}) if stats else {}
        io_r = rt.get("read_io_count", 0)
        io_w = rt.get("write_io_count", 0)

        if io_r == 0 and speedup > 1.05:
            status = "✅ GREEN"
        elif io_r > 0:
            status = "❌ RED (disk reads)"
        else:
            status = "➖"

        print(f"  {mem:<10}{hot:<10.0f}{speedup:<10.2f}{cache_mem:<12}{disk:<10}{io_r:<10}{io_w:<12}{status}")

# Write markdown
report_path = f"{output_dir}/report.md"
with open(report_path, "w") as f:
    f.write("# Sweet Spot Analysis: Memory Budget vs Performance\n\n")
    f.write("Queries with numeric predicates that benefit from caching.\n")
    f.write("Finding the minimum memory budget for maximum benefit.\n\n")

    for q in queries:
        baseline = get_hot_avg(f"{output_dir}/q{q}_baseline.json")
        f.write(f"## Q{q} (Pushdown baseline: {baseline:.0f}ms)\n\n")
        f.write("| Budget | Hot (ms) | Speedup | Cache mem | Disk | IO reads | Status |\n")
        f.write("|--------|----------|---------|-----------|------|----------|--------|\n")
        for mem in memory_configs:
            hot = get_hot_avg(f"{output_dir}/q{q}_{mem}mb.json")
            stats = get_cache_stats(f"{output_dir}/q{q}_{mem}mb.json")
            if hot is None:
                f.write(f"| {mem}MB | SKIP | | | | | |\n")
                continue
            speedup = baseline / hot if baseline and hot > 0 else 0
            cache_mem = stats['memory_usage_bytes']//(1024*1024) if stats else 0
            disk = stats['disk_usage_bytes']//(1024*1024) if stats else 0
            rt = stats.get("runtime", {}) if stats else {}
            io_r = rt.get("read_io_count", 0)
            status = "✅" if io_r == 0 and speedup > 1.05 else ("❌" if io_r > 0 else "➖")
            f.write(f"| {mem}MB | {hot:.0f} | {speedup:.2f}× | {cache_mem}MB | {disk}MB | {io_r} | {status} |\n")
        f.write("\n")

print(f"\n\nReport: {report_path}")
print(f"Flamegraphs: {output_dir}/flamegraphs/")

# --- Detailed report with explain-analyze and flamegraph links ---
import re
detail_path = f"{output_dir}/detailed_report.md"
with open(detail_path, "w") as f:
    f.write("# Sweet Spot Detailed Analysis\n\n")
    f.write("## Configuration\n\n")
    f.write("| Parameter | Value |\n|---|---|\n")
    f.write("| Instance | c6a.4xlarge |\n")
    f.write("| Dataset | ClickBench hits.parquet (~14.8 GB) |\n")
    f.write(f"| Iterations | {iterations} |\n")
    f.write("| Cache policy | S3-FIFO (LiquidPolicy) |\n")
    f.write("| Squeeze policy | TranscodeSqueezeEvict |\n")
    f.write("| Hydration | NoHydration |\n")
    f.write("| Strategy | Numeric predicate-only caching |\n\n")

    for q in queries:
        baseline = get_hot_avg(f"{output_dir}/q{q}_baseline.json")
        try:
            with open(f"benchmark/clickbench/queries/q{q}.sql") as sq:
                sql = sq.read().strip()
        except:
            sql = "N/A"

        f.write(f"---\n\n## Q{q}\n\n")
        f.write(f"```sql\n{sql}\n```\n\n")
        f.write(f"**Pushdown baseline:** {baseline:.0f}ms\n\n")

        f.write("### Performance vs Memory Budget\n\n")
        f.write("| Budget | Cold (ms) | Hot avg (ms) | All iters | Speedup | Entries | Mem | Disk | IO r/w | eval_pred | cache_hit |\n")
        f.write("|--------|-----------|-------------|-----------|---------|---------|-----|------|--------|-----------|----------|\n")

        for mem in memory_configs:
            try:
                with open(f"{output_dir}/q{q}_{mem}mb.json") as jf:
                    data = json.load(jf)
                times = [r["time_millis"] for r in data["results"][0]["iteration_results"]]
                cold = times[0]
                hot = times[1:] if len(times) > 1 else times
                hot_avg = sum(hot) / len(hot)
                stats = data["results"][0]["iteration_results"][-1].get("cache_stats", {})
                rt = stats.get("runtime", {})
                speedup = baseline / hot_avg if baseline and hot_avg > 0 else 0
                entries = stats.get("total_entries", 0)
                mem_used = stats.get("memory_usage_bytes", 0) // (1024*1024)
                disk_used = stats.get("disk_usage_bytes", 0) // (1024*1024)
                io_r = rt.get("read_io_count", 0)
                io_w = rt.get("write_io_count", 0)
                eval_p = rt.get("eval_predicate", 0)
                c_hit = rt.get("cache_hit", 0)
                f.write(f"| {mem}MB | {cold} | {hot_avg:.0f} | {times} | {speedup:.2f}x | {entries} | {mem_used}MB | {disk_used}MB | {io_r}/{io_w} | {eval_p} | {c_hit} |\n")
            except:
                f.write(f"| {mem}MB | - | - | - | - | - | - | - | - | - | - |\n")
        f.write("\n")

        f.write("### Cache Stats (last iteration, per config)\n\n")
        for mem in memory_configs:
            log_path = f"{output_dir}/q{q}_{mem}mb_explain.log"
            if not os.path.exists(log_path):
                continue
            with open(log_path) as lf:
                content = lf.read()
            blocks = content.split("=== EXPLAIN ANALYZE")
            if len(blocks) < 2:
                continue
            last_block = blocks[-1]
            cache_lines = [l for l in last_block.split("\n") if any(k in l for k in ["Cache:", "Hits:", "Misses:", "IO:", "Squeeze:", "Time:"])]
            if cache_lines:
                f.write(f"<details>\n<summary>{mem}MB cache stats (hot)</summary>\n\n```\n")
                f.write("\n".join(cache_lines))
                f.write("\n```\n</details>\n\n")

        f.write("### Flamegraphs\n\n")
        for mem in memory_configs:
            fg_dir = f"{output_dir}/flamegraphs/q{q}_{mem}mb"
            if os.path.exists(fg_dir):
                svgs = [x for x in os.listdir(fg_dir) if x.endswith(".svg")]
                if svgs:
                    f.write(f"- **{mem}MB:** {len(svgs)} flamegraphs in `flamegraphs/q{q}_{mem}mb/`\n")
        f.write("\n")

print(f"Detailed report: {detail_path}")
print("=" * 100)
PYEOF

echo ""
echo "=== Done! Flamegraphs in $OUTPUT_DIR/flamegraphs/ ==="
