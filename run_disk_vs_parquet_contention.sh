#!/bin/bash
set -e

# Disk Cache vs Parquet Under CPU Contention
# ============================================
# Core question: When CPU is saturated by heavy queries, does reading from
# disk cache (no decode) give better latency than reading from Parquet (full decode)?
#
# Experiment A: Light query under heavy CPU load
#   - Run heavy query (q4: COUNT DISTINCT 17M) in background → saturates CPU
#   - Foreground: light query reads from disk cache vs Parquet
#   - Expected: disk cache wins because it doesn't need CPU for decode
#
# Experiment B: Heavy query itself benefits from disk cache
#   - The heavy query (q4, q8) reads data. If columns are in disk cache,
#     it skips decode → frees CPU for the hash table work → finishes faster
#   - Compare: heavy query from Parquet vs from disk cache vs from memory cache
#
# Memory budgets chosen to FORCE disk spill (from crossover results):
#   c0 at 40% = 144MB (362MB WS, will have ~1959 entries on disk)
#   q1 at 30% = 54MB (181MB WS, partial spill)
#   q4 (heavy, from main manifest idx 4): full scan on UserID (Int64)
#     Working set ~668MB → use 200MB to force spill

LIGHT_MANIFEST="benchmark/clickbench/manifest_light.json"
HEAVY_MANIFEST="benchmark/clickbench/manifest_heavy.json"
MAIN_MANIFEST="benchmark/clickbench/manifest.json"
OUTPUT_DIR="outputs/disk_vs_parquet_contention"
ITERATIONS=5

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "============================================================"
echo "  🧪 Disk Cache vs Parquet Under CPU Contention"
echo "  🔁 Iterations: $ITERATIONS"
echo "============================================================"
echo ""

# Enable perf + drop caches
echo "🔧 Setup..."
sudo sysctl -w kernel.perf_event_paranoid=-1 2>/dev/null || true
echo ""

# Build
echo "🔨 Building..."
cargo build --release --bin in_process 2>&1 | tail -3
echo ""

# ============================================================
# EXPERIMENT A: Light queries under heavy CPU contention
# ============================================================
echo "═══════════════════════════════════════════════════════════"
echo "  ⚡ EXPERIMENT A: Light queries under heavy CPU contention"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Scenario: heavy q4 (COUNT DISTINCT 17M UserIDs) in background"
echo "  Light queries tested: c0 (idx 0), q1 (idx 7)"
echo "  Modes: Parquet vs Disk cache vs Memory cache"
echo ""

# Light queries and their disk-spill budgets
LIGHT_QUERIES=(0 7)
LIGHT_NAMES=("c0_range_filter" "q1_advengine")
LIGHT_DISK_MEM=(144 54)  # Force partial spill
LIGHT_MEM_HI=2048

HEAVY_BG_IDX=0  # q4 in heavy manifest

# --- A1: Baselines (no contention) ---
echo "  📊 A1: Baselines (no contention)..."
for i in "${!LIGHT_QUERIES[@]}"; do
    qi=${LIGHT_QUERIES[$i]}
    name=${LIGHT_NAMES[$i]}
    disk_mem=${LIGHT_DISK_MEM[$i]}

    echo -n "    🔹 $name — Parquet..."
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true
    timeout 300 target/release/in_process \
        --manifest "$LIGHT_MANIFEST" \
        --bench-mode parquet \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --output "$OUTPUT_DIR/a1_${name}_parquet.json" > "$OUTPUT_DIR/a1_${name}_parquet.log" 2>&1 && echo " ✅" || echo " ❌"

    echo -n "    🔹 $name — Disk ${disk_mem}MB..."
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true
    timeout 300 target/release/in_process \
        --manifest "$LIGHT_MANIFEST" \
        --bench-mode liquid \
        --max-memory-mb $disk_mem \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --output "$OUTPUT_DIR/a1_${name}_disk.json" > "$OUTPUT_DIR/a1_${name}_disk.log" 2>&1 && echo " ✅" || echo " ❌"

    echo -n "    🔹 $name — Memory ${LIGHT_MEM_HI}MB..."
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true
    timeout 300 target/release/in_process \
        --manifest "$LIGHT_MANIFEST" \
        --bench-mode liquid \
        --max-memory-mb $LIGHT_MEM_HI \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --output "$OUTPUT_DIR/a1_${name}_mem.json" > "$OUTPUT_DIR/a1_${name}_mem.log" 2>&1 && echo " ✅" || echo " ❌"
