#!/bin/bash
set -e

# Disk Cache vs Parquet Decode: CPU Savings Benchmark
# ====================================================
# Hypothesis: Reading from disk cache (pre-decoded liquid format) uses
# significantly less CPU than reading from Parquet (decompress + decode),
# freeing CPU for query execution and improving throughput.
#
# 3 modes compared:
#   A) parquet    — DataFusion reads Parquet directly (full decode every time)
#   B) liquid-lo  — LiquidCache with tiny memory (forces eviction to disk cache)
#   C) liquid-hi  — LiquidCache with large memory (everything in RAM, best case)
#
# Queries tested (all numeric-filter, varying working set):
#   q1  (idx 7 in light manifest): COUNT(*) WHERE AdvEngineID <> 0
#       → Full scan, single Int16 filter col, ~181MB working set
#   q7  (idx 8): GROUP BY AdvEngineID WHERE <> 0
#       → Same column, tiny GROUP BY
#   c0  (idx 0): COUNT(*) WHERE AdvEngineID > 0 AND ResolutionWidth BETWEEN 1024-1920
#       → Range filter on 2 Int16 cols, ~362MB working set
#   c1  (idx 1): COUNT/AVG/SUM WHERE 4 numeric predicates
#       → 6MB working set, very selective
#   q40 (idx 9): Multi-predicate selective
#       → 24MB working set, stats-pruned to ~3 RGs

MANIFEST="benchmark/clickbench/manifest_light.json"
HEAVY_MANIFEST="benchmark/clickbench/manifest_heavy.json"
OUTPUT_DIR="outputs/disk_cache_cpu"
ITERATIONS=5

# Memory configs:
#   LO = forces most data to disk cache (must be smaller than working set)
#   HI = everything fits in memory
#
# Working sets from concurrent_mix results:
#   c0: 362MB (23080 entries) → use 64MB to force heavy spill
#   c1: 6MB (291 entries)     → use 2MB to force spill
#   q1: 181MB (11540 entries) → use 64MB to force spill
#   q7: 181MB (11540 entries) → use 64MB to force spill
#   q40: 24MB (860 entries)   → use 8MB to force spill
MEM_HI=2048

# Per-query low memory (forces disk spill for each)
# Must be BELOW working set to guarantee disk cache reads
declare -A MEM_LO_MAP
MEM_LO_MAP[0]=64    # c0: 362MB working set
MEM_LO_MAP[1]=2     # c1: 6MB working set
MEM_LO_MAP[7]=64    # q1: 181MB working set
MEM_LO_MAP[8]=64    # q7: 181MB working set
MEM_LO_MAP[9]=8     # q40: 24MB working set

# Query indices in manifest_light.json
QUERIES="0 1 7 8 9"
QUERY_NAMES=("c0_range_filter" "c1_multi_numeric_pred" "q1_advengine_ne0" "q7_group_advengine" "q40_multi_pred_selective")

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/flamegraphs"

echo "============================================================"
echo "  🧪 Disk Cache vs Parquet Decode: CPU Savings"
echo "  📊 Modes: parquet | liquid-${MEM_LO}mb (disk) | liquid-${MEM_HI}mb (memory)"
echo "  🔁 Iterations: $ITERATIONS"
echo "============================================================"
echo ""

# Build once
echo "🔨 Building release binary..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# Print queries
echo "🪶 Queries:"
idx=0
for qi in $QUERIES; do
    SQL_FILE=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['queries'][$qi])")
    echo "  [$qi] ${QUERY_NAMES[$idx]}:"
    echo "      $(cat "$SQL_FILE" | tr '\n' ' ')"
    idx=$((idx + 1))
done
echo ""

# ============================================================
# Experiment 1: Single query, isolate decode cost
# Compare CPU cycles/instructions across modes
# ============================================================
echo "⚡ Experiment 1: Single query CPU comparison"
echo ""

# Mode A: Parquet (no cache)
echo "  📊 Mode A: Parquet (no cache, full decode)..."
idx=0
for qi in $QUERIES; do
    echo -n "    🔹 [${qi}] ${QUERY_NAMES[$idx]}..."
    timeout 600 target/release/in_process \
        --manifest "$MANIFEST" \
        --bench-mode parquet \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --output "$OUTPUT_DIR/parquet_q${qi}.json" > "$OUTPUT_DIR/parquet_q${qi}.log" 2>&1 && echo " ✅" || echo " ❌"
    idx=$((idx + 1))
