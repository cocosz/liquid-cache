#!/bin/bash
set -e

# A query that SELECTs EventDate directly (will show cache hits on hot run)
# Using Q6 which references EventDate in projection
QUERY=${1:-6}

echo "=== Running Q${QUERY} with EventDate-only cache, 2GB, 2 iterations ==="
echo "=== Iteration 1 = cold, Iteration 2 = hot ==="
echo ""

RUST_LOG=warn cargo run --release --bin in_process -- \
  --manifest benchmark/clickbench/manifest.json \
  --bench-mode liquid \
  --max-memory-mb 2048 \
  --skip-string-columns \
  --query-index $QUERY \
  --iteration 2 \
  --explain-analyze \
  --output outputs/q${QUERY}_eventdate.json 2>&1 | tee outputs/q${QUERY}_eventdate.log

echo ""
echo "=== Done ==="
