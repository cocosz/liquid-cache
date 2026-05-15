#!/bin/bash
set -e

export TMPDIR=${TMPDIR:-/home/ec2-user/tmp}
mkdir -p $TMPDIR
mkdir -p outputs/coalescing

echo "=== Building release ==="
cargo build --release --bin in_process

# Check data exists
if [ ! -f benchmark/clickbench/data/hits.parquet ]; then
    echo "ERROR: hits.parquet not found. Download with:"
    echo "  wget -P benchmark/clickbench/data/ https://datasets.clickhouse.com/hits_compatible/hits.parquet"
    exit 1
fi

QUERIES="7 19"
MEMORY_CONFIGS="64 128 256 512"
MODES="liquid liquid-no-squeeze"
ITERATIONS=3

for q in $QUERIES; do
  for mem in $MEMORY_CONFIGS; do
    for mode in $MODES; do
      label="q${q}_${mode}_${mem}mb"
      echo ""
      echo "=== Q${q} ${mode} @ ${mem}MB ==="
      ./target/release/in_process \
        --manifest benchmark/clickbench/manifest.json \
        --bench-mode $mode \
        --max-memory-mb $mem \
        --query-index $q \
        --iteration $ITERATIONS \
        --reset-cache \
        --output outputs/coalescing/${label}.json
    done
  done
done

# DataFusion baseline (no cache, unlimited memory)
echo ""
echo "=== DataFusion baseline ==="
for q in $QUERIES; do
  ./target/release/in_process \
    --manifest benchmark/clickbench/manifest.json \
    --bench-mode datafusion-default \
    --query-index $q \
    --iteration $ITERATIONS \
    --output outputs/coalescing/q${q}_datafusion_baseline.json
done

echo ""
echo "============================================"
echo "=== Summary ==="
echo "============================================"

python3 << 'EOF'
import json, os

results_dir = "outputs/coalescing"
files = sorted(f for f in os.listdir(results_dir) if f.endswith(".json"))

print(f"\n{'Config':<40} {'Iter1':>7} {'Iter2':>7} {'Iter3':>7} {'Avg':>7}  {'DiskR':>7} {'DiskW':>7}")
print("-" * 105)

for fname in files:
    path = os.path.join(results_dir, fname)
    with open(path) as f:
        d = json.load(f)
    for q in d["results"]:
        iters = q["iteration_results"]
        times = [r["time_millis"] for r in iters]
        disk_r = sum(r["disk_bytes_read"] for r in iters) // len(iters) // 1024 // 1024
        disk_w = sum(r["disk_bytes_written"] for r in iters) // len(iters) // 1024 // 1024
        avg = sum(times) / len(times)
        label = fname.replace(".json", "")
        time_strs = "".join(f"{t:>7.0f}" for t in times)
        print(f"{label:<40} {time_strs} {avg:>7.0f}  {disk_r:>5}MB {disk_w:>5}MB")

print()
EOF

echo "=== Done. Full results in outputs/coalescing/ ==="
