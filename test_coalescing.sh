#!/bin/bash
set -e

export TMPDIR=/home/ec2-user/tmp
mkdir -p $TMPDIR

echo "=== Building release ==="
cargo build --release --bin in_process

# Check data exists
if [ ! -f benchmark/clickbench/data/hits.parquet ]; then
    echo "ERROR: hits.parquet not found. Download with:"
    echo "  wget -P benchmark/clickbench/data/ https://datasets.clickhouse.com/hits_compatible/hits.parquet"
    exit 1
fi

echo ""
echo "=== Running Q19 with liquid-no-squeeze @ 256MB (coalescing should activate) ==="
echo "--- Iteration 1 (cold cache, fills + spills to disk) ---"
./target/release/in_process \
  --manifest benchmark/clickbench/manifest.json \
  --bench-mode liquid-no-squeeze \
  --max-memory-mb 256 \
  --query-index 19 \
  --iteration 3 \
  --reset-cache \
  --output /tmp/coalesce_q19_nosqueeze.json

echo ""
echo "Results saved to /tmp/coalesce_q19_nosqueeze.json"
echo ""

echo "=== Running Q19 with liquid (squeeze) @ 256MB (baseline comparison) ==="
./target/release/in_process \
  --manifest benchmark/clickbench/manifest.json \
  --bench-mode liquid \
  --max-memory-mb 256 \
  --query-index 19 \
  --iteration 3 \
  --reset-cache \
  --output /tmp/coalesce_q19_squeeze.json

echo ""
echo "Results saved to /tmp/coalesce_q19_squeeze.json"
echo ""

echo "=== Running Q7 with liquid-no-squeeze @ 64MB (smaller budget, more spill) ==="
./target/release/in_process \
  --manifest benchmark/clickbench/manifest.json \
  --bench-mode liquid-no-squeeze \
  --max-memory-mb 64 \
  --query-index 7 \
  --iteration 3 \
  --reset-cache \
  --output /tmp/coalesce_q7_nosqueeze.json

echo ""
echo "=== Summary ==="
echo "Q19 liquid-no-squeeze (coalesced):"
python3 -c "
import json
with open('/tmp/coalesce_q19_nosqueeze.json') as f:
    d = json.load(f)
for q in d.get('queries', d.get('results', [d])):
    times = [i.get('elapsed_ms', i.get('duration_ms', 0)) for i in q.get('iterations', [])]
    if times:
        print(f'  iterations: {times}')
        print(f'  avg: {sum(times)/len(times):.1f}ms')
" 2>/dev/null || echo "  (parse output manually: cat /tmp/coalesce_q19_nosqueeze.json | python3 -m json.tool)"

echo ""
echo "Q19 liquid-squeeze (baseline):"
python3 -c "
import json
with open('/tmp/coalesce_q19_squeeze.json') as f:
    d = json.load(f)
for q in d.get('queries', d.get('results', [d])):
    times = [i.get('elapsed_ms', i.get('duration_ms', 0)) for i in q.get('iterations', [])]
    if times:
        print(f'  iterations: {times}')
        print(f'  avg: {sum(times)/len(times):.1f}ms')
" 2>/dev/null || echo "  (parse output manually: cat /tmp/coalesce_q19_squeeze.json | python3 -m json.tool)"

echo ""
echo "=== Done. Check /tmp/coalesce_*.json for full results ==="