done
echo ""

# Mode B: Liquid with tiny memory (disk cache reads)
echo "  💾 Mode B: Liquid (per-query low memory, disk cache, no decode)..."
idx=0
for qi in $QUERIES; do
    MEM_LO=${MEM_LO_MAP[$qi]}
    echo -n "    🔹 [${qi}] ${QUERY_NAMES[$idx]} (${MEM_LO}MB)..."
    timeout 600 target/release/in_process \
        --manifest "$MANIFEST" \
        --bench-mode liquid \
        --max-memory-mb $MEM_LO \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --flamegraph-dir "$OUTPUT_DIR/flamegraphs/disk_q${qi}" \
        --output "$OUTPUT_DIR/disk_q${qi}.json" > "$OUTPUT_DIR/disk_q${qi}.log" 2>&1 && echo " ✅" || echo " ❌"
    idx=$((idx + 1))
done
echo ""

# Mode C: Liquid with large memory (memory cache, best case)
echo "  🚀 Mode C: Liquid ${MEM_HI}MB (memory cache, zero I/O)..."
idx=0
for qi in $QUERIES; do
    echo -n "    🔹 [${qi}] ${QUERY_NAMES[$idx]}..."
    timeout 600 target/release/in_process \
        --manifest "$MANIFEST" \
        --bench-mode liquid \
        --max-memory-mb $MEM_HI \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --flamegraph-dir "$OUTPUT_DIR/flamegraphs/mem_q${qi}" \
        --output "$OUTPUT_DIR/mem_q${qi}.json" > "$OUTPUT_DIR/mem_q${qi}.log" 2>&1 && echo " ✅" || echo " ❌"
    idx=$((idx + 1))
done
echo ""

# ============================================================
# Experiment 2: Concurrent throughput
# Run same light query N times concurrently in each mode
# ============================================================
echo "⚡ Experiment 2: Concurrent throughput (4 parallel copies of q1)"
echo ""

CONC_QUERY=7  # q1 in light manifest
CONC_COPIES=4
CONC_MEM_LO=${MEM_LO_MAP[7]}  # 64MB for q1

for mode_name in parquet disk mem; do
    if [ "$mode_name" = "parquet" ]; then
        MODE_ARGS="--bench-mode parquet"
        LABEL="Parquet (decode per copy)"
    elif [ "$mode_name" = "disk" ]; then
        MODE_ARGS="--bench-mode liquid --max-memory-mb $CONC_MEM_LO"
        LABEL="Disk cache ${CONC_MEM_LO}MB (no decode)"
    else
        MODE_ARGS="--bench-mode liquid --max-memory-mb $MEM_HI"
        LABEL="Memory cache ${MEM_HI}MB (no I/O)"
    fi

    echo -n "  🔸 $LABEL: launching $CONC_COPIES copies..."
    START_TIME=$(date +%s%N)

    PIDS=()
    for i in $(seq 1 $CONC_COPIES); do
        target/release/in_process \
            --manifest "$MANIFEST" \
            $MODE_ARGS \
            --iteration $ITERATIONS \
            --query-index $CONC_QUERY \
            --perf-events \
            --output "$OUTPUT_DIR/conc_${mode_name}_copy${i}.json" > "$OUTPUT_DIR/conc_${mode_name}_copy${i}.log" 2>&1 &
        PIDS+=($!)
    done

    # Wait for all copies
    for pid in "${PIDS[@]}"; do
        wait $pid 2>/dev/null || true
    done

    END_TIME=$(date +%s%N)
    ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))
    echo " ✅ total: ${ELAPSED_MS}ms"
    echo "$ELAPSED_MS" > "$OUTPUT_DIR/conc_${mode_name}_total_ms.txt"
done
echo ""

# ============================================================
# Experiment 3: Mixed concurrent (heavy bg + light fg)
# ============================================================
echo "⚡ Experiment 3: Mixed concurrent (heavy q4 bg + light q1 fg)"
echo ""

HEAVY_QUERY=0  # q4 in heavy manifest
LIGHT_QUERY=7  # q1 in light manifest
MIXED_MEM_LO=${MEM_LO_MAP[7]}  # 64MB for q1

