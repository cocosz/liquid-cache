#!/bin/bash
set -e

QUERY=${1:?Usage: ./run_profile.sh <query_index>}
MEMORY_MB=${2:-2048}
ITERATIONS=${3:-5}

mkdir -p outputs

echo "========================================"
echo "  Q${QUERY}: Predicate-Only Cache Benchmark"
echo "  Memory: ${MEMORY_MB}MB, Iterations: ${ITERATIONS}"
echo "========================================"
echo ""

# --- Run baseline (plain Parquet/DataFusion, no cache) ---
echo ">>> Running BASELINE (parquet mode, no cache)..."
RUST_LOG=warn cargo run --release --bin in_process -- \
  --manifest benchmark/clickbench/manifest.json \
  --bench-mode parquet \
  --query-index $QUERY \
  --iteration $ITERATIONS \
  --output outputs/q${QUERY}_baseline.json 2>&1 | tail -5

echo ""

# --- Run with predicate-only cache ---
echo ">>> Running PREDICATE-ONLY CACHE (liquid mode, ${MEMORY_MB}MB)..."
RUST_LOG=warn cargo run --release --bin in_process -- \
  --manifest benchmark/clickbench/manifest.json \
  --bench-mode liquid \
  --max-memory-mb $MEMORY_MB \
  --query-index $QUERY \
  --iteration $ITERATIONS \
  --explain-analyze \
  --output outputs/q${QUERY}_predicate_only.json 2>&1 | tail -40

echo ""

# --- Parse results and compute speedup ---
python3 - "$QUERY" <<'EOF'
import json, sys

query = sys.argv[1]

try:
    with open(f"outputs/q{query}_baseline.json") as f:
        baseline = json.load(f)
    with open(f"outputs/q{query}_predicate_only.json") as f:
        cached = json.load(f)
except FileNotFoundError as e:
    print(f"Error: {e}")
    sys.exit(1)

def get_times(data):
    results = data["results"][0]["iteration_results"]
    return [r["time_millis"] for r in results]

baseline_times = get_times(baseline)
cached_times = get_times(cached)

# Skip first iteration (cold start) for hot comparison
baseline_hot = baseline_times[1:] if len(baseline_times) > 1 else baseline_times
cached_cold = cached_times[0] if cached_times else 0
cached_hot = cached_times[1:] if len(cached_times) > 1 else cached_times

baseline_avg = sum(baseline_hot) / len(baseline_hot) if baseline_hot else 0
cached_avg = sum(cached_hot) / len(cached_hot) if cached_hot else 0

print("=" * 50)
print(f"  Q{query} RESULTS SUMMARY")
print("=" * 50)
print(f"  Baseline (Parquet):  {baseline_avg:.0f}ms avg (hot)")
print(f"  Predicate Cache:     {cached_cold}ms cold → {cached_avg:.0f}ms hot")
print(f"")
if baseline_avg > 0:
    speedup = baseline_avg / cached_avg if cached_avg > 0 else float('inf')
    pct = ((baseline_avg - cached_avg) / baseline_avg) * 100
    if pct > 0:
        print(f"  Speedup: {speedup:.2f}x ({pct:.0f}% faster) ✅")
    else:
        print(f"  Slowdown: {speedup:.2f}x ({-pct:.0f}% slower) ❌")
print(f"")
print(f"  All iterations:")
print(f"    Baseline: {baseline_times}")
print(f"    Cached:   {cached_times}")
print("=" * 50)
EOF

echo ""
echo "=== Done ==="
