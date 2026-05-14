#!/bin/bash
set -e

MEMORY_MB=${1:-2048}
ITERATIONS=${2:-5}
OUTPUT_DIR="outputs/predicate_only_bench"

mkdir -p "$OUTPUT_DIR"

# All 43 ClickBench queries (0-42)
QUERIES=$(seq 0 42)

echo "========================================================"
echo "  Predicate-Only Cache: Full ClickBench Benchmark"
echo "  Memory: ${MEMORY_MB}MB, Iterations: ${ITERATIONS}"
echo "========================================================"
echo ""

# Build once upfront
echo ">>> Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# --- Run all baselines ---
echo ">>> Running ALL baselines (parquet mode)..."
for Q in $QUERIES; do
    echo -n "  Q${Q}..."
    if RUST_LOG=error target/release/in_process \
        --manifest benchmark/clickbench/manifest.json \
        --bench-mode parquet \
        --query-index $Q \
        --iteration $ITERATIONS \
        --output "$OUTPUT_DIR/q${Q}_baseline.json" > /dev/null 2>&1; then
        echo " done"
    else
        echo " FAILED (skipping)"
    fi
done
echo ""

# --- Run all with predicate-only cache ---
echo ">>> Running ALL with predicate-only cache (liquid, ${MEMORY_MB}MB)..."
for Q in $QUERIES; do
    echo -n "  Q${Q}..."
    if RUST_LOG=error target/release/in_process \
        --manifest benchmark/clickbench/manifest.json \
        --bench-mode liquid \
        --max-memory-mb $MEMORY_MB \
        --query-index $Q \
        --iteration $ITERATIONS \
        --output "$OUTPUT_DIR/q${Q}_cached.json" > /dev/null 2>&1; then
        echo " done"
    else
        echo " FAILED (skipping)"
    fi
done
echo ""

# --- Generate summary report ---
echo ">>> Generating summary report..."
python3 - "$OUTPUT_DIR" "$MEMORY_MB" "$ITERATIONS" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
memory_mb = sys.argv[2]
iterations = int(sys.argv[3])

def get_times(filepath):
    try:
        with open(filepath) as f:
            data = json.load(f)
        results = data["results"][0]["iteration_results"]
        return [r["time_millis"] for r in results]
    except (FileNotFoundError, KeyError, IndexError):
        return None

print("=" * 70)
print(f"  PREDICATE-ONLY CACHE BENCHMARK RESULTS ({memory_mb}MB, {iterations} iterations)")
print("=" * 70)
print(f"{'Query':<8}{'Baseline(ms)':<14}{'Cached(ms)':<13}{'Speedup':<10}{'Status'}")
print("-" * 70)

results = []
for q in range(43):
    baseline_times = get_times(f"{output_dir}/q{q}_baseline.json")
    cached_times = get_times(f"{output_dir}/q{q}_cached.json")

    if baseline_times is None or cached_times is None:
        print(f"Q{q:<7}{'SKIP':<14}{'SKIP':<13}{'N/A':<10}❌ missing data")
        continue

    # Use hot avg (skip first iteration)
    baseline_hot = baseline_times[1:] if len(baseline_times) > 1 else baseline_times
    cached_hot = cached_times[1:] if len(cached_times) > 1 else cached_times

    baseline_avg = sum(baseline_hot) / len(baseline_hot)
    cached_avg = sum(cached_hot) / len(cached_hot)

    if baseline_avg > 0 and cached_avg > 0:
        speedup = baseline_avg / cached_avg
        pct = ((baseline_avg - cached_avg) / baseline_avg) * 100
        status = "✅" if pct > 5 else ("➖" if pct > -5 else "❌")
        print(f"Q{q:<7}{baseline_avg:<14.0f}{cached_avg:<13.0f}{speedup:<10.2f}{status} {pct:+.0f}%")
        results.append((q, baseline_avg, cached_avg, speedup, pct))
    else:
        print(f"Q{q:<7}{baseline_avg:<14.0f}{cached_avg:<13.0f}{'N/A':<10}⚠️")

print("-" * 70)

# Summary stats
if results:
    faster = [r for r in results if r[4] > 5]
    slower = [r for r in results if r[4] < -5]
    neutral = [r for r in results if -5 <= r[4] <= 5]

    print(f"\nSummary:")
    print(f"  Faster (>5%):  {len(faster)} queries")
    print(f"  Neutral (±5%): {len(neutral)} queries")
    print(f"  Slower (<-5%): {len(slower)} queries")

    if faster:
        avg_speedup = sum(r[3] for r in faster) / len(faster)
        print(f"  Avg speedup (faster queries): {avg_speedup:.2f}x")

    if slower:
        print(f"  Slower queries: {[f'Q{r[0]}' for r in slower]}")

# Write markdown report
report_path = f"{output_dir}/report.md"
with open(report_path, "w") as f:
    f.write(f"# Predicate-Only Cache Benchmark Results\n\n")
    f.write(f"Config: {memory_mb}MB memory, {iterations} iterations\n\n")
    f.write(f"| Query | Baseline (ms) | Cached (ms) | Speedup | Change |\n")
    f.write(f"|-------|--------------|-------------|---------|--------|\n")
    for q, bl, ca, sp, pct in results:
        status = "✅" if pct > 5 else ("➖" if pct > -5 else "❌")
        f.write(f"| Q{q} | {bl:.0f} | {ca:.0f} | {sp:.2f}x | {pct:+.0f}% {status} |\n")

print(f"\nReport saved to: {report_path}")
print("=" * 70)
PYEOF

echo ""
echo "=== All done! ==="