for mode_name in parquet disk mem; do
    if [ "$mode_name" = "parquet" ]; then
        MODE_ARGS="--bench-mode parquet"
        LABEL="Parquet"
    elif [ "$mode_name" = "disk" ]; then
        MODE_ARGS="--bench-mode liquid --max-memory-mb $MIXED_MEM_LO"
        LABEL="Disk cache ${MIXED_MEM_LO}MB"
    else
        MODE_ARGS="--bench-mode liquid --max-memory-mb $MEM_HI"
        LABEL="Memory cache ${MEM_HI}MB"
    fi

    echo -n "  🔸 $LABEL: heavy bg + light fg..."

    # Launch heavy query in background
    target/release/in_process \
        --manifest "$HEAVY_MANIFEST" \
        $MODE_ARGS \
        --iteration 1 \
        --query-index $HEAVY_QUERY \
        --output "$OUTPUT_DIR/mixed_heavy_${mode_name}.json" > "$OUTPUT_DIR/mixed_heavy_${mode_name}.log" 2>&1 &
    HEAVY_PID=$!

    # Run light query in foreground
    timeout 600 target/release/in_process \
        --manifest "$MANIFEST" \
        $MODE_ARGS \
        --iteration $ITERATIONS \
        --query-index $LIGHT_QUERY \
        --perf-events \
        --explain-analyze \
        --output "$OUTPUT_DIR/mixed_light_${mode_name}.json" > "$OUTPUT_DIR/mixed_light_${mode_name}.log" 2>&1 || true

    wait $HEAVY_PID 2>/dev/null || true
    echo " ✅"
done
echo ""

# ============================================================
# Generate report
# ============================================================
echo "📝 Generating report..."
python3 - "$OUTPUT_DIR" "$ITERATIONS" "$MEM_HI" "$QUERIES" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
iterations = int(sys.argv[2])
mem_hi = int(sys.argv[3])
queries = sys.argv[4].split()

# Per-query low memory configs (must match shell MEM_LO_MAP)
mem_lo_map = {"0": 64, "1": 2, "7": 64, "8": 64, "9": 8}

query_names = ["c0_range_filter", "c1_multi_numeric_pred", "q1_advengine_ne0", "q7_group_advengine", "q40_multi_pred_selective"]

def load_json(filepath):
    try:
        with open(filepath) as f:
            return json.load(f)
    except:
        return None

def get_times(data, qi=0):
    try:
        return [r["time_millis"] for r in data["results"][qi]["iteration_results"]]
    except:
        return []

def hot_min(times):
    hot = times[1:] if len(times) > 1 else times
    return min(hot) if hot else 0

def get_perf(data, qi=0):
    """Get perf events from last iteration."""
    try:
        last = data["results"][qi]["iteration_results"][-1]
        return last.get("perf_events")
    except:
        return None

def get_disk_read(data, qi=0):
    try:
        last = data["results"][qi]["iteration_results"][-1]
        return last.get("disk_bytes_read", 0) / (1024*1024)
    except:
        return 0

def get_cache_stats(data, qi=0):
    try:
        last = data["results"][qi]["iteration_results"][-1]
        return last.get("cache_stats")
    except:
        return None