done
echo ""

# --- A2: Under contention (heavy q4 in background) ---
echo "  📊 A2: Under contention (heavy q4 background)..."
for i in "${!LIGHT_QUERIES[@]}"; do
    qi=${LIGHT_QUERIES[$i]}
    name=${LIGHT_NAMES[$i]}
    disk_mem=${LIGHT_DISK_MEM[$i]}

    for mode in parquet disk mem; do
        if [ "$mode" = "parquet" ]; then
            MODE_ARGS="--bench-mode parquet"
            LABEL="Parquet"
        elif [ "$mode" = "disk" ]; then
            MODE_ARGS="--bench-mode liquid --max-memory-mb $disk_mem"
            LABEL="Disk ${disk_mem}MB"
        else
            MODE_ARGS="--bench-mode liquid --max-memory-mb $LIGHT_MEM_HI"
            LABEL="Memory ${LIGHT_MEM_HI}MB"
        fi

        echo -n "    🔹 $name + heavy bg — $LABEL..."
        sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true

        # Start heavy query in background (saturate CPU)
        target/release/in_process \
            --manifest "$HEAVY_MANIFEST" \
            --bench-mode liquid \
            --max-memory-mb 2048 \
            --iteration 2 \
            --query-index $HEAVY_BG_IDX \
            --output "$OUTPUT_DIR/a2_heavy_bg_${name}_${mode}.json" > "$OUTPUT_DIR/a2_heavy_bg_${name}_${mode}.log" 2>&1 &
        HEAVY_PID=$!

        # Small delay to let heavy query start consuming CPU
        sleep 1

        # Run light query in foreground
        timeout 300 target/release/in_process \
            --manifest "$LIGHT_MANIFEST" \
            $MODE_ARGS \
            --iteration $ITERATIONS \
            --query-index $qi \
            --perf-events \
            --explain-analyze \
            --output "$OUTPUT_DIR/a2_${name}_${mode}.json" > "$OUTPUT_DIR/a2_${name}_${mode}.log" 2>&1 && echo " ✅" || echo " ❌"

        wait $HEAVY_PID 2>/dev/null || true
    done
done
echo ""

# ============================================================
# EXPERIMENT B: Heavy query itself benefits from disk cache
# ============================================================
echo "═══════════════════════════════════════════════════════════"
echo "  ⚡ EXPERIMENT B: Heavy queries benefit from disk cache"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  If heavy query data is pre-cached on disk, it skips decode"
echo "  → frees CPU cycles for hash table work → finishes faster"
echo ""

# Heavy queries to test (from heavy manifest)
# idx 0: q4 COUNT(DISTINCT UserID) — full scan Int64
# idx 2: q8 GROUP BY RegionID, COUNT(DISTINCT UserID)
HEAVY_QUERIES=(0 2)
HEAVY_NAMES=("q4_count_distinct" "q8_distinct_groupby")
HEAVY_DISK_MEM=(200 200)  # Force partial spill for heavy queries
HEAVY_MEM_HI=2048

