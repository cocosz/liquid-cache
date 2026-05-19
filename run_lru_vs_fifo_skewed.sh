#!/bin/bash
set -e

# LRU vs S3-FIFO under Skewed Access Patterns
#
# Design:
#   Two queries share the same cached columns (EventDate, CounterID) but hit
#   different row groups (different date ranges). The "hot" query runs 3× more
#   often, creating temporal skew. If LRU is better at retaining frequently-
#   accessed entries, it should show lower latency for the hot query after
#   the cold query pollutes the cache.
#
# Queries (in manifest_skewed.json):
#   Index 0 (HOT): WHERE EventDate IN [2013-07-14, 2013-07-20] AND CounterID > 0
#   Index 1 (COLD): WHERE EventDate IN [2013-06-01, 2013-06-07] AND CounterID > 0
#
# Sequence pattern: HOT HOT HOT COLD HOT HOT HOT COLD ... (repeated N times)
# We measure the latency of each HOT query *after* a COLD query pollutes the cache.
#
# Memory budgets: tight (just below combined working set) to force evictions.

OUTPUT_DIR="outputs/lru_vs_fifo_skewed"
MANIFEST="benchmark/clickbench/manifest_skewed.json"

# Sequence: 4 cycles of (HOT HOT HOT COLD)
# = 16 steps total, 12 HOT + 4 COLD
SEQUENCE="0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1"

# Memory budgets to test (must be tight enough to force evictions between queries)
# We'll first run a baseline to discover working set sizes, then test tight budgets.
MEMORY_CONFIGS="16 32 64 128 256 512"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "============================================================"
echo "  🧪 LRU vs S3-FIFO Skewed Access Experiment"
echo "  Manifest: $MANIFEST"
echo "  Sequence: $SEQUENCE"
echo "  Memory configs: $MEMORY_CONFIGS MB"
echo "============================================================"
echo ""

# Build once
echo "🔨 Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# Run baselines: each query individually with unlimited memory to find working set
echo "📊 Running baselines (unlimited memory)..."
for Q in 0 1; do
    echo -n "  Query $Q (5 iters, no limit)..."
    timeout 300 target/release/in_process \
        --manifest "$MANIFEST" \
        --bench-mode liquid \
        --query-index $Q \
        --iteration 5 \
        --explain-analyze \
        --output "$OUTPUT_DIR/baseline_q${Q}.json" > "$OUTPUT_DIR/baseline_q${Q}.log" 2>&1 && echo " ✅" || echo " ❌"
done
echo ""

# Run parquet baselines
echo "📊 Running parquet baselines..."
for Q in 0 1; do
    echo -n "  Query $Q parquet..."
    timeout 300 target/release/in_process \
        --manifest "$MANIFEST" \
        --bench-mode parquet \
        --query-index $Q \
        --iteration 5 \
        --output "$OUTPUT_DIR/parquet_q${Q}.json" > "$OUTPUT_DIR/parquet_q${Q}.log" 2>&1 && echo " ✅" || echo " ❌"
done
echo ""

# Run sequence for each policy × memory budget
for POLICY in lru s3fifo; do
    echo "═══════════════════════════════════════════════════════"
    echo "  Policy: $POLICY"
    echo "═══════════════════════════════════════════════════════"
    for MEM in $MEMORY_CONFIGS; do
        echo -n "  💾 ${MEM}MB..."
        if timeout 600 target/release/in_process \
            --manifest "$MANIFEST" \
            --bench-mode liquid \
            --max-memory-mb $MEM \
            --cache-policy $POLICY \
            --explain-analyze \
            --query-sequence "$SEQUENCE" \
            --output "$OUTPUT_DIR/${POLICY}_${MEM}mb.json" > "$OUTPUT_DIR/${POLICY}_${MEM}mb.log" 2>&1; then
            echo " ✅"
        else
            echo " ❌"
        fi
    done
    echo ""
done

# Generate analysis
echo "📝 Generating analysis..."
python3 - "$OUTPUT_DIR" "$SEQUENCE" "$MEMORY_CONFIGS" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
sequence_str = sys.argv[2]
mem_configs_str = sys.argv[3]

sequence = [int(x) for x in sequence_str.split(',')]
memory_configs = [int(x) for x in mem_configs_str.split()]

def load_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except:
        return None

def get_sequence_results(data):
    """Extract per-step time_millis and cache_stats from sequence results."""
    if not data:
        return []
    results = []
    for qr in data['results']:
        ir = qr['iteration_results'][0]
        results.append({
            'query_id': qr['query']['id'],
            'time_ms': ir['time_millis'],
            'cpu_time': ir.get('cache_cpu_time', 0),
            'disk_read': ir.get('disk_bytes_read', 0),
            'stats': ir.get('cache_stats'),
        })
    return results

