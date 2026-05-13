#!/bin/bash
set -e

QUERY=${1:?Usage: ./run_profile.sh <query_index>}

echo "=== Q${QUERY}: SkipStr + 2GB + EXPLAIN ANALYZE ==="
cargo run --release --bin in_process -- \
  --manifest benchmark/clickbench/manifest.json \
  --bench-mode liquid \
  --max-memory-mb 2048 \
  --skip-string-columns \
  --query-index $QUERY \
  --iteration 5 \
  --explain-analyze \
  --output outputs/q${QUERY}_explain.json

echo ""
echo "=== Done. Output: outputs/q${QUERY}_explain.json ==="