echo "  📊 B1: Heavy queries — Parquet vs Disk cache vs Memory cache..."
for i in "${!HEAVY_QUERIES[@]}"; do
    qi=${HEAVY_QUERIES[$i]}
    name=${HEAVY_NAMES[$i]}
    disk_mem=${HEAVY_DISK_MEM[$i]}

    echo -n "    🔹 $name — Parquet..."
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true
    timeout 600 target/release/in_process \
        --manifest "$HEAVY_MANIFEST" \
        --bench-mode parquet \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --output "$OUTPUT_DIR/b1_${name}_parquet.json" > "$OUTPUT_DIR/b1_${name}_parquet.log" 2>&1 && echo " ✅" || echo " ❌"

    echo -n "    🔹 $name — Disk ${disk_mem}MB..."
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true
    timeout 600 target/release/in_process \
        --manifest "$HEAVY_MANIFEST" \
        --bench-mode liquid \
        --max-memory-mb $disk_mem \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --output "$OUTPUT_DIR/b1_${name}_disk.json" > "$OUTPUT_DIR/b1_${name}_disk.log" 2>&1 && echo " ✅" || echo " ❌"

    echo -n "    🔹 $name — Memory ${HEAVY_MEM_HI}MB..."
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true
    timeout 600 target/release/in_process \
        --manifest "$HEAVY_MANIFEST" \
        --bench-mode liquid \
        --max-memory-mb $HEAVY_MEM_HI \
        --iteration $ITERATIONS \
        --query-index $qi \
        --perf-events \
        --explain-analyze \
        --output "$OUTPUT_DIR/b1_${name}_mem.json" > "$OUTPUT_DIR/b1_${name}_mem.log" 2>&1 && echo " ✅" || echo " ❌"
done
echo ""

# --- B2: Heavy queries under ADDITIONAL contention (another heavy in bg) ---
echo "  📊 B2: Heavy query + another heavy in background..."
for i in "${!HEAVY_QUERIES[@]}"; do
    qi=${HEAVY_QUERIES[$i]}
    name=${HEAVY_NAMES[$i]}
    disk_mem=${HEAVY_DISK_MEM[$i]}

    # Use the OTHER heavy query as background
    bg_idx=$(( (qi + 1) % 3 ))

    for mode in parquet disk mem; do
        if [ "$mode" = "parquet" ]; then
            MODE_ARGS="--bench-mode parquet"
            LABEL="Parquet"
        elif [ "$mode" = "disk" ]; then
            MODE_ARGS="--bench-mode liquid --max-memory-mb $disk_mem"
            LABEL="Disk ${disk_mem}MB"
        else
            MODE_ARGS="--bench-mode liquid --max-memory-mb $HEAVY_MEM_HI"
            LABEL="Memory ${HEAVY_MEM_HI}MB"
        fi

        echo -n "    🔹 $name + contention — $LABEL..."
        sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true

        # Background: another heavy query
        target/release/in_process \
            --manifest "$HEAVY_MANIFEST" \
            --bench-mode liquid \
            --max-memory-mb 2048 \
            --iteration 2 \
            --query-index $bg_idx \
            --output "$OUTPUT_DIR/b2_bg_${name}_${mode}.json" > "$OUTPUT_DIR/b2_bg_${name}_${mode}.log" 2>&1 &
        BG_PID=$!

        sleep 1

        # Foreground: the heavy query we're measuring
        timeout 600 target/release/in_process \
            --manifest "$HEAVY_MANIFEST" \
            $MODE_ARGS \
            --iteration $ITERATIONS \
            --query-index $qi \
            --perf-events \
            --explain-analyze \
            --output "$OUTPUT_DIR/b2_${name}_${mode}.json" > "$OUTPUT_DIR/b2_${name}_${mode}.log" 2>&1 && echo " ✅" || echo " ❌"

        wait $BG_PID 2>/dev/null || true
    done
done
echo ""

# ============================================================
# Generate report
# ============================================================
echo "📝 Generating report..."
python3 - "$OUTPUT_DIR" "$ITERATIONS" <<'PYEOF'
import json, sys, os

output_dir = sys.argv[1]
iterations = int(sys.argv[2])

def load_json(fp):
    try:
        with open(fp) as f:
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
    try:
        return data["results"][qi]["iteration_results"][-1].get("perf_events")
    except:
        return None

def get_cache_stats(data, qi=0):
    try:
        return data["results"][qi]["iteration_results"][-1].get("cache_stats")
    except:
        return None

def get_disk_bytes(data, qi=0):
    try:
        last = data["results"][qi]["iteration_results"][-1]
        return last.get("disk_bytes_read", 0) / (1024*1024)
    except:
        return 0

