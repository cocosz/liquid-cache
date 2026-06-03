# Numeric Predicate-Only Cache Benchmark

Config: 2048MB memory, 5 iterations, hot avg (skip iter 0)

| Query | No Pushdown (ms) | Pushdown (ms) | LiquidCache (ms) | LC vs Push | LC vs NP |
|-------|-----------------|--------------|-----------------|-----------|----------|
| Q19 | 59 | 86 | 22 | 3.99x | 2.73x |
| Q24 | 388 | 438 | 396 | 1.11x | 0.98x |
| Q26 | 400 | 542 | 440 | 1.23x | 0.91x |
| Q37 | 103 | 94 | 79 | 1.18x | 1.30x |
