# Sweet Spot Analysis: Memory Budget vs Performance

Queries with numeric predicates that benefit from caching.
Finding the minimum memory budget for maximum benefit.

## Q19 (Pushdown baseline: 86ms)

| Budget | Hot (ms) | Speedup | Cache mem | Disk | IO reads | Status |
|--------|----------|---------|-----------|------|----------|--------|
| 8MB | 682 | 0.13× | 7MB | 619MB | 0 | ➖ |
| 16MB | 630 | 0.14× | 15MB | 620MB | 0 | ➖ |
| 32MB | 603 | 0.14× | 31MB | 620MB | 0 | ➖ |
| 64MB | 509 | 0.17× | 63MB | 619MB | 0 | ➖ |
| 128MB | 364 | 0.23× | 127MB | 620MB | 0 | ➖ |
| 256MB | 168 | 0.51× | 255MB | 620MB | 0 | ➖ |
| 384MB | 33 | 2.59× | 383MB | 470MB | 0 | ✅ |
| 512MB | 27 | 3.14× | 511MB | 216MB | 0 | ✅ |
| 768MB | 21 | 4.02× | 668MB | 0MB | 0 | ✅ |
| 1024MB | 21 | 4.07× | 668MB | 0MB | 0 | ✅ |
| 2048MB | 21 | 4.07× | 668MB | 0MB | 0 | ✅ |

## Q7 (Pushdown baseline: 32ms)

| Budget | Hot (ms) | Speedup | Cache mem | Disk | IO reads | Status |
|--------|----------|---------|-----------|------|----------|--------|
| 8MB | 560 | 0.06× | 7MB | 17MB | 0 | ➖ |
| 16MB | 345 | 0.09× | 15MB | 10MB | 0 | ➖ |
| 32MB | 16 | 2.00× | 31MB | 0MB | 0 | ✅ |
| 64MB | 16 | 2.00× | 63MB | 0MB | 0 | ✅ |
| 128MB | 16 | 1.94× | 127MB | 0MB | 0 | ✅ |
| 256MB | 15 | 2.14× | 181MB | 0MB | 0 | ✅ |
| 384MB | 15 | 2.07× | 181MB | 0MB | 0 | ✅ |
| 512MB | 15 | 2.07× | 181MB | 0MB | 0 | ✅ |
| 768MB | 16 | 1.94× | 181MB | 0MB | 0 | ✅ |
| 1024MB | 16 | 2.03× | 181MB | 0MB | 0 | ✅ |
| 2048MB | 16 | 1.97× | 181MB | 0MB | 0 | ✅ |

## Q40 (Pushdown baseline: 40ms)

| Budget | Hot (ms) | Speedup | Cache mem | Disk | IO reads | Status |
|--------|----------|---------|-----------|------|----------|--------|
| 8MB | 190 | 0.21× | 7MB | 7MB | 0 | ➖ |
| 16MB | 22 | 1.85× | 15MB | 0MB | 0 | ✅ |
| 32MB | 20 | 2.01× | 24MB | 0MB | 0 | ✅ |
| 64MB | 20 | 1.99× | 24MB | 0MB | 0 | ✅ |
| 128MB | 22 | 1.83× | 24MB | 0MB | 0 | ✅ |
| 256MB | 20 | 1.94× | 24MB | 0MB | 0 | ✅ |
| 384MB | 20 | 1.99× | 24MB | 0MB | 0 | ✅ |
| 512MB | 20 | 1.96× | 24MB | 0MB | 0 | ✅ |
| 768MB | 20 | 2.01× | 24MB | 0MB | 0 | ✅ |
| 1024MB | 21 | 1.87× | 24MB | 0MB | 0 | ✅ |
| 2048MB | 20 | 1.99× | 24MB | 0MB | 0 | ✅ |

## Q42 (Pushdown baseline: 32ms)

| Budget | Hot (ms) | Speedup | Cache mem | Disk | IO reads | Status |
|--------|----------|---------|-----------|------|----------|--------|
| 8MB | 18 | 1.74× | 7MB | 0MB | 0 | ✅ |
| 16MB | 18 | 1.77× | 13MB | 0MB | 0 | ✅ |
| 32MB | 18 | 1.77× | 13MB | 0MB | 0 | ✅ |
| 64MB | 19 | 1.70× | 13MB | 0MB | 0 | ✅ |
| 128MB | 18 | 1.79× | 13MB | 0MB | 0 | ✅ |
| 256MB | 20 | 1.65× | 13MB | 0MB | 0 | ✅ |
| 384MB | 19 | 1.72× | 13MB | 0MB | 0 | ✅ |
| 512MB | 18 | 1.74× | 13MB | 0MB | 0 | ✅ |
| 768MB | 18 | 1.74× | 13MB | 0MB | 0 | ✅ |
| 1024MB | 18 | 1.74× | 13MB | 0MB | 0 | ✅ |
| 2048MB | 18 | 1.79× | 13MB | 0MB | 0 | ✅ |