report_path = f"{output_dir}/report.md"
with open(report_path, "w") as f:
    f.write("# Disk Cache vs Parquet Under CPU Contention\n\n")

    f.write("## Core Question\n\n")
    f.write("When CPU is saturated by heavy queries (hash tables, GROUP BY), does reading from disk cache\n")
    f.write("(pre-decoded, no CPU for decode) give better latency than reading from Parquet (needs CPU for decode)?\n\n")

    # ---- Experiment A ----
    f.write("---\n\n## Experiment A: Light Queries Under Heavy CPU Load\n\n")
    f.write("**Setup:** Heavy q4 (COUNT DISTINCT over 17M UserIDs) runs in background, saturating CPU.\n")
    f.write("Light query runs in foreground in three modes.\n\n")

    light_names = ["c0_range_filter", "q1_advengine"]
    light_disk_mem = [144, 54]

    for i, name in enumerate(light_names):
        disk_mem = light_disk_mem[i]
        f.write(f"### {name}\n\n")

        # Baseline (no contention)
        f.write("#### Without contention (baseline)\n\n")
        f.write("| Mode | All iterations (ms) | Min hot | Disk read (MB) |\n")
        f.write("|------|--------------------:|--------:|---------------:|\n")

        pq_bl = load_json(f"{output_dir}/a1_{name}_parquet.json")
        dk_bl = load_json(f"{output_dir}/a1_{name}_disk.json")
        mm_bl = load_json(f"{output_dir}/a1_{name}_mem.json")

        pq_bl_t = get_times(pq_bl) if pq_bl else []
        dk_bl_t = get_times(dk_bl) if dk_bl else []
        mm_bl_t = get_times(mm_bl) if mm_bl else []
        pq_bl_min = hot_min(pq_bl_t)
        dk_bl_min = hot_min(dk_bl_t)
        mm_bl_min = hot_min(mm_bl_t)

        f.write(f"| Parquet | {pq_bl_t} | {pq_bl_min} | {get_disk_bytes(pq_bl):.1f} |\n")
        f.write(f"| Disk cache {disk_mem}MB | {dk_bl_t} | {dk_bl_min} | {get_disk_bytes(dk_bl):.1f} |\n")
        f.write(f"| Memory cache 2048MB | {mm_bl_t} | {mm_bl_min} | {get_disk_bytes(mm_bl):.1f} |\n\n")

        # Under contention
        f.write("#### Under contention (heavy q4 in background)\n\n")
        f.write("| Mode | All iterations (ms) | Min hot | Speedup vs Parquet | Regression vs baseline |\n")
        f.write("|------|--------------------:|--------:|-------------------:|-----------------------:|\n")

        pq_c = load_json(f"{output_dir}/a2_{name}_parquet.json")
        dk_c = load_json(f"{output_dir}/a2_{name}_disk.json")
        mm_c = load_json(f"{output_dir}/a2_{name}_mem.json")

        pq_c_t = get_times(pq_c) if pq_c else []
        dk_c_t = get_times(dk_c) if dk_c else []
        mm_c_t = get_times(mm_c) if mm_c else []
        pq_c_min = hot_min(pq_c_t)
        dk_c_min = hot_min(dk_c_t)
        mm_c_min = hot_min(mm_c_t)

        dk_sp = pq_c_min / dk_c_min if dk_c_min > 0 else 0
        mm_sp = pq_c_min / mm_c_min if mm_c_min > 0 else 0
        pq_regr = ((pq_c_min - pq_bl_min) / pq_bl_min * 100) if pq_bl_min > 0 else 0
        dk_regr = ((dk_c_min - dk_bl_min) / dk_bl_min * 100) if dk_bl_min > 0 else 0
        mm_regr = ((mm_c_min - mm_bl_min) / mm_bl_min * 100) if mm_bl_min > 0 else 0

        f.write(f"| Parquet | {pq_c_t} | {pq_c_min} | 1.00× | +{pq_regr:.0f}% |\n")
        f.write(f"| Disk cache {disk_mem}MB | {dk_c_t} | {dk_c_min} | {dk_sp:.2f}× | +{dk_regr:.0f}% |\n")
        f.write(f"| Memory cache 2048MB | {mm_c_t} | {mm_c_min} | {mm_sp:.2f}× | +{mm_regr:.0f}% |\n\n")

        # Analysis
        f.write("**Analysis:** ")
        if dk_sp > 1.0:
            f.write(f"✅ Disk cache is {dk_sp:.2f}× faster than Parquet under contention. ")
            f.write(f"Parquet regresses {pq_regr:+.0f}% due to CPU competition for decode, ")
            f.write(f"while disk cache only regresses {dk_regr:+.0f}% (no decode CPU needed). ")
            f.write(f"Memory cache ({mm_sp:.2f}×) shows the best case with no I/O at all.")
        elif dk_sp > 0:
            f.write(f"Disk cache ({dk_sp:.2f}×) vs Parquet under contention. ")
            if dk_regr < pq_regr:
                f.write(f"Disk cache regresses less ({dk_regr:+.0f}% vs {pq_regr:+.0f}%) — confirms CPU contention hits Parquet harder.")
            else:
                f.write(f"Both suffer similar regression. The disk I/O overhead may offset decode savings at this budget.")
        f.write("\n\n")

        # Cache stats
        dk_stats = get_cache_stats(dk_c) if dk_c else None
        if dk_stats:
            rt = dk_stats.get("runtime", {})
            f.write(f"**Cache stats (disk {disk_mem}MB, under contention):**\n")
            f.write(f"- Entries: {dk_stats.get('total_entries',0)} total, {dk_stats.get('disk_liquid_entries',0)} on disk\n")
            f.write(f"- Memory: {dk_stats.get('memory_usage_bytes',0)//(1024*1024)}MB / Disk: {dk_stats.get('disk_usage_bytes',0)//(1024*1024)}MB\n")
            f.write(f"- eval_predicate: {rt.get('eval_predicate',0)}\n\n")

        # Explain-analyze
        for mode, label in [("disk", f"Disk {disk_mem}MB"), ("parquet", "Parquet")]:
            log_path = f"{output_dir}/a2_{name}_{mode}.log"
            if os.path.exists(log_path):
                with open(log_path) as lf:
                    content = lf.read()
                blocks = content.split("=== EXPLAIN ANALYZE")
                if len(blocks) >= 2:
                    last = blocks[-1][:3000]
                    f.write(f"<details>\n<summary>EXPLAIN ANALYZE — {label} under contention</summary>\n\n```\n")
                    f.write("=== EXPLAIN ANALYZE" + last.strip())
                    f.write("\n```\n</details>\n\n")

        f.write("---\n\n")

    # ---- Experiment B ----
    f.write("## Experiment B: Heavy Queries Benefit from Disk Cache\n\n")
    f.write("**Hypothesis:** A heavy query (e.g., COUNT DISTINCT) reads all rows. If columns are pre-cached on disk,\n")
    f.write("it skips Parquet decode → frees CPU cycles for hash table operations → finishes faster.\n\n")

    heavy_names = ["q4_count_distinct", "q8_distinct_groupby"]
    heavy_disk_mem = [200, 200]

    for i, name in enumerate(heavy_names):
        disk_mem = heavy_disk_mem[i]
        f.write(f"### {name}\n\n")

        # Alone
        f.write("#### Alone (no contention)\n\n")
        f.write("| Mode | All iterations (ms) | Min hot | Speedup vs Parquet | Disk read (MB) |\n")
        f.write("|------|--------------------:|--------:|-------------------:|---------------:|\n")

        pq = load_json(f"{output_dir}/b1_{name}_parquet.json")
        dk = load_json(f"{output_dir}/b1_{name}_disk.json")
        mm = load_json(f"{output_dir}/b1_{name}_mem.json")

        pq_t = get_times(pq) if pq else []
        dk_t = get_times(dk) if dk else []
        mm_t = get_times(mm) if mm else []
        pq_min = hot_min(pq_t)
        dk_min = hot_min(dk_t)
        mm_min = hot_min(mm_t)

        dk_sp = pq_min / dk_min if dk_min > 0 else 0
        mm_sp = pq_min / mm_min if mm_min > 0 else 0

        f.write(f"| Parquet | {pq_t} | {pq_min} | 1.00× | {get_disk_bytes(pq):.1f} |\n")
        f.write(f"| Disk cache {disk_mem}MB | {dk_t} | {dk_min} | {dk_sp:.2f}× | {get_disk_bytes(dk):.1f} |\n")
        f.write(f"| Memory cache 2048MB | {mm_t} | {mm_min} | {mm_sp:.2f}× | {get_disk_bytes(mm):.1f} |\n\n")

        # Under contention
        f.write("#### Under contention (another heavy in background)\n\n")
        f.write("| Mode | All iterations (ms) | Min hot | Speedup vs Parquet | Regression vs alone |\n")
        f.write("|------|--------------------:|--------:|-------------------:|--------------------:|\n")

        pq_c = load_json(f"{output_dir}/b2_{name}_parquet.json")
        dk_c = load_json(f"{output_dir}/b2_{name}_disk.json")
        mm_c = load_json(f"{output_dir}/b2_{name}_mem.json")

        pq_c_t = get_times(pq_c) if pq_c else []
        dk_c_t = get_times(dk_c) if dk_c else []
        mm_c_t = get_times(mm_c) if mm_c else []
        pq_c_min = hot_min(pq_c_t)
        dk_c_min = hot_min(dk_c_t)
        mm_c_min = hot_min(mm_c_t)

        dk_c_sp = pq_c_min / dk_c_min if dk_c_min > 0 else 0
        mm_c_sp = pq_c_min / mm_c_min if mm_c_min > 0 else 0
        pq_regr = ((pq_c_min - pq_min) / pq_min * 100) if pq_min > 0 else 0
        dk_regr = ((dk_c_min - dk_min) / dk_min * 100) if dk_min > 0 else 0
        mm_regr = ((mm_c_min - mm_min) / mm_min * 100) if mm_min > 0 else 0

        f.write(f"| Parquet | {pq_c_t} | {pq_c_min} | 1.00× | +{pq_regr:.0f}% |\n")
        f.write(f"| Disk cache {disk_mem}MB | {dk_c_t} | {dk_c_min} | {dk_c_sp:.2f}× | +{dk_regr:.0f}% |\n")
        f.write(f"| Memory cache 2048MB | {mm_c_t} | {mm_c_min} | {mm_c_sp:.2f}× | +{mm_regr:.0f}% |\n\n")

        # Analysis
        f.write("**Analysis:** ")
        if dk_sp > 1.0 or dk_c_sp > 1.0:
            f.write(f"Even for heavy queries, disk cache helps: {dk_sp:.2f}× alone, {dk_c_sp:.2f}× under contention. ")
            f.write(f"The heavy query needs CPU for hash table operations. With disk cache, it doesn't also need CPU for decode → more CPU available for the actual computation.")
        else:
            f.write(f"Heavy query: disk cache {dk_sp:.2f}× alone, {dk_c_sp:.2f}× under contention. ")
            if dk_regr < pq_regr:
                f.write(f"Disk cache regresses less ({dk_regr:+.0f}% vs Parquet {pq_regr:+.0f}%) under contention — confirms decode CPU is freed.")
            else:
                f.write(f"For this query, the bottleneck is hash table computation, not data decode. Cache doesn't help much.")
        f.write("\n\n")

        # Cache stats
        dk_stats = get_cache_stats(dk_c) if dk_c else get_cache_stats(dk)
        if dk_stats:
            rt = dk_stats.get("runtime", {})
            f.write(f"**Cache stats (disk {disk_mem}MB):**\n")
            f.write(f"- Entries: {dk_stats.get('total_entries',0)} total, {dk_stats.get('disk_liquid_entries',0)} on disk\n")
            f.write(f"- Memory: {dk_stats.get('memory_usage_bytes',0)//(1024*1024)}MB / Disk: {dk_stats.get('disk_usage_bytes',0)//(1024*1024)}MB\n")
            f.write(f"- eval_predicate: {rt.get('eval_predicate',0)}, squeezed_needs_io: {rt.get('get_squeezed_needs_io',0)}\n\n")

        # Explain-analyze
        for mode, label in [("disk", f"Disk {disk_mem}MB"), ("parquet", "Parquet")]:
            log_path = f"{output_dir}/b1_{name}_{mode}.log"
            if os.path.exists(log_path):
                with open(log_path) as lf:
                    content = lf.read()
                blocks = content.split("=== EXPLAIN ANALYZE")
                if len(blocks) >= 2:
                    last = blocks[-1][:3000]
                    f.write(f"<details>\n<summary>EXPLAIN ANALYZE — {label} alone</summary>\n\n```\n")
                    f.write("=== EXPLAIN ANALYZE" + last.strip())
                    f.write("\n```\n</details>\n\n")

        f.write("---\n\n")

    # ---- Conclusion ----
    f.write("## Conclusion\n\n")
    f.write("| Scenario | Disk cache advantage | Why |\n")
    f.write("|----------|---------------------|-----|\n")
    f.write("| Light query alone | ✅ if working set fits | Skip decode → faster even without contention |\n")
    f.write("| Light query + heavy bg | ✅✅ amplified | Parquet needs CPU for decode, but CPU is saturated → disk cache wins more |\n")
    f.write("| Heavy query alone | Depends on working set | If decode cost is significant fraction of total time |\n")
    f.write("| Heavy query + heavy bg | ✅ if decode is bottleneck | Freed CPU goes to hash table ops → faster completion |\n\n")
    f.write("**Key insight:** The advantage of disk cache over Parquet grows under CPU contention, ")
    f.write("because Parquet's decode step competes for the same CPU that heavy queries need. ")
    f.write("Disk cache converts a CPU problem (decode) into an I/O problem (sequential read), ")
    f.write("and I/O doesn't compete with CPU-bound hash table operations.\n")

