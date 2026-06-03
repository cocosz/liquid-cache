# IOPS Comparison: 3K (old) vs 16K (new)

## Q19 (Baseline: old=85ms, new=86ms)

| Budget | Old Hot(ms) | New Hot(ms) | Improvement | Mem | Disk | Disk Read | Disk Write |
|--------|-------------|-------------|-------------|-----|------|-----------|------------|
| 8MB | 4796 | 682 | 7.0x | 7MB | 619MB | 632MB | 0MB |
| 16MB | 4664 | 630 | 7.4x | 15MB | 620MB | 615MB | 0MB |
| 32MB | 4392 | 603 | 7.3x | 31MB | 620MB | 581MB | 0MB |
| 64MB | 3856 | 509 | 7.6x | 63MB | 619MB | 514MB | 0MB |
| 128MB | 2778 | 364 | 7.6x | 127MB | 620MB | 379MB | 0MB |
| 256MB | 635 | 168 | 3.8x | 255MB | 620MB | 111MB | 0MB |
| 384MB | 33 | 33 | 1.0x | 383MB | 470MB | 0MB | 0MB |
| 512MB | 28 | 27 | 1.0x | 511MB | 216MB | 0MB | 0MB |
| 768MB | 20 | 21 | 1.0x | 668MB | 0MB | 0MB | 0MB |
| 1024MB | 22 | 21 | 1.0x | 668MB | 0MB | 0MB | 0MB |
| 2048MB | 21 | 21 | 1.0x | 668MB | 0MB | 0MB | 0MB |

## Q7 (Baseline: old=32ms, new=32ms)

| Budget | Old Hot(ms) | New Hot(ms) | Improvement | Mem | Disk | Disk Read | Disk Write |
|--------|-------------|-------------|-------------|-----|------|-----------|------------|
| 8MB | 3717 | 560 | 6.6x | 7MB | 17MB | 63MB | 0MB |
| 16MB | 1909 | 345 | 5.5x | 15MB | 10MB | 35MB | 0MB |
| 32MB | 16 | 16 | 1.0x | 31MB | 0MB | 0MB | 0MB |
| 64MB | 16 | 16 | 1.0x | 63MB | 0MB | 0MB | 0MB |
| 128MB | 16 | 16 | 1.0x | 127MB | 0MB | 0MB | 0MB |
| 256MB | 15 | 15 | 1.0x | 181MB | 0MB | 0MB | 0MB |
| 384MB | 16 | 15 | 1.0x | 181MB | 0MB | 0MB | 0MB |
| 512MB | 15 | 15 | 1.0x | 181MB | 0MB | 0MB | 0MB |
| 768MB | 16 | 16 | 1.0x | 181MB | 0MB | 0MB | 0MB |
| 1024MB | 16 | 16 | 1.0x | 181MB | 0MB | 0MB | 0MB |
| 2048MB | 16 | 16 | 1.0x | 181MB | 0MB | 0MB | 0MB |

## Q40 (Baseline: old=38ms, new=40ms)

| Budget | Old Hot(ms) | New Hot(ms) | Improvement | Mem | Disk | Disk Read | Disk Write |
|--------|-------------|-------------|-------------|-----|------|-----------|------------|
| 8MB | 86 | 190 | 0.5x | 7MB | 7MB | 4MB | 0MB |
| 16MB | 20 | 22 | 0.9x | 15MB | 0MB | 0MB | 0MB |
| 32MB | 20 | 20 | 1.0x | 24MB | 0MB | 0MB | 0MB |
| 64MB | 20 | 20 | 1.0x | 24MB | 0MB | 0MB | 0MB |
| 128MB | 20 | 22 | 0.9x | 24MB | 0MB | 0MB | 0MB |
| 256MB | 20 | 20 | 1.0x | 24MB | 0MB | 0MB | 0MB |
| 384MB | 21 | 20 | 1.1x | 24MB | 0MB | 0MB | 0MB |
| 512MB | 20 | 20 | 1.0x | 24MB | 0MB | 0MB | 0MB |
| 768MB | 20 | 20 | 1.0x | 24MB | 0MB | 0MB | 0MB |
| 1024MB | 21 | 21 | 1.0x | 24MB | 0MB | 0MB | 0MB |
| 2048MB | 20 | 20 | 1.0x | 24MB | 0MB | 0MB | 0MB |

## Q42 (Baseline: old=33ms, new=32ms)

| Budget | Old Hot(ms) | New Hot(ms) | Improvement | Mem | Disk | Disk Read | Disk Write |
|--------|-------------|-------------|-------------|-----|------|-----------|------------|
| 8MB | 20 | 18 | 1.1x | 7MB | 0MB | 0MB | 0MB |
| 16MB | 18 | 18 | 1.0x | 13MB | 0MB | 0MB | 0MB |
| 32MB | 18 | 18 | 1.0x | 13MB | 0MB | 0MB | 0MB |
| 64MB | 18 | 19 | 0.9x | 13MB | 0MB | 0MB | 0MB |
| 128MB | 18 | 18 | 1.0x | 13MB | 0MB | 0MB | 0MB |
| 256MB | 18 | 20 | 0.9x | 13MB | 0MB | 0MB | 0MB |
| 384MB | 18 | 19 | 1.0x | 13MB | 0MB | 0MB | 0MB |
| 512MB | 18 | 18 | 1.0x | 13MB | 0MB | 0MB | 0MB |
| 768MB | 20 | 18 | 1.1x | 13MB | 0MB | 0MB | 0MB |
| 1024MB | 20 | 18 | 1.1x | 13MB | 0MB | 0MB | 0MB |
| 2048MB | 18 | 18 | 1.0x | 13MB | 0MB | 0MB | 0MB |

