#!/bin/bash
set -e

MEMORY_MB=${1:-2048}
ITERATIONS=${2:-5}
OUTPUT_DIR="outputs/numeric_pred_bench"
QUERIES="19 24 26 37"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "========================================================"
echo "  3-Way Comparison: Numeric Predicate-Only Cache"
echo "  Queries: $QUERIES"
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

# --- 3. LiquidCache (numeric predicate-only) with explain-analyze ---
echo ">>> [3/3] Running LiquidCache (numeric predicate-only, ${MEMORY_MB}MB) with EXPLAIN ANALYZE..."
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

# --- Generate summary report ---
echo ">>> Generating summary report..."
python3 - "$OUTPUT_DIR" "$MEMORY_MB" "$ITERATIONS" "$QUERIES" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
memory_mb = sys.argv[2]
iterations = int(sys.argv[3])
queries = [int(q) for q in sys.argv[4].split()]

def get_times(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        return [r["time_millis"] for r in data["results"][0]["iteration_results"]]
    except (FileNotFoundError, KeyError, IndexError):
        return None

def get_cache_stats(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        return data["results"][0]["iteration_results"][-1].get("cache_stats")
    except (FileNotFoundError, KeyError, IndexError):
        return None

print("=" * 90)
print(f"  NUMERIC PREDICATE-ONLY CACHE: Q{', Q'.join(str(q) for q in queries)}")
print(f"  Config: {memory_mb}MB, {iterations} iterations")
print("=" * 90)
print(f"{'Query':<7}{'NoPush':<10}{'Push':<10}{'LC':<10}{'Push/NP':<10}{'LC/Push':<10}{'LC/NP'}")
print("-" * 90)

results = []
for q in queries:
    np_times = get_times(f"{output_dir}/q{q}_no_pushdown.json")
    pu_times = get_times(f"{output_dir}/q{q}_pushdown.json")
    lc_times = get_times(f"{output_dir}/q{q}_liquid.json")

    if np_times is None or pu_times is None or lc_times is None:
        print(f"Q{q:<6}{'—':<10}{'—':<10}{'—':<10}SKIP")
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

    print(f"Q{q:<6}{np_avg:<10.0f}{pu_avg:<10.0f}{lc_avg:<10.0f}"
          f"{pvn:<10.2f}{lvp:<10.2f}{lvn:.2f}")
    results.append((q, np_avg, pu_avg, lc_avg, pvn, lvp, lvn, np_times, pu_times, lc_times))

print("-" * 90)

# Per-query detail with cache stats
print("\n--- Cache Stats ---")
for q, np_avg, pu_avg, lc_avg, pvn, lvp, lvn, np_t, pu_t, lc_t in results:
    stats = get_cache_stats(f"{output_dir}/q{q}_liquid.json")
    print(f"\nQ{q}: LC={lc_avg:.0f}ms (hot), Push={pu_avg:.0f}ms → {lvp:.2f}x speedup")
    print(f"  All iters: NoPush={np_t} Push={pu_t} LC={lc_t}")
    if stats:
        print(f"  Cache: entries={stats['total_entries']}, "
              f"arrow={stats['memory_arrow_entries']}, "
              f"liquid={stats['memory_liquid_entries']}, "
              f"squeezed={stats['memory_squeezed_liquid_entries']}")
        print(f"  Memory: {stats['memory_usage_bytes']//(1024*1024)}MB / {stats['max_memory_bytes']//(1024*1024)}MB")
        print(f"  Disk: {stats['disk_usage_bytes']//(1024*1024)}MB")

# Write markdown report
report_path = f"{output_dir}/report.md"
with open(report_path, "w") as f:
    f.write(f"# Numeric Predicate-Only Cache Benchmark\n\n")
    f.write(f"Config: {memory_mb}MB memory, {iterations} iterations, hot avg (skip iter 0)\n\n")
    f.write(f"| Query | No Pushdown (ms) | Pushdown (ms) | LiquidCache (ms) | LC vs Push | LC vs NP |\n")
    f.write(f"|-------|-----------------|--------------|-----------------|-----------|----------|\n")
    for q, np, pu, lc, pvn, lvp, lvn, *_ in results:
        f.write(f"| Q{q} | {np:.0f} | {pu:.0f} | {lc:.0f} | {lvp:.2f}x | {lvn:.2f}x |\n")

print(f"\nReport: {report_path}")
print("=" * 90)
PYEOF

echo ""
echo "=== All done! ==="
