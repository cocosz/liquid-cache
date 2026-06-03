#!/usr/bin/env python3
"""Parse per-column memory usage from individual column benchmark results."""

import json
import os
import re

results_dir = 'outputs/column_memory/results'
results = []

for fname in sorted(os.listdir(results_dir)):
    if not fname.endswith('.json'):
        continue
    col = fname.replace('.json', '')
    
    with open(os.path.join(results_dir, fname)) as f:
        data = json.load(f)
    
    # Use the last iteration's cache stats
    last_iter = data['results'][0]['iteration_results'][-1]
    stats = last_iter.get('cache_stats', {})
    
    mem_bytes = stats.get('memory_usage_bytes', 0)
    disk_bytes = stats.get('disk_usage_bytes', 0)
    total_entries = stats.get('total_entries', 0)
    
    mem_mb = mem_bytes / (1024 * 1024)
    disk_mb = disk_bytes / (1024 * 1024)
    
    # Memory breakdown by format
    arrow_mb = stats.get('memory_arrow_bytes', 0) / (1024 * 1024)
    liquid_mb = stats.get('memory_liquid_bytes', 0) / (1024 * 1024)
    squeezed_mb = stats.get('memory_squeezed_liquid_bytes', 0) / (1024 * 1024)
    
    results.append({
        'col': col,
        'mem_mb': mem_mb,
        'disk_mb': disk_mb,
        'entries': total_entries,
        'arrow_mb': arrow_mb,
        'liquid_mb': liquid_mb,
        'squeezed_mb': squeezed_mb,
        'mem_bytes': mem_bytes,
    })

# Sort by memory descending
results.sort(key=lambda x: x['mem_bytes'], reverse=True)

# Print table
print(f"{'#':<4} {'Column':<28} {'Memory (MB)':<12} {'Disk (MB)':<10} {'Entries':<8} {'Format'}")
print("=" * 90)

total_mb = 0
for i, r in enumerate(results, 1):
    total_mb += r['mem_mb']
    
    if r['squeezed_mb'] > 0.1:
        fmt = f"squeezed ({r['squeezed_mb']:.1f} MB)"
    elif r['liquid_mb'] > 0.1:
        fmt = f"liquid ({r['liquid_mb']:.1f} MB)"
    elif r['arrow_mb'] > 0.1:
        fmt = f"arrow ({r['arrow_mb']:.1f} MB)"
    else:
        fmt = "-"
    
    spill = f" +{r['disk_mb']:.0f}MB spill" if r['disk_mb'] > 0 else ""
    print(f"{i:<4} {r['col']:<28} {r['mem_mb']:<12.1f} {r['disk_mb']:<10.1f} {r['entries']:<8} {fmt}{spill}")

print("=" * 90)
print(f"{'':4} {'TOTAL':<28} {total_mb:<12.1f}")
print()

# Summary by size buckets
big = [r for r in results if r['mem_mb'] >= 100]
medium = [r for r in results if 10 <= r['mem_mb'] < 100]
small = [r for r in results if r['mem_mb'] < 10]

print("--- Size Buckets ---")
print(f"  Large (>=100MB):  {len(big)} cols, {sum(r['mem_mb'] for r in big):.0f} MB total")
for r in big:
    print(f"    {r['col']:<28} {r['mem_mb']:.1f} MB")
print(f"  Medium (10-100MB): {len(medium)} cols, {sum(r['mem_mb'] for r in medium):.0f} MB total")
for r in medium:
    print(f"    {r['col']:<28} {r['mem_mb']:.1f} MB")
print(f"  Small (<10MB):    {len(small)} cols, {sum(r['mem_mb'] for r in small):.0f} MB total")
print()
print(f"If you cache only small+medium columns: {sum(r['mem_mb'] for r in medium) + sum(r['mem_mb'] for r in small):.0f} MB")
print(f"If you cache only small columns: {sum(r['mem_mb'] for r in small):.0f} MB")
