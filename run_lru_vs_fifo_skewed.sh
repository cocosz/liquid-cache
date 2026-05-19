#!/bin/bash
set -e

# LRU vs S3-FIFO under Skewed Access Patterns
#
# Design:
#   Use Q19 (UserID, 668MB working set) as HOT and Q7 (AdvEngineID, 31MB) as COLD.
#   Both cache different columns but share the same memory budget, so running COLD
#   forces eviction of HOT's entries. Memory set below Q19's working set to create
#   eviction pressure.
#
#   The hypothesis: after COLD query runs and evicts some HOT entries, LRU should
#   recover faster because it retained the most-recently-accessed HOT entries.
#   But for sequential scans, LRU ordering == insertion ordering, so we expect
#   no difference (confirming the v2 sweet-spot findings).
#
# Queries (from manifest.json):
#   Index 19 (HOT): SELECT "UserID" FROM hits WHERE "UserID" = 435090932899640449
#   Index 7  (COLD): SELECT "AdvEngineID", COUNT(*) FROM hits WHERE "AdvEngineID" <> 0 ...
#
# Sequence: HOT HOT HOT COLD HOT HOT HOT COLD HOT HOT HOT COLD
# Memory budgets: 128, 256, 384, 512 (below Q19's 668MB working set)

OUTPUT_DIR="outputs/lru_vs_fifo_skewed"
MANIFEST="benchmark/clickbench/manifest.json"

# Sequence: 3 cycles of (HOT HOT HOT COLD)
SEQUENCE="19,19,19,7,19,19,19,7,19,19,19,7"

# Memory budgets: below Q19 working set (668MB) to force evictions
MEMORY_CONFIGS="128 256 384 512"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "============================================================"
echo "  🧪 LRU vs S3-FIFO Skewed Access Experiment"
echo "  Manifest: $MANIFEST"
echo "  Sequence: $SEQUENCE"
echo "  Memory configs: $MEMORY_CONFIGS MB"
echo "  HOT = Q19 (UserID, 668MB working set)"
echo "  COLD = Q7  (AdvEngineID, 31MB working set)"
echo "============================================================"
echo ""

# Build once
echo "🔨 Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# Run parquet baselines
echo "📊 Running parquet baselines..."
for Q in 19 7; do
    echo -n "  Q$Q parquet (5 iters)..."
    timeout 300 target/release/in_process \
        --manifest "$MANIFEST" \
        --bench-mode parquet \
        --query-index $Q \
        --iteration 5 \
        --output "$OUTPUT_DIR/parquet_q${Q}.json" > "$OUTPUT_DIR/parquet_q${Q}.log" 2>&1 && echo " ✅" || echo " ❌"
done
echo ""

# Run liquid baselines (unlimited memory)
echo "📊 Running liquid baselines (unlimited memory)..."
for Q in 19 7; do
    echo -n "  Q$Q liquid unlimited..."
    timeout 300 target/release/in_process \
        --manifest "$MANIFEST" \
        --bench-mode liquid \
        --query-index $Q \
        --iteration 5 \
        --explain-analyze \
        --output "$OUTPUT_DIR/baseline_q${Q}.json" > "$OUTPUT_DIR/baseline_q${Q}.log" 2>&1 && echo " ✅" || echo " ❌"
done
echo ""

# Run sequence for each policy × memory budget
for POLICY in lru s3fifo; do
    echo "═══════════════════════════════════════════════════════"
    echo "  Policy: $POLICY"
    echo "═══════════════════════════════════════════════════════"
    for MEM in $MEMORY_CONFIGS; do
        echo -n "  💾 ${MEM}MB..."
        if timeout 1200 target/release/in_process \
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

HOT_Q = 19
COLD_Q = 7

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
print("  BASELINES")
print("=" * 80)
for q in [HOT_Q, COLD_Q]:
    label = "HOT" if q == HOT_Q else "COLD"
    data = load_json(f'{output_dir}/baseline_q{q}.json')
    if data:
        times = [r['time_millis'] for r in data['results'][0]['iteration_results']]
        stats = data['results'][0]['iteration_results'][-1].get('cache_stats')
        entries = stats.get('total_entries', 0) if stats else 0
        mem_mb = stats.get('memory_usage_bytes', 0) / (1024*1024) if stats else 0
        print(f"  Q{q} ({label}) liquid unlimited: times={times}, working_set={mem_mb:.1f}MB, entries={entries}")

    data = load_json(f'{output_dir}/parquet_q{q}.json')
    if data:
        times = [r['time_millis'] for r in data['results'][0]['iteration_results']]
        hot = min(times[1:]) if len(times) > 1 else times[0]
        print(f"  Q{q} ({label}) parquet: times={times}, min_hot={hot}ms")

