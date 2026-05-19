#!/bin/bash
set -e

# Sweet Spot Analysis for LRU cache policy
# Same queries and memory configs as run_sweet_spot.sh but using --cache-policy lru
#
# Queries:
# Q19: UserID Int64 (668MB working set) - high-card, needs more memory
# Q7:  AdvEngineID Int16 (31MB working set) - low-card, tiny memory
# Q40: Multi-predicate, 3 RGs (15MB working set) - stats-pruned
# Q42: Multi-predicate, 3 RGs (7MB working set) - smallest

QUERIES="19 7 40 42"
MEMORY_CONFIGS="8 16 32 64 128 256 384 512 768 1024 2048"
ITERATIONS=5
OUTPUT_DIR="outputs/sweet_spot_lru"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/flamegraphs"

echo "============================================================"
echo "  🧪 Sweet Spot Finder (LRU policy)"
echo "  Queries: $QUERIES"
echo "  Memory configs: $MEMORY_CONFIGS MB"
echo "  Cache policy: LRU"
echo "============================================================"
echo ""

# Build once
echo "🔨 Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# Run baselines (pushdown, no cache)
echo "📊 Running pushdown baselines..."
for Q in $QUERIES; do
    echo -n "  🔹 Q${Q} baseline..."
    timeout 300 target/release/in_process \
        --manifest benchmark/clickbench/manifest.json \
        --bench-mode parquet \
        --query-index $Q \
        --iteration $ITERATIONS \
        --output "$OUTPUT_DIR/q${Q}_baseline.json" > /dev/null 2>&1 && echo " ✅" || echo " ❌"
done
echo ""

# Run each query at each memory config with LRU policy — both liquid (hydration) and arrow (no hydration)
for Q in $QUERIES; do
    echo "🚀 Q${Q}: LRU + hydration..."
    for MEM in $MEMORY_CONFIGS; do
        echo -n "  💾 ${MEM}MB..."
        mkdir -p "$OUTPUT_DIR/flamegraphs/q${Q}_${MEM}mb_lru_hydrate"
        if timeout 600 target/release/in_process \
            --manifest benchmark/clickbench/manifest.json \
            --bench-mode liquid-hydrate \
            --max-memory-mb $MEM \
            --query-index $Q \
            --iteration $ITERATIONS \
            --explain-analyze \
            --cache-policy lru \
            --flamegraph-dir "$OUTPUT_DIR/flamegraphs/q${Q}_${MEM}mb_lru_hydrate" \
            --output "$OUTPUT_DIR/q${Q}_${MEM}mb_lru_hydrate.json" > "$OUTPUT_DIR/q${Q}_${MEM}mb_lru_hydrate.log" 2>&1; then
            echo " ✅"
        else
            echo " ❌"
        fi
    done
    echo ""

    echo "🚀 Q${Q}: LRU + NO hydration..."
    for MEM in $MEMORY_CONFIGS; do
        echo -n "  💾 ${MEM}MB..."
        mkdir -p "$OUTPUT_DIR/flamegraphs/q${Q}_${MEM}mb_lru_nohydrate"
        if timeout 600 target/release/in_process \
            --manifest benchmark/clickbench/manifest.json \
            --bench-mode liquid \
            --max-memory-mb $MEM \
            --query-index $Q \
            --iteration $ITERATIONS \
            --explain-analyze \
            --cache-policy lru \
            --flamegraph-dir "$OUTPUT_DIR/flamegraphs/q${Q}_${MEM}mb_lru_nohydrate" \
            --output "$OUTPUT_DIR/q${Q}_${MEM}mb_lru_nohydrate.json" > "$OUTPUT_DIR/q${Q}_${MEM}mb_lru_nohydrate.log" 2>&1; then
            echo " ✅"
        else
            echo " ❌"
        fi
    done
    echo ""

    echo "🚀 Q${Q}: S3-FIFO + hydration..."
    for MEM in $MEMORY_CONFIGS; do
        echo -n "  💾 ${MEM}MB..."
        mkdir -p "$OUTPUT_DIR/flamegraphs/q${Q}_${MEM}mb_s3fifo_hydrate"
        if timeout 600 target/release/in_process \
            --manifest benchmark/clickbench/manifest.json \
            --bench-mode liquid-hydrate \
            --max-memory-mb $MEM \
            --query-index $Q \
            --iteration $ITERATIONS \
            --explain-analyze \
            --cache-policy s3fifo \
            --flamegraph-dir "$OUTPUT_DIR/flamegraphs/q${Q}_${MEM}mb_s3fifo_hydrate" \
            --output "$OUTPUT_DIR/q${Q}_${MEM}mb_s3fifo_hydrate.json" > "$OUTPUT_DIR/q${Q}_${MEM}mb_s3fifo_hydrate.log" 2>&1; then
            echo " ✅"
        else
            echo " ❌"
        fi
    done
    echo ""

    echo "🚀 Q${Q}: S3-FIFO + NO hydration..."
    for MEM in $MEMORY_CONFIGS; do
        echo -n "  💾 ${MEM}MB..."
        mkdir -p "$OUTPUT_DIR/flamegraphs/q${Q}_${MEM}mb_s3fifo_nohydrate"
        if timeout 600 target/release/in_process \
            --manifest benchmark/clickbench/manifest.json \
            --bench-mode liquid \
            --max-memory-mb $MEM \
            --query-index $Q \
            --iteration $ITERATIONS \
            --explain-analyze \
            --cache-policy s3fifo \
            --flamegraph-dir "$OUTPUT_DIR/flamegraphs/q${Q}_${MEM}mb_s3fifo_nohydrate" \
            --output "$OUTPUT_DIR/q${Q}_${MEM}mb_s3fifo_nohydrate.json" > "$OUTPUT_DIR/q${Q}_${MEM}mb_s3fifo_nohydrate.log" 2>&1; then
            echo " ✅"
        else
            echo " ❌"
        fi
    done
    echo ""
