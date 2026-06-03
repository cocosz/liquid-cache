#!/usr/bin/env python3
"""Parse Q40-Q42 benchmark results showing cold vs hot performance + cache stats."""

import json
import os

def parse_query_result(path):
    with open(path) as f:
        data = json.load(f)
    
    result = data['results'][0]
    query = result['query']['statement'][0][:80]
    
    iterations = []
    for i, iter_result in enumerate(result['iteration_results']):
        stats = iter_result.get('cache_stats', {})
        iterations.append({
            'iteration': i,
            'time_ms': iter_result['time_millis'],
            'memory_mb': stats.get('memory_usage_bytes', 0) / (1024*1024),
            'disk_mb': stats.get('disk_usage_bytes', 0) / (1024*1024),
            'total_entries': stats.get('total_entries', 0),
            'disk_entries': stats.get('disk_liquid_entries', 0) + stats.get('disk_arrow_entries', 0),
            'mem_liquid': stats.get('memory_liquid_entries', 0),
            'mem_squeezed': stats.get('memory_squeezed_liquid_entries', 0),
            'read_io': stats.get('runtime', {}).get('read_io_count', 0),
            'write_io': stats.get('runtime', {}).get('write_io_count', 0),
        })
    
    return query, iterations

queries = ['q40', 'q41', 'q42']
base_dir = 'outputs/q40_q41_q42'

for q in queries:
    liquid_path = f'{base_dir}/{q}.json'
    baseline_path = f'{base_dir}/{q}_baseline.json'
    
    if not os.path.exists(liquid_path):
        continue
    
    query, iters = parse_query_result(liquid_path)
    
    print(f"{'='*80}")
    print(f"  {q.upper()}: {query}")
    print(f"{'='*80}")
    print()
    
    # Baseline
    if os.path.exists(baseline_path):
        _, base_iters = parse_query_result(baseline_path)
        base_times = [it['time_ms'] for it in base_iters]
        print(f"  Baseline (DataFusion): {base_times} ms")
        print(f"  Baseline best: {min(base_times[1:])} ms (warm)")
        print()
    
    # LiquidCache iterations
    print(f"  {'Iter':<5} {'Time':<8} {'Mem(MB)':<9} {'Disk(MB)':<9} {'Entries':<9} {'DiskE':<7} {'ReadIO':<8} {'WriteIO':<8}")
    print(f"  {'-'*60}")
    
    for it in iters:
        label = "COLD" if it['iteration'] == 0 else "HOT"
        print(f"  {label:<5} {it['time_ms']:<8} {it['memory_mb']:<9.0f} {it['disk_mb']:<9.0f} {it['total_entries']:<9} {it['disk_entries']:<7} {it['read_io']:<8} {it['write_io']:<8}")
    
    # Cold vs Hot analysis
    cold = iters[0]['time_ms']
    hot_best = min(it['time_ms'] for it in iters[1:])
    hot_last = iters[-1]
    
    print()
    print(f"  Cold (iter 0): {cold} ms")
    print(f"  Hot best:      {hot_best} ms")
    print(f"  Speedup:       {cold/hot_best:.1f}x (cold→hot)")
    
    if os.path.exists(baseline_path):
        _, base_iters = parse_query_result(baseline_path)
        base_best = min(it['time_ms'] for it in base_iters[1:])
        print(f"  vs Baseline:   {base_best/hot_best:.1f}x {'faster' if hot_best < base_best else 'slower'}")
    
    # Cache miss check
    if hot_last['read_io'] == 0 and hot_last['disk_entries'] == 0:
        print(f"  Cache misses:  ZERO ✅ (all data in memory)")
    elif hot_last['read_io'] > 0:
        print(f"  Cache misses:  {hot_last['read_io']} disk reads (data on disk)")
    
    print()
    print()