print()

# Analysis per policy per memory budget
print("=" * 80)
print("  SEQUENCE RESULTS")
print("=" * 80)

# Identify "post-cold" HOT queries: indices where query is HOT and previous was COLD
post_cold_indices = []
for i, q in enumerate(sequence):
    if q == HOT_Q and i > 0 and sequence[i-1] == COLD_Q:
        post_cold_indices.append(i)

print(f"\n  Sequence: {['Q'+str(q) for q in sequence]}")
print(f"  Post-cold HOT indices: {post_cold_indices}")
print(f"  (Q{HOT_Q} runs immediately after Q{COLD_Q} evicts some of its entries)\n")

header = f"  {'Budget':<8}{'Policy':<10}{'PostCold Q19':<14}{'All Q19 avg':<14}{'Q7 avg':<12}{'Entries':<10}{'MemMB':<10}{'DiskMB'}"
print(header)
print(f"  {'-'*80}")

for mem in memory_configs:
    for policy in ['lru', 's3fifo']:
        data = load_json(f'{output_dir}/{policy}_{mem}mb.json')
        results = get_sequence_results(data)
        if not results:
            print(f"  {mem:<8}{policy:<10}SKIP")
            continue

        # Separate HOT and COLD results
        hot_times = [results[i]['time_ms'] for i in range(len(sequence)) if sequence[i] == HOT_Q]
        cold_times = [results[i]['time_ms'] for i in range(len(sequence)) if sequence[i] == COLD_Q]
        post_cold_times = [results[i]['time_ms'] for i in post_cold_indices if i < len(results)]

        hot_avg = sum(hot_times) / len(hot_times) if hot_times else 0
        cold_avg = sum(cold_times) / len(cold_times) if cold_times else 0
        post_cold_avg = sum(post_cold_times) / len(post_cold_times) if post_cold_times else 0

        # Cache state from last step
        last_stats = results[-1]['stats'] if results else None
        entries = last_stats.get('total_entries', 0) if last_stats else 0
        mem_mb = last_stats.get('memory_usage_bytes', 0) / (1024*1024) if last_stats else 0
        disk_mb = last_stats.get('disk_usage_bytes', 0) / (1024*1024) if last_stats else 0

        print(f"  {mem:<8}{policy:<10}{post_cold_avg:<14.1f}{hot_avg:<14.1f}{cold_avg:<12.1f}{entries:<10}{mem_mb:<10.1f}{disk_mb:.1f}")

# Detailed per-step view
print(f"\n{'=' * 80}")
print("  PER-STEP LATENCY (ms)")
print("=" * 80)

for mem in memory_configs:
    has_data = False
    for policy in ['lru', 's3fifo']:
        data = load_json(f'{output_dir}/{policy}_{mem}mb.json')
        if get_sequence_results(data):
            has_data = True
    if not has_data:
        continue

    print(f"\n  === {mem}MB ===")
    print(f"  {'Step':<6}{'Query':<8}", end="")
    for policy in ['lru', 's3fifo']:
        print(f"{policy:<14}", end="")
    print("  delta")

    for step in range(len(sequence)):
        q_label = f"Q{sequence[step]}"
        marker = " ◀" if step in post_cold_indices else ""
        print(f"  {step:<6}{q_label:<8}", end="")
        times = {}
        for policy in ['lru', 's3fifo']:
            data = load_json(f'{output_dir}/{policy}_{mem}mb.json')
            results = get_sequence_results(data)
            if results and step < len(results):
                t = results[step]['time_ms']
                times[policy] = t
                print(f"{t:<14}", end="")
            else:
                print(f"{'—':<14}", end="")
        if 'lru' in times and 's3fifo' in times:
            diff = times['s3fifo'] - times['lru']
            sign = "+" if diff > 0 else ""
            print(f"  {sign}{diff}ms", end="")
        print(marker)

print(f"\n  ◀ = post-cold Q19 (key measurement point)")

PYEOF

echo ""
echo "🎉 === Done! ==="
echo "  📄 Results: $OUTPUT_DIR/"
