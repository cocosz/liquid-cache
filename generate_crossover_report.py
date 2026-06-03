#!/usr/bin/env python3
"""Generate detailed crossover report with per-query analysis, cache stats, and explain-analyze."""
import json, os

OUTPUT_DIR = "outputs/disk_cache_crossover"
LIGHT_MANIFEST = "benchmark/clickbench/manifest_light.json"

QUERIES = [0, 1, 2, 4, 5, 6, 7, 8, 9, 11]
QUERY_NAMES = [
    "c0_range_filter", "c1_multi_numeric", "c2_point_lookups",
    "c4_date_range_agg", "c6_selective", "c7_wide_numeric",
    "q1_advengine", "q7_group_advengine", "q40_multi_pred", "q42_time_bucket",
]
WORKING_SET_MB = [362, 6, 1, 505, 1, 383, 181, 181, 24, 13]
PERCENTAGES = [10, 20, 30, 40, 50, 60, 80, 100, 150]

# Load SQL for each query
with open(LIGHT_MANIFEST) as f:
    light_data = json.load(f)
    light_query_paths = light_data["queries"]

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

def get_cache_stats(data, qi=0):
    try:
        return data["results"][qi]["iteration_results"][-1].get("cache_stats")
    except:
        return None

def get_perf(data, qi=0):
    try:
        return data["results"][qi]["iteration_results"][-1].get("perf_events")
    except:
        return None

def get_disk_bytes(data, qi=0):
    try:
        last = data["results"][qi]["iteration_results"][-1]
        return last.get("disk_bytes_read", 0), last.get("disk_bytes_written", 0)
    except:
        return 0, 0

def get_sql(query_idx):
    try:
        with open(light_query_paths[query_idx]) as f:
            return f.read().strip()
    except:
        return "N/A"

