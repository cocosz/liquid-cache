# Sweet Spot Analysis: Memory Budget vs Performance

Queries with numeric predicates that benefit from caching.
Finding the minimum memory budget for maximum benefit.

## Q19 (Pushdown baseline: 85ms)

| Budget | Hot (ms) | Speedup | Cache mem | Disk | IO reads | Status |
|--------|----------|---------|-----------|------|----------|--------|
| 8MB | 4796 | 0.02× | 7MB | 619MB | 0 | ➖ |
| 16MB | 4664 | 0.02× | 15MB | 619MB | 0 | ➖ |
| 32MB | 4392 | 0.02× | 31MB | 619MB | 0 | ➖ |
| 64MB | 3856 | 0.02× | 63MB | 619MB | 0 | ➖ |
| 128MB | 2778 | 0.03× | 127MB | 619MB | 0 | ➖ |
| 256MB | 635 | 0.13× | 255MB | 619MB | 0 | ➖ |
| 384MB | 33 | 2.59× | 383MB | 470MB | 0 | ✅ |
| 512MB | 28 | 3.05× | 511MB | 216MB | 0 | ✅ |
| 768MB | 20 | 4.13× | 668MB | 0MB | 0 | ✅ |
| 1024MB | 22 | 3.94× | 668MB | 0MB | 0 | ✅ |
| 2048MB | 21 | 3.99× | 668MB | 0MB | 0 | ✅ |

## Q7 (Pushdown baseline: 32ms)

| Budget | Hot (ms) | Speedup | Cache mem | Disk | IO reads | Status |
|--------|----------|---------|-----------|------|----------|--------|
| 8MB | 3717 | 0.01× | 7MB | 17MB | 0 | ➖ |
| 16MB | 1909 | 0.02× | 15MB | 10MB | 0 | ➖ |
| 32MB | 16 | 2.08× | 31MB | 0MB | 0 | ✅ |
| 64MB | 16 | 2.08× | 63MB | 0MB | 0 | ✅ |
| 128MB | 16 | 2.05× | 127MB | 0MB | 0 | ✅ |
| 256MB | 15 | 2.19× | 181MB | 0MB | 0 | ✅ |
| 384MB | 16 | 2.05× | 181MB | 0MB | 0 | ✅ |
| 512MB | 15 | 2.11× | 181MB | 0MB | 0 | ✅ |
| 768MB | 16 | 2.02× | 181MB | 0MB | 0 | ✅ |
| 1024MB | 16 | 2.08× | 181MB | 0MB | 0 | ✅ |
| 2048MB | 16 | 2.05× | 181MB | 0MB | 0 | ✅ |

## Q40 (Pushdown baseline: 38ms)

| Budget | Hot (ms) | Speedup | Cache mem | Disk | IO reads | Status |
|--------|----------|---------|-----------|------|----------|--------|
| 8MB | 86 | 0.44× | 7MB | 7MB | 0 | ➖ |
| 16MB | 20 | 1.88× | 15MB | 0MB | 0 | ✅ |
| 32MB | 20 | 1.90× | 24MB | 0MB | 0 | ✅ |
| 64MB | 20 | 1.90× | 24MB | 0MB | 0 | ✅ |
| 128MB | 20 | 1.88× | 24MB | 0MB | 0 | ✅ |
| 256MB | 20 | 1.92× | 24MB | 0MB | 0 | ✅ |
| 384MB | 21 | 1.81× | 24MB | 0MB | 0 | ✅ |
| 512MB | 20 | 1.85× | 24MB | 0MB | 0 | ✅ |
| 768MB | 20 | 1.92× | 24MB | 0MB | 0 | ✅ |
| 1024MB | 21 | 1.79× | 24MB | 0MB | 0 | ✅ |
| 2048MB | 20 | 1.88× | 24MB | 0MB | 0 | ✅ |

## Q42 (Pushdown baseline: 33ms)

| Budget | Hot (ms) | Speedup | Cache mem | Disk | IO reads | Status |
|--------|----------|---------|-----------|------|----------|--------|
| 8MB | 20 | 1.66× | 7MB | 0MB | 0 | ✅ |
| 16MB | 18 | 1.82× | 13MB | 0MB | 0 | ✅ |
| 32MB | 18 | 1.77× | 13MB | 0MB | 0 | ✅ |
| 64MB | 18 | 1.82× | 13MB | 0MB | 0 | ✅ |
| 128MB | 18 | 1.82× | 13MB | 0MB | 0 | ✅ |
| 256MB | 18 | 1.79× | 13MB | 0MB | 0 | ✅ |
| 384MB | 18 | 1.79× | 13MB | 0MB | 0 | ✅ |
| 512MB | 18 | 1.82× | 13MB | 0MB | 0 | ✅ |
| 768MB | 20 | 1.66× | 13MB | 0MB | 0 | ✅ |
| 1024MB | 20 | 1.68× | 13MB | 0MB | 0 | ✅ |
| 2048MB | 18 | 1.82× | 13MB | 0MB | 0 | ✅ |