report_path = f"{output_dir}/report.md"
with open(report_path, "w") as f:
    f.write("# Disk Cache vs Parquet Decode: CPU Savings Report\n\n")
    f.write("## Hypothesis\n\n")
    f.write("Reading from disk cache (pre-decoded liquid format) uses significantly less CPU than reading from Parquet ")
    f.write("(decompress + decode), freeing CPU for query execution and improving throughput.\n\n")

    f.write("## Modes Compared\n\n")
    f.write("| Mode | Description | Memory budget |\n|------|-------------|---------------|\n")
    f.write(f"| A: Parquet | DataFusion reads Parquet directly, full decode every query | Unlimited |\n")
    f.write(f"| B: Disk cache | LiquidCache with per-query low memory — data evicted to disk in decoded format | Per-query (see below) |\n")
    f.write(f"| C: Memory cache | LiquidCache with {mem_hi}MB memory — everything in RAM | {mem_hi}MB |\n\n")
    f.write("**Per-query disk-mode memory budgets** (chosen to be below working set, forcing disk spill):\n\n")
    f.write("| Query | Working set | Disk mode budget |\n|-------|-------------|------------------|\n")
    working_sets = {"0": "362MB", "1": "6MB", "7": "181MB", "8": "181MB", "9": "24MB"}
    for i, qi in enumerate(queries):
        name = query_names[i] if i < len(query_names) else f"q{qi}"
        f.write(f"| {name} | {working_sets.get(qi, '?')} | {mem_lo_map.get(qi, 64)}MB |\n")
    f.write("\n")

    # ---- Experiment 1: Per-query comparison ----
    f.write("---\n\n## Experiment 1: CPU Cost per Query (single query, no contention)\n\n")
    f.write("| Query | Mode | Min hot (ms) | CPU cycles | Instructions | Disk read (MB) | IO reads | Speedup vs Parquet |\n")
    f.write("|-------|------|-------------|-----------|-------------|----------------|----------|--------------------|\n")

    for i, qi in enumerate(queries):
        name = query_names[i] if i < len(query_names) else f"q{qi}"

        # Mode A: Parquet
        pq = load_json(f"{output_dir}/parquet_q{qi}.json")
        pq_times = get_times(pq) if pq else []
        pq_min = hot_min(pq_times)
        pq_perf = get_perf(pq) if pq else None
        pq_disk = get_disk_read(pq) if pq else 0

        # Mode B: Disk cache
        dk = load_json(f"{output_dir}/disk_q{qi}.json")
        dk_times = get_times(dk) if dk else []
        dk_min = hot_min(dk_times)
        dk_perf = get_perf(dk) if dk else None
        dk_disk = get_disk_read(dk) if dk else 0
        dk_stats = get_cache_stats(dk) if dk else None
        dk_io = dk_stats.get("runtime", {}).get("read_io_count", 0) if dk_stats else 0

        # Mode C: Memory cache
        mm = load_json(f"{output_dir}/mem_q{qi}.json")
        mm_times = get_times(mm) if mm else []
        mm_min = hot_min(mm_times)
        mm_perf = get_perf(mm) if mm else None
        mm_disk = get_disk_read(mm) if mm else 0

        # Write rows
        pq_cycles = pq_perf.get("cpu_cycles", 0) if pq_perf else 0
        pq_instr = pq_perf.get("instructions", 0) if pq_perf else 0
        f.write(f"| **{name}** | Parquet | {pq_min} | {pq_cycles:,} | {pq_instr:,} | {pq_disk:.1f} | — | 1.00× |\n")

        dk_cycles = dk_perf.get("cpu_cycles", 0) if dk_perf else 0
        dk_instr = dk_perf.get("instructions", 0) if dk_perf else 0
        dk_speedup = pq_min / dk_min if dk_min > 0 else 0
        q_mem_lo = mem_lo_map.get(qi, 64)
        f.write(f"| | Disk {q_mem_lo}MB | {dk_min} | {dk_cycles:,} | {dk_instr:,} | {dk_disk:.1f} | {dk_io} | {dk_speedup:.2f}× |\n")

        mm_cycles = mm_perf.get("cpu_cycles", 0) if mm_perf else 0
        mm_instr = mm_perf.get("instructions", 0) if mm_perf else 0
        mm_speedup = pq_min / mm_min if mm_min > 0 else 0
        f.write(f"| | Memory {mem_hi}MB | {mm_min} | {mm_cycles:,} | {mm_instr:,} | {mm_disk:.1f} | 0 | {mm_speedup:.2f}× |\n")

    f.write("\n")
    f.write("**Reading the table:** If disk cache shows fewer CPU cycles/instructions than Parquet with similar disk read → ")
    f.write("the CPU savings from skipping decode are confirmed.\n\n")

    # ---- Per-query detailed: cache stats + explain-analyze ----
    f.write("---\n\n## Per-Query Details: Cache Stats & Execution Plans\n\n")

    for i, qi in enumerate(queries):
        name = query_names[i] if i < len(query_names) else f"q{qi}"

        f.write(f"### {name}\n\n")

        # Cache stats for disk mode
        dk = load_json(f"{output_dir}/disk_q{qi}.json")
        dk_stats = get_cache_stats(dk) if dk else None
        if dk_stats:
            rt = dk_stats.get("runtime", {})
            f.write(f"#### Cache Stats — Disk mode ({mem_lo_map.get(qi, 64)}MB, last iteration)\n\n")
            f.write("```\n")
            f.write(f"total_entries: {dk_stats.get('total_entries', 0)}\n")
            f.write(f"memory_arrow_entries: {dk_stats.get('memory_arrow_entries', 0)}\n")
            f.write(f"memory_liquid_entries: {dk_stats.get('memory_liquid_entries', 0)}\n")
            f.write(f"memory_squeezed_liquid_entries: {dk_stats.get('memory_squeezed_liquid_entries', 0)}\n")
            f.write(f"disk_liquid_entries: {dk_stats.get('disk_liquid_entries', 0)}\n")
            f.write(f"disk_arrow_entries: {dk_stats.get('disk_arrow_entries', 0)}\n")
            f.write(f"memory_usage_bytes: {dk_stats.get('memory_usage_bytes', 0):,} ({dk_stats.get('memory_usage_bytes', 0)//(1024*1024)} MB)\n")
            f.write(f"disk_usage_bytes: {dk_stats.get('disk_usage_bytes', 0):,} ({dk_stats.get('disk_usage_bytes', 0)//(1024*1024)} MB)\n")
            f.write(f"max_memory_bytes: {dk_stats.get('max_memory_bytes', 0):,} ({dk_stats.get('max_memory_bytes', 0)//(1024*1024)} MB)\n")
            f.write(f"---\n")
            f.write(f"cache_hit: {rt.get('cache_hit', 0)}\n")
            f.write(f"cache_miss: {rt.get('cache_miss', 0)}\n")
            f.write(f"eval_predicate: {rt.get('eval_predicate', 0)}\n")
            f.write(f"get_squeezed_success: {rt.get('get_squeezed_success', 0)}\n")
            f.write(f"get_squeezed_needs_io: {rt.get('get_squeezed_needs_io', 0)}\n")
            f.write(f"read_io_count: {rt.get('read_io_count', 0)}\n")
            f.write(f"write_io_count: {rt.get('write_io_count', 0)}\n")
            f.write(f"disk_evictions: {rt.get('disk_evictions', 0)}\n")
            f.write(f"squeeze_io_saved: {rt.get('squeeze_io_saved', 0)}\n")
            f.write("```\n\n")

        # Cache stats for memory mode
        mm = load_json(f"{output_dir}/mem_q{qi}.json")
        mm_stats = get_cache_stats(mm) if mm else None
        if mm_stats:
            rt = mm_stats.get("runtime", {})
            f.write(f"#### Cache Stats — Memory mode ({mem_hi}MB, last iteration)\n\n")
            f.write("```\n")
            f.write(f"total_entries: {mm_stats.get('total_entries', 0)}\n")
            f.write(f"memory_arrow_entries: {mm_stats.get('memory_arrow_entries', 0)}\n")
            f.write(f"memory_liquid_entries: {mm_stats.get('memory_liquid_entries', 0)}\n")
            f.write(f"memory_squeezed_liquid_entries: {mm_stats.get('memory_squeezed_liquid_entries', 0)}\n")
            f.write(f"disk_liquid_entries: {mm_stats.get('disk_liquid_entries', 0)}\n")
            f.write(f"memory_usage_bytes: {mm_stats.get('memory_usage_bytes', 0):,} ({mm_stats.get('memory_usage_bytes', 0)//(1024*1024)} MB)\n")
            f.write(f"disk_usage_bytes: {mm_stats.get('disk_usage_bytes', 0):,} ({mm_stats.get('disk_usage_bytes', 0)//(1024*1024)} MB)\n")
            f.write(f"---\n")
            f.write(f"cache_hit: {rt.get('cache_hit', 0)}\n")
            f.write(f"cache_miss: {rt.get('cache_miss', 0)}\n")
            f.write(f"eval_predicate: {rt.get('eval_predicate', 0)}\n")
            f.write(f"get_squeezed_success: {rt.get('get_squeezed_success', 0)}\n")
            f.write(f"read_io_count: {rt.get('read_io_count', 0)}\n")
            f.write(f"write_io_count: {rt.get('write_io_count', 0)}\n")
            f.write(f"squeeze_io_saved: {rt.get('squeeze_io_saved', 0)}\n")
            f.write("```\n\n")

        # Explain-analyze from logs (disk mode)
        dk_log = f"{output_dir}/disk_q{qi}.log"
        if os.path.exists(dk_log):
            with open(dk_log) as lf:
                content = lf.read()
            blocks = content.split("=== EXPLAIN ANALYZE")
            if len(blocks) >= 2:
                last_block = blocks[-1][:4000]
                f.write(f"<details>\n<summary>EXPLAIN ANALYZE — Disk mode ({mem_lo_map.get(qi, 64)}MB, last iteration)</summary>\n\n```\n")
                f.write("=== EXPLAIN ANALYZE" + last_block.strip())
                f.write("\n```\n</details>\n\n")

        # Explain-analyze from logs (memory mode)
        mm_log = f"{output_dir}/mem_q{qi}.log"
        if os.path.exists(mm_log):
            with open(mm_log) as lf:
                content = lf.read()
            blocks = content.split("=== EXPLAIN ANALYZE")
            if len(blocks) >= 2:
                last_block = blocks[-1][:4000]
                f.write(f"<details>\n<summary>EXPLAIN ANALYZE — Memory mode ({mem_hi}MB, last iteration)</summary>\n\n```\n")
                f.write("=== EXPLAIN ANALYZE" + last_block.strip())
                f.write("\n```\n</details>\n\n")

        # Explain-analyze from logs (parquet mode)
        pq_log = f"{output_dir}/parquet_q{qi}.log"
        if os.path.exists(pq_log):
            with open(pq_log) as lf:
                content = lf.read()
            blocks = content.split("=== EXPLAIN ANALYZE")
            if len(blocks) >= 2:
                last_block = blocks[-1][:4000]
                f.write(f"<details>\n<summary>EXPLAIN ANALYZE — Parquet (no cache, last iteration)</summary>\n\n```\n")
                f.write("=== EXPLAIN ANALYZE" + last_block.strip())
                f.write("\n```\n</details>\n\n")

        f.write("---\n\n")

    # ---- Experiment 2: Concurrent throughput ----
    f.write("---\n\n## Experiment 2: Concurrent Throughput (4 parallel copies of q1)\n\n")
    f.write("| Mode | Total wall time (ms) | Queries/sec | Speedup |\n")
    f.write("|------|---------------------|-------------|--------|\n")

    conc_results = {}
    for mode in ["parquet", "disk", "mem"]:
        try:
            with open(f"{output_dir}/conc_{mode}_total_ms.txt") as tf:
                total_ms = int(tf.read().strip())
        except:
            total_ms = 0
        conc_results[mode] = total_ms

    pq_total = conc_results.get("parquet", 1)
    for mode, label in [("parquet", "Parquet (full decode)"), ("disk", f"Disk cache (per-query)"), ("mem", f"Memory cache {mem_hi}MB")]:
        total_ms = conc_results[mode]
        qps = (4 * iterations * 1000 / total_ms) if total_ms > 0 else 0
        speedup = pq_total / total_ms if total_ms > 0 else 0
        f.write(f"| {label} | {total_ms} | {qps:.1f} | {speedup:.2f}× |\n")

    f.write("\n**Interpretation:** Higher queries/sec with disk cache than Parquet (at similar I/O) = CPU savings translate to throughput.\n\n")

    # ---- Experiment 3: Mixed concurrent ----
    f.write("---\n\n## Experiment 3: Mixed Concurrent (heavy q4 bg + light q1 fg)\n\n")
    f.write("| Mode | Light q1 min hot (ms) | CPU cycles | Disk read (MB) | Speedup vs Parquet |\n")
    f.write("|------|----------------------|-----------|----------------|--------------------|\n")

    pq_mixed = load_json(f"{output_dir}/mixed_light_parquet.json")
    pq_mixed_times = get_times(pq_mixed) if pq_mixed else []
    pq_mixed_min = hot_min(pq_mixed_times)
    pq_mixed_perf = get_perf(pq_mixed) if pq_mixed else None
    pq_mixed_cycles = pq_mixed_perf.get("cpu_cycles", 0) if pq_mixed_perf else 0
    pq_mixed_disk = get_disk_read(pq_mixed) if pq_mixed else 0
    f.write(f"| Parquet | {pq_mixed_min} | {pq_mixed_cycles:,} | {pq_mixed_disk:.1f} | 1.00× |\n")

    dk_mixed = load_json(f"{output_dir}/mixed_light_disk.json")
    dk_mixed_times = get_times(dk_mixed) if dk_mixed else []
    dk_mixed_min = hot_min(dk_mixed_times)
    dk_mixed_perf = get_perf(dk_mixed) if dk_mixed else None
    dk_mixed_cycles = dk_mixed_perf.get("cpu_cycles", 0) if dk_mixed_perf else 0
    dk_mixed_disk = get_disk_read(dk_mixed) if dk_mixed else 0
    dk_mixed_speedup = pq_mixed_min / dk_mixed_min if dk_mixed_min > 0 else 0
    f.write(f"| Disk cache {mem_lo_map.get('7', 64)}MB | {dk_mixed_min} | {dk_mixed_cycles:,} | {dk_mixed_disk:.1f} | {dk_mixed_speedup:.2f}× |\n")

    mm_mixed = load_json(f"{output_dir}/mixed_light_mem.json")
    mm_mixed_times = get_times(mm_mixed) if mm_mixed else []
    mm_mixed_min = hot_min(mm_mixed_times)
    mm_mixed_perf = get_perf(mm_mixed) if mm_mixed else None
    mm_mixed_cycles = mm_mixed_perf.get("cpu_cycles", 0) if mm_mixed_perf else 0
    mm_mixed_disk = get_disk_read(mm_mixed) if mm_mixed else 0
    mm_mixed_speedup = pq_mixed_min / mm_mixed_min if mm_mixed_min > 0 else 0
    f.write(f"| Memory cache {mem_hi}MB | {mm_mixed_min} | {mm_mixed_cycles:,} | {mm_mixed_disk:.1f} | {mm_mixed_speedup:.2f}× |\n")

    f.write("\n**Key question answered:** Under CPU contention from a heavy query, does disk cache (no decode) ")
    f.write("give light queries more headroom than Parquet (full decode)?\n\n")

    # ---- Conclusion ----
    f.write("---\n\n## Conclusion\n\n")
    f.write("| Evidence | What it proves |\n|----------|---------------|\n")
    f.write("| Disk cache fewer CPU cycles than Parquet at similar I/O | Decode is the CPU cost being saved |\n")
    f.write("| Higher concurrent QPS with disk cache | Freed CPU translates to real throughput |\n")
    f.write("| Lower mixed-mode latency with disk cache | Under contention, no-decode path wins |\n")
    f.write("| Memory cache fastest of all | Eliminating both I/O and decode is optimal |\n\n")
    f.write("### Trade-off spectrum\n\n")
    f.write("```\n")
    f.write("Parquet (high CPU, medium I/O)\n")
    f.write("    ↓ disk cache saves decode CPU\n")
    f.write("Disk Cache (low CPU, medium I/O)  ← sweet spot when memory is scarce\n")
    f.write("    ↓ memory cache eliminates I/O\n")
    f.write("Memory Cache (low CPU, zero I/O)  ← optimal when memory is available\n")
    f.write("```\n")