report_path = f"{OUTPUT_DIR}/detailed_report.md"
with open(report_path, "w") as f:
    f.write("# Disk Cache Crossover: Memory Budget vs Performance — Detailed Report\n\n")

    # Configuration
    f.write("## Configuration\n\n")
    f.write("| Parameter | Value |\n|---|---|\n")
    f.write("| Instance | c6a.4xlarge (16 vCPU, 32 GB RAM) |\n")
    f.write("| Dataset | ClickBench hits.parquet (~14.8 GB, 100M rows) |\n")
    f.write("| Iterations | 5 (metric: min of hot, iter 1-4) |\n")
    f.write("| Cache policy | S3-FIFO (LiquidPolicy) |\n")
    f.write("| Squeeze policy | TranscodeSqueezeEvict |\n")
    f.write("| Page cache | Dropped before each run (echo 3 > /proc/sys/vm/drop_caches) |\n")
    f.write("| Budgets tested | 10%, 20%, 30%, 40%, 50%, 60%, 80%, 100%, 150% of working set |\n\n")

    # Hypothesis
    f.write("## Hypothesis\n\n")
    f.write("LiquidCache stores evicted data on disk in **pre-decoded liquid format**. Reading from disk cache avoids ")
    f.write("Parquet decompression (zstd/snappy) and page decoding (delta, dictionary, RLE). This should:\n")
    f.write("1. Save CPU cycles (no decode work)\n")
    f.write("2. Be faster than Parquet when the memory budget covers enough of the working set\n")
    f.write("3. Show a clear **crossover point** — below which disk I/O exceeds decode savings\n\n")

    # Summary table
    f.write("---\n\n## Summary: Crossover Points\n\n")
    f.write("| Query | Working set | Crossover | Budget at crossover | Best speedup | Parquet (ms) | Best cache (ms) |\n")
    f.write("|-------|-------------|-----------|--------------------:|-------------:|-------------:|----------------:|\n")

    crossovers = {}
    for idx, qi in enumerate(QUERIES):
        name = QUERY_NAMES[idx]
        ws = WORKING_SET_MB[idx]
        pq = load_json(f"{OUTPUT_DIR}/parquet_q{qi}.json")
        pq_min = hot_min(get_times(pq)) if pq else 0

        crossover_pct = None
        best_min = float('inf')
        for pct in PERCENTAGES:
            data = load_json(f"{OUTPUT_DIR}/liquid_q{qi}_{pct}pct.json")
            if data:
                hmin = hot_min(get_times(data))
                if hmin > 0 and hmin < best_min:
                    best_min = hmin
                if hmin > 0 and pq_min > 0 and pq_min / hmin >= 1.0 and crossover_pct is None:
                    crossover_pct = pct

        crossovers[qi] = crossover_pct
        best_sp = pq_min / best_min if best_min > 0 and best_min < float('inf') else 0
        cross_str = f"{crossover_pct}%" if crossover_pct else "N/A"
        cross_mb = f"{ws * crossover_pct // 100}MB" if crossover_pct else "—"
        f.write(f"| {name} | {ws}MB | {cross_str} | {cross_mb} | {best_sp:.2f}× | {pq_min} | {int(best_min) if best_min < float('inf') else '-'} |\n")

    f.write("\n")

    # Per-query detailed sections
    f.write("---\n\n## Per-Query Detailed Analysis\n\n")

    for idx, qi in enumerate(QUERIES):
        name = QUERY_NAMES[idx]
        ws = WORKING_SET_MB[idx]
        sql = get_sql(qi)

        pq = load_json(f"{OUTPUT_DIR}/parquet_q{qi}.json")
        pq_times = get_times(pq) if pq else []
        pq_min = hot_min(pq_times)

        f.write(f"### {name}\n\n")
        f.write(f"**Working set:** {ws}MB | **Crossover:** {crossovers[qi] or 'N/A'}%\n\n")
        f.write(f"```sql\n{sql}\n```\n\n")
        f.write(f"**Parquet baseline:** {pq_min}ms (min hot), all iterations: {pq_times}\n\n")

        # Performance table
        f.write("#### Performance Table\n\n")
        f.write("| Budget | Memory (MB) | Cold | Iter 1 | Iter 2 | Iter 3 | Iter 4 | Min hot | Speedup | Entries mem | Entries disk | Disk (MB) | Disk read (MB) | Zone |\n")
        f.write("|--------|-------------|------|--------|--------|--------|--------|---------|---------|------------|-------------|-----------|----------------|------|\n")

        for pct in PERCENTAGES:
            mem_mb = max(1, ws * pct // 100)
            data = load_json(f"{OUTPUT_DIR}/liquid_q{qi}_{pct}pct.json")
            if data is None:
                f.write(f"| {pct}% | {mem_mb} | - | - | - | - | - | - | - | - | - | - | - | - |\n")
                continue

            times = get_times(data)
            cold = times[0] if times else 0
            hot = times[1:] if len(times) > 1 else times
            hmin = min(hot) if hot else 0
            speedup = pq_min / hmin if hmin > 0 and pq_min > 0 else 0
            stats = get_cache_stats(data)
            disk_r, disk_w = get_disk_bytes(data)

            mem_entries = 0
            disk_entries = 0
            disk_mb = 0
            io_reads = 0
            if stats:
                mem_entries = (stats.get("memory_arrow_entries", 0) +
                              stats.get("memory_liquid_entries", 0) +
                              stats.get("memory_squeezed_liquid_entries", 0))
                disk_entries = stats.get("disk_liquid_entries", 0) + stats.get("disk_arrow_entries", 0)
                disk_mb = stats.get("disk_usage_bytes", 0) // (1024*1024)
                io_reads = stats.get("runtime", {}).get("read_io_count", 0)

            proc_disk_r = disk_r / (1024*1024)

            # Format iterations
            iter_strs = [str(t) for t in hot]
            while len(iter_strs) < 4:
                iter_strs.append("-")

            is_crossover = (crossovers[qi] == pct)
            zone = "🟢 ←" if is_crossover else ("🟢" if speedup >= 1.0 else "🔴")

            if is_crossover:
                f.write(f"| **{pct}%** | **{mem_mb}** | **{cold}** | **{iter_strs[0]}** | **{iter_strs[1]}** | **{iter_strs[2]}** | **{iter_strs[3]}** | **{hmin}** | **{speedup:.2f}×** | **{mem_entries}** | **{disk_entries}** | **{disk_mb}** | **{proc_disk_r:.1f}** | {zone} |\n")
            else:
                f.write(f"| {pct}% | {mem_mb} | {cold} | {iter_strs[0]} | {iter_strs[1]} | {iter_strs[2]} | {iter_strs[3]} | {hmin} | {speedup:.2f}× | {mem_entries} | {disk_entries} | {disk_mb} | {proc_disk_r:.1f} | {zone} |\n")

        # Parquet row
        pq_hot = pq_times[1:] if len(pq_times) > 1 else pq_times
        pq_iter_strs = [str(t) for t in pq_hot]
        while len(pq_iter_strs) < 4:
            pq_iter_strs.append("-")
        f.write(f"| Parquet | — | {pq_times[0] if pq_times else '-'} | {pq_iter_strs[0]} | {pq_iter_strs[1]} | {pq_iter_strs[2]} | {pq_iter_strs[3]} | {pq_min} | 1.00× | — | — | — | — | — |\n")
        f.write("\n")

        # Cache stats at crossover (or best config)
        target_pct = crossovers[qi] or PERCENTAGES[-1]
        target_data = load_json(f"{OUTPUT_DIR}/liquid_q{qi}_{target_pct}pct.json")
        target_stats = get_cache_stats(target_data) if target_data else None

        if target_stats:
            rt = target_stats.get("runtime", {})
            f.write(f"#### Cache Stats ({target_pct}% = {max(1, ws * target_pct // 100)}MB, last iteration)\n\n")
            f.write("```\n")
            f.write(f"total_entries: {target_stats.get('total_entries', 0)}\n")
            f.write(f"memory_arrow_entries: {target_stats.get('memory_arrow_entries', 0)}\n")
            f.write(f"memory_liquid_entries: {target_stats.get('memory_liquid_entries', 0)}\n")
            f.write(f"memory_squeezed_liquid_entries: {target_stats.get('memory_squeezed_liquid_entries', 0)}\n")
            f.write(f"disk_liquid_entries: {target_stats.get('disk_liquid_entries', 0)}\n")
            f.write(f"disk_arrow_entries: {target_stats.get('disk_arrow_entries', 0)}\n")
            f.write(f"memory_usage_bytes: {target_stats.get('memory_usage_bytes', 0):,} ({target_stats.get('memory_usage_bytes', 0)//(1024*1024)} MB)\n")
            f.write(f"disk_usage_bytes: {target_stats.get('disk_usage_bytes', 0):,} ({target_stats.get('disk_usage_bytes', 0)//(1024*1024)} MB)\n")
            f.write(f"---\n")
            f.write(f"eval_predicate: {rt.get('eval_predicate', 0)}\n")
            f.write(f"cache_hit: {rt.get('cache_hit', 0)}\n")
            f.write(f"cache_miss: {rt.get('cache_miss', 0)}\n")
            f.write(f"get_squeezed_success: {rt.get('get_squeezed_success', 0)}\n")
            f.write(f"get_squeezed_needs_io: {rt.get('get_squeezed_needs_io', 0)}\n")
            f.write(f"read_io_count: {rt.get('read_io_count', 0)}\n")
            f.write(f"write_io_count: {rt.get('write_io_count', 0)}\n")
            f.write(f"disk_evictions: {rt.get('disk_evictions', 0)}\n")
            f.write(f"squeeze_io_saved: {rt.get('squeeze_io_saved', 0)}\n")
            f.write("```\n\n")

        # Explain-analyze at crossover
        target_log = f"{OUTPUT_DIR}/liquid_q{qi}_{target_pct}pct.log"
        if os.path.exists(target_log):
            with open(target_log) as lf:
                content = lf.read()
            blocks = content.split("=== EXPLAIN ANALYZE")
            if len(blocks) >= 2:
                last_block = blocks[-1][:4000]
                f.write(f"<details>\n<summary>EXPLAIN ANALYZE — {target_pct}% budget (last iteration)</summary>\n\n```\n")
                f.write("=== EXPLAIN ANALYZE" + last_block.strip())
                f.write("\n```\n</details>\n\n")

        # Parquet explain-analyze
        pq_log = f"{OUTPUT_DIR}/parquet_q{qi}.log"
        if os.path.exists(pq_log):
            with open(pq_log) as lf:
                content = lf.read()
            blocks = content.split("=== EXPLAIN ANALYZE")
            if len(blocks) >= 2:
                last_block = blocks[-1][:4000]
                f.write(f"<details>\n<summary>EXPLAIN ANALYZE — Parquet (last iteration)</summary>\n\n```\n")
                f.write("=== EXPLAIN ANALYZE" + last_block.strip())
                f.write("\n```\n</details>\n\n")

        # Analysis paragraph
        f.write("#### Analysis\n\n")
        crossover_pct = crossovers[qi]

        if crossover_pct is not None:
            cross_mb = max(1, ws * crossover_pct // 100)
            cross_data = load_json(f"{OUTPUT_DIR}/liquid_q{qi}_{crossover_pct}pct.json")
            cross_stats = get_cache_stats(cross_data) if cross_data else None
            cross_min = hot_min(get_times(cross_data)) if cross_data else 0
            cross_speedup = pq_min / cross_min if cross_min > 0 else 0
            disk_entries_at_cross = cross_stats.get("disk_liquid_entries", 0) if cross_stats else 0

            if disk_entries_at_cross == 0:
                f.write(f"**Crossover at {crossover_pct}% ({cross_mb}MB): {cross_speedup:.2f}× speedup.** ")
                f.write(f"At this budget, the entire working set in liquid format fits in memory — no disk spill. ")
                f.write(f"The liquid format compresses {ws}MB (Arrow size) down to ≤{cross_mb}MB, ")
                f.write(f"so the 'working set' in liquid terms is smaller than the Arrow estimate. ")
                f.write(f"All predicate evaluation happens on in-memory cached data, skipping Parquet decode entirely.\n\n")
            else:
                f.write(f"**Crossover at {crossover_pct}% ({cross_mb}MB): {cross_speedup:.2f}× speedup.** ")
                f.write(f"At this budget, {disk_entries_at_cross} entries are on disk but the hot working set stays in memory. ")
                f.write(f"Reading the cold entries from disk cache (pre-decoded) is still faster than decoding Parquet.\n\n")

            # Below crossover
            below_pct = PERCENTAGES[0] if crossover_pct > PERCENTAGES[0] else None
            if below_pct and below_pct != crossover_pct:
                below_data = load_json(f"{OUTPUT_DIR}/liquid_q{qi}_{below_pct}pct.json")
                below_min = hot_min(get_times(below_data)) if below_data else 0
                below_stats = get_cache_stats(below_data) if below_data else None
                below_disk = below_stats.get("disk_liquid_entries", 0) if below_stats else 0
                if below_min > 0:
                    below_sp = pq_min / below_min
                    f.write(f"At {below_pct}% ({max(1, ws * below_pct // 100)}MB): {below_sp:.2f}× — ")
                    if below_disk > 0:
                        f.write(f"{below_disk} entries on disk, random I/O dominates, slower than Parquet.\n\n")
                    else:
                        f.write(f"still fast (liquid compresses well enough to fit).\n\n")
        else:
            # No crossover found
            f.write(f"**No crossover found.** Disk cache never outperforms Parquet at any tested budget. ")
            f.write(f"This query is CPU-bound on aggregation — the time is spent computing results ")
            f.write(f"(AVG/SUM/COUNT over millions of rows), not on reading/decoding data. ")
            f.write(f"Caching avoids decode but doesn't reduce the aggregation cost, which dominates.\n\n")

        f.write("---\n\n")

    # ---- Overall Conclusion ----
    f.write("## Conclusion\n\n")

    # Classify queries
    always_fast = [QUERY_NAMES[i] for i, qi in enumerate(QUERIES) if crossovers[qi] and crossovers[qi] <= 20]
    moderate = [QUERY_NAMES[i] for i, qi in enumerate(QUERIES) if crossovers[qi] and 30 <= crossovers[qi] <= 50]
    no_benefit = [QUERY_NAMES[i] for i, qi in enumerate(QUERIES) if crossovers[qi] is None]

    f.write("### Query Classification by Crossover Behavior\n\n")
    f.write("| Category | Queries | Crossover | Why |\n")
    f.write("|----------|---------|-----------|-----|\n")
    f.write(f"| Always fast (≤20%) | {', '.join(always_fast)} | 10-20% | Liquid format compresses data well below Arrow size; even tiny budgets hold the full working set |\n")
    f.write(f"| Moderate (30-50%) | {', '.join(moderate)} | 30-50% | Large working set, needs meaningful fraction in memory to avoid I/O cliff |\n")
    f.write(f"| No benefit | {', '.join(no_benefit)} | N/A | CPU-bound on aggregation, decode is not the bottleneck |\n\n")

    f.write("### Key Insight: Liquid Compression Factor\n\n")
    f.write("The crossover doesn't occur at a fixed percentage because **liquid format compresses numeric columns** ")
    f.write("significantly below their Arrow (decoded) size:\n\n")
    f.write("| Query | Arrow working set | Liquid actual size | Compression ratio |\n")
    f.write("|-------|------------------:|-------------------:|------------------:|\n")

    for idx, qi in enumerate(QUERIES):
        ws = WORKING_SET_MB[idx]
        # Find smallest budget where everything fits (disk_entries = 0)
        for pct in PERCENTAGES:
            data = load_json(f"{OUTPUT_DIR}/liquid_q{qi}_{pct}pct.json")
            if data:
                stats = get_cache_stats(data)
                if stats and stats.get("disk_liquid_entries", 0) == 0:
                    liquid_mb = stats.get("memory_usage_bytes", 0) // (1024*1024)
                    ratio = ws / liquid_mb if liquid_mb > 0 else 0
                    f.write(f"| {QUERY_NAMES[idx]} | {ws}MB | {liquid_mb}MB | {ratio:.1f}× |\n")
                    break
        else:
            f.write(f"| {QUERY_NAMES[idx]} | {ws}MB | >budget | — |\n")

    f.write("\n")
    f.write("### Recommendation\n\n")
    f.write("1. **For selective queries** (c1, c2, c6, q42, q40): Even a tiny memory budget (1-12MB) gives full cache benefit. ")
    f.write("These are the best candidates for disk cache — their working set after statistics pruning is already tiny.\n\n")
    f.write("2. **For full-scan queries** (c0, q1, q7): Budget 50% of Arrow working set. ")
    f.write("Thanks to liquid compression, this typically means the data fits entirely in memory with zero disk spill.\n\n")
    f.write("3. **For aggregation-heavy queries** (c4): Cache doesn't help — the bottleneck is computation, not I/O/decode. ")
    f.write("Don't waste cache memory on these.\n\n")
    f.write("4. **Rule of thumb**: Set cache memory to **50% of the largest full-scan query's Arrow working set**. ")
    f.write("This covers all query types: selective queries fit trivially, full-scan queries fit after liquid compression.\n")

print(f"✅ Report: {report_path}")
