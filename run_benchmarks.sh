#!/bin/bash
set -e

mkdir -p outputs/skip_str_with_spill

# Skip string columns + allow disk spill for numerics
# Start from 4096MB where numeric columns fit in memory

for mem in 4096 8192 12800; do
  echo "=== skip-str + disk spill: max-memory-mb=$mem ==="
  cargo run --release --bin in_process -- \
    --manifest benchmark/clickbench/manifest.json \
    --bench-mode liquid \
    --max-memory-mb $mem \
    --skip-string-columns \
    --output outputs/skip_str_with_spill/liquid_${mem}mb.json
  echo "=== Done: ${mem}MB ==="
  sleep 30
done

# DataFusion baseline
echo "=== DataFusion baseline ==="
cargo run --release --bin in_process -- \
  --manifest benchmark/clickbench/manifest.json \
  --bench-mode datafusion-default \
  --output outputs/skip_str_with_spill/datafusion_baseline.json
echo "=== Done ==="

echo "All benchmarks complete."