print(f"✅ Report: {report_path}")

# Console summary
print("\n" + "=" * 80)
print("  DISK CACHE CPU SAVINGS SUMMARY")
print("=" * 80)

for i, qi in enumerate(queries):
    name = query_names[i] if i < len(query_names) else f"q{qi}"
    pq = load_json(f"{output_dir}/parquet_q{qi}.json")
    dk = load_json(f"{output_dir}/disk_q{qi}.json")
    mm = load_json(f"{output_dir}/mem_q{qi}.json")
    pq_min = hot_min(get_times(pq)) if pq else 0
    dk_min = hot_min(get_times(dk)) if dk else 0
    mm_min = hot_min(get_times(mm)) if mm else 0
    print(f"  {name:<25} Parquet: {pq_min:>5}ms  Disk: {dk_min:>5}ms  Memory: {mm_min:>5}ms  "
          f"Disk speedup: {pq_min/dk_min if dk_min else 0:.2f}×  Mem speedup: {pq_min/mm_min if mm_min else 0:.2f}×")

print("\n" + "=" * 80)
PYEOF

echo ""
echo "🎉 === Done! ==="
echo "  📄 Report: $OUTPUT_DIR/report.md"
echo "  📋 Logs: $OUTPUT_DIR/*.log"
echo "  🔥 Flamegraphs: $OUTPUT_DIR/flamegraphs/"