done

# Generate summary
echo "📝 Generating summary..."
python3 - "$OUTPUT_DIR" "$ITERATIONS" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
iterations = int(sys.argv[2])

queries = [19, 7, 40, 42]
memory_configs = [8, 16, 32, 64, 128, 256, 384, 512, 768, 1024, 2048]

def get_hot_min(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        times = [r["time_millis"] for r in data["results"][0]["iteration_results"]]
        hot = times[1:] if len(times) > 1 else times
        return min(hot) if hot else None
    except:
        return None

def get_cache_stats(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        return data["results"][0]["iteration_results"][-1].get("cache_stats")
    except:
        return None

def get_all_times(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        return [r["time_millis"] for r in data["results"][0]["iteration_results"]]
    except:
        return []

def get_cpu_time(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        iters = data["results"][0]["iteration_results"]
        hot = iters[1:] if len(iters) > 1 else iters
        return min(r["cache_cpu_time"] for r in hot)
    except:
        return 0

modes = [
    ("lru_hydrate", "LRU + Hydration"),
    ("lru_nohydrate", "LRU + No Hydration"),
    ("s3fifo_hydrate", "S3-FIFO + Hydration"),
    ("s3fifo_nohydrate", "S3-FIFO + No Hydration"),
]

# Console summary
print("=" * 100)
print("  SWEET SPOT ANALYSIS (LRU Policy): Memory Budget vs Hot Query Latency")
print("=" * 100)

for mode_key, mode_label in modes:
    print(f"\n{'═'*100}")
    print(f"  Mode: {mode_label}")
    print(f"{'═'*100}")
    for q in queries:
        baseline = get_hot_min(f"{output_dir}/q{q}_baseline.json")
        baseline_str = f"{baseline}ms" if baseline else "N/A"
        print(f"\n  Q{q} (Pushdown baseline: {baseline_str})")
        print(f"  {'Budget':<10}{'Min hot':<10}{'Speedup':<10}{'Status'}")
        print(f"  {'-'*40}")

        for mem in memory_configs:
            hot = get_hot_min(f"{output_dir}/q{q}_{mem}mb_{mode_key}.json")
            if hot is None:
                print(f"  {mem:<10}{'SKIP':<10}")
                continue
            speedup = baseline / hot if baseline and hot > 0 else 0
            status = "✅" if speedup > 1.05 else "➖"
            print(f"  {mem:<10}{hot:<10}{speedup:<10.2f}{status}")

# Write markdown report
report_path = f"{output_dir}/report.md"
with open(report_path, "w") as f:
    f.write("# Sweet Spot Analysis (LRU Policy): Memory Budget vs Performance\n\n")
    f.write("## Configuration\n\n")
    f.write("| Parameter | Value |\n|---|---|\n")
    f.write(f"| Cache policy | **LRU** |\n")
    f.write(f"| Iterations | {iterations} |\n")
    f.write("| Squeeze policy | TranscodeSqueezeEvict |\n")
    f.write("| Hydration | NoHydration |\n")
    f.write("| Strategy | Numeric predicate-only caching |\n\n")

    for q in queries:
        baseline = get_hot_min(f"{output_dir}/q{q}_baseline.json")
        baseline_times = get_all_times(f"{output_dir}/q{q}_baseline.json")

        try:
            with open(f"benchmark/clickbench/queries/q{q}.sql") as sq:
                sql = sq.read().strip()
        except:
            sql = "N/A"

        f.write(f"---\n\n## Q{q}\n\n")
        f.write(f"```sql\n{sql}\n```\n\n")
        f.write(f"**Pushdown baseline:** {baseline}ms (min hot), all: {baseline_times}\n\n")

        f.write("### Performance Table (LRU)\n\n")
        f.write("| Memory | Cold (iter 0) | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Speedup | Entries | Mem (MB) | Disk (MB) | Scan CPU (µs) | Zone |\n")
        f.write("|--------|--------------|--------|--------|--------|--------|---------|---------|---------|----------|-----------|---------------|------|\n")

        for mem in memory_configs:
            times = get_all_times(f"{output_dir}/q{q}_{mem}mb.json")
            stats = get_cache_stats(f"{output_dir}/q{q}_{mem}mb.json")
            cpu = get_cpu_time(f"{output_dir}/q{q}_{mem}mb.json")

            if not times:
                f.write(f"| {mem}MB | - | - | - | - | - | - | - | - | - | - | - | - |\n")
                continue

            cold = times[0]
            hot = times[1:] if len(times) > 1 else times
            hmin = min(hot) if hot else 0
            speedup = baseline / hmin if baseline and hmin > 0 else 0

            entries = stats.get("total_entries", 0) if stats else 0
            cache_mb = stats.get("memory_usage_bytes", 0) // (1024*1024) if stats else 0
            disk_mb = stats.get("disk_usage_bytes", 0) // (1024*1024) if stats else 0
            rt = stats.get("runtime", {}) if stats else {}
            io_r = rt.get("read_io_count", 0)

            zone = "🟢" if io_r == 0 and speedup > 1.0 else ("🔴" if io_r > 0 else "➖")

            iter_strs = [str(t) for t in hot]
            while len(iter_strs) < 4:
                iter_strs.append("-")

            f.write(f"| {mem}MB | {cold} | {iter_strs[0]} | {iter_strs[1]} | {iter_strs[2]} | {iter_strs[3]} | {hmin} | {speedup:.2f}x | {entries} | {cache_mb} | {disk_mb} | {cpu} | {zone} |\n")

        # Pushdown row
        if baseline_times:
            bl_hot = baseline_times[1:] if len(baseline_times) > 1 else baseline_times
            bl_strs = [str(t) for t in bl_hot]
            while len(bl_strs) < 4:
                bl_strs.append("-")
            f.write(f"| Pushdown | {baseline_times[0]} | {bl_strs[0]} | {bl_strs[1]} | {bl_strs[2]} | {bl_strs[3]} | {baseline} | 1.00x | — | — | — | — | — |\n")

        f.write("\n")

        # Cache stats at best config
        best_mem = None
        best_speedup = 0
        for mem in memory_configs:
            hmin = get_hot_min(f"{output_dir}/q{q}_{mem}mb.json")
            if hmin and baseline:
                sp = baseline / hmin
                if sp > best_speedup:
                    best_speedup = sp
                    best_mem = mem

        if best_mem:
            stats = get_cache_stats(f"{output_dir}/q{q}_{best_mem}mb.json")
            if stats:
                rt = stats.get("runtime", {})
                f.write(f"### Cache Stats (best: {best_mem}MB, last iteration)\n\n```\n")
                f.write(f"total_entries: {stats.get('total_entries', 0)}\n")
                f.write(f"memory_arrow_entries: {stats.get('memory_arrow_entries', 0)}\n")
                f.write(f"memory_liquid_entries: {stats.get('memory_liquid_entries', 0)}\n")
                f.write(f"memory_squeezed_liquid_entries: {stats.get('memory_squeezed_liquid_entries', 0)}\n")
                f.write(f"disk_liquid_entries: {stats.get('disk_liquid_entries', 0)}\n")
                f.write(f"memory_usage_bytes: {stats.get('memory_usage_bytes', 0):,}\n")
                f.write(f"disk_usage_bytes: {stats.get('disk_usage_bytes', 0):,}\n")
                f.write(f"---\n")
                f.write(f"eval_predicate: {rt.get('eval_predicate', 0)}\n")
                f.write(f"cache_hit: {rt.get('cache_hit', 0)}\n")
                f.write(f"read_io_count: {rt.get('read_io_count', 0)}\n")
                f.write(f"write_io_count: {rt.get('write_io_count', 0)}\n")
                f.write(f"squeeze_io_saved: {rt.get('squeeze_io_saved', 0)}\n")
                f.write("```\n\n")

        # Explain-analyze
        if best_mem:
            log_path = f"{output_dir}/q{q}_{best_mem}mb_explain.log"
            if os.path.exists(log_path):
                with open(log_path) as lf:
                    content = lf.read()
                blocks = content.split("=== EXPLAIN ANALYZE")
                if len(blocks) >= 2:
                    last_block = blocks[-1][:4000]
                    f.write(f"<details>\n<summary>EXPLAIN ANALYZE ({best_mem}MB, last iteration)</summary>\n\n```\n")
                    f.write("=== EXPLAIN ANALYZE" + last_block.strip())
                    f.write("\n```\n</details>\n\n")

print(f"\nReport: {report_path}")
print("=" * 100)
PYEOF

echo ""
echo "🎉 === Done! ==="
echo "  📄 Report: $OUTPUT_DIR/report.md"
echo "  🔥 Flamegraphs: $OUTPUT_DIR/flamegraphs/"