# Print baselines
print("=" * 80)
print("  BASELINES (unlimited memory, 5 iterations)")
print("=" * 80)
for q in [0, 1]:
    data = load_json(f'{output_dir}/baseline_q{q}.json')
    if data:
        times = [r['time_millis'] for r in data['results'][0]['iteration_results']]
        stats = data['results'][0]['iteration_results'][-1].get('cache_stats')
        entries = stats.get('total_entries', 0) if stats else 0
        mem_mb = stats.get('memory_usage_bytes', 0) / (1024*1024) if stats else 0
        print(f"  Q{q}: times={times}, working_set={mem_mb:.1f}MB, entries={entries}")

# Print parquet baselines
for q in [0, 1]:
    data = load_json(f'{output_dir}/parquet_q{q}.json')
    if data:
        times = [r['time_millis'] for r in data['results'][0]['iteration_results']]
        hot = min(times[1:]) if len(times) > 1 else times[0]
        print(f"  Q{q} parquet: times={times}, min_hot={hot}ms")

print()

# Analysis per policy per memory budget
print("=" * 80)
print("  SEQUENCE RESULTS: HOT query latency after COLD pollution")
print("=" * 80)

# Identify "post-cold" HOT queries: indices where query is 0 and previous was 1
post_cold_indices = []
for i, q in enumerate(sequence):
    if q == 0 and i > 0 and sequence[i-1] == 1:
        post_cold_indices.append(i)

print(f"\n  Sequence: {sequence}")
print(f"  Post-cold HOT indices: {post_cold_indices}")
print(f"  (These are the HOT queries right after a COLD query evicts their data)\n")

header = f"  {'Budget':<8}{'Policy':<10}{'PostCold HOT avg':<18}{'All HOT avg':<14}{'COLD avg':<12}{'IO reads':<12}{'Entries'}"
print(header)
print(f"  {'-'*90}")

for mem in memory_configs:
    for policy in ['lru', 's3fifo']:
        data = load_json(f'{output_dir}/{policy}_{mem}mb.json')
        results = get_sequence_results(data)
        if not results:
            print(f"  {mem:<8}{policy:<10}SKIP")
            continue

        # Separate HOT and COLD results
        hot_times = [results[i]['time_ms'] for i in range(len(sequence)) if sequence[i] == 0]
        cold_times = [results[i]['time_ms'] for i in range(len(sequence)) if sequence[i] == 1]
        post_cold_times = [results[i]['time_ms'] for i in post_cold_indices if i < len(results)]

        hot_avg = sum(hot_times) / len(hot_times) if hot_times else 0
        cold_avg = sum(cold_times) / len(cold_times) if cold_times else 0
        post_cold_avg = sum(post_cold_times) / len(post_cold_times) if post_cold_times else 0

        # IO reads from last step
        last_stats = results[-1]['stats'] if results else None
        io_reads = last_stats['runtime']['read_io_count'] if last_stats and last_stats.get('runtime') else 0
        entries = last_stats.get('total_entries', 0) if last_stats else 0

        print(f"  {mem:<8}{policy:<10}{post_cold_avg:<18.1f}{hot_avg:<14.1f}{cold_avg:<12.1f}{io_reads:<12}{entries}")

# Detailed per-step view for most interesting budget
print(f"\n{'=' * 80}")
print("  PER-STEP LATENCY (detailed view)")
print("=" * 80)

for mem in memory_configs:
    has_data = False
    for policy in ['lru', 's3fifo']:
        data = load_json(f'{output_dir}/{policy}_{mem}mb.json')
        results = get_sequence_results(data)
        if results:
            has_data = True
    if not has_data:
        continue

    print(f"\n  === {mem}MB ===")
    print(f"  {'Step':<6}{'Query':<8}", end="")
    for policy in ['lru', 's3fifo']:
        print(f"{policy+' (ms)':<14}", end="")
    print()

    for step in range(len(sequence)):
        q_label = "HOT" if sequence[step] == 0 else "COLD"
        marker = " ◀" if step in post_cold_indices else ""
        print(f"  {step:<6}{q_label:<8}", end="")
        for policy in ['lru', 's3fifo']:
            data = load_json(f'{output_dir}/{policy}_{mem}mb.json')
            results = get_sequence_results(data)
            if results and step < len(results):
                t = results[step]['time_ms']
                print(f"{t:<14}", end="")
            else:
                print(f"{'—':<14}", end="")
        print(marker)

print(f"\n  ◀ = post-cold HOT query (measures recovery after pollution)")

PYEOF

echo ""
echo "🎉 === Done! ==="
echo "  📄 Results: $OUTPUT_DIR/"