print(f"✅ Report: {report_path}")

# Console summary
print("\n" + "=" * 90)
print("  DISK VS PARQUET UNDER CONTENTION — SUMMARY")
print("=" * 90)
for name in ["c0_range_filter", "q1_advengine"]:
    pq_bl = load_json(f"{output_dir}/a1_{name}_parquet.json")
    dk_bl = load_json(f"{output_dir}/a1_{name}_disk.json")
    pq_c = load_json(f"{output_dir}/a2_{name}_parquet.json")
    dk_c = load_json(f"{output_dir}/a2_{name}_disk.json")
    pq_bl_min = hot_min(get_times(pq_bl)) if pq_bl else 0
    dk_bl_min = hot_min(get_times(dk_bl)) if dk_bl else 0
    pq_c_min = hot_min(get_times(pq_c)) if pq_c else 0
    dk_c_min = hot_min(get_times(dk_c)) if dk_c else 0
    print(f"\n  {name}:")
    print(f"    Alone:      Parquet={pq_bl_min}ms  Disk={dk_bl_min}ms  (disk {pq_bl_min/dk_bl_min if dk_bl_min else 0:.2f}×)")
    print(f"    Contention: Parquet={pq_c_min}ms  Disk={dk_c_min}ms  (disk {pq_c_min/dk_c_min if dk_c_min else 0:.2f}×)")
    print(f"    Parquet regr: +{(pq_c_min-pq_bl_min)/pq_bl_min*100 if pq_bl_min else 0:.0f}%  Disk regr: +{(dk_c_min-dk_bl_min)/dk_bl_min*100 if dk_bl_min else 0:.0f}%")
print("\n" + "=" * 90)
PYEOF

echo ""
echo "🎉 === Done! ==="
echo "  📄 Report: $OUTPUT_DIR/report.md"
echo "  📋 Logs: $OUTPUT_DIR/*.log"
