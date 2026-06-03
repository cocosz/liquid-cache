# Per-Column Memory Usage — ClickBench hits.parquet

Measured by running `COUNT(DISTINCT "col")` on each of the 105 columns individually.  
Each column runs as a separate process (cache fully cleared between columns).  
Memory budget: 12.8GB (no spill to disk).

## Setup

| Component | Details |
|-----------|---------|
| **Instance** | AWS c6a.4xlarge (16 vCPUs, 32 GB RAM) |
| **Dataset** | ClickBench `hits.parquet` (~14GB, 99.99M rows, 105 columns) |
| **Query** | `SELECT COUNT(DISTINCT "col") FROM hits` per column |
| **Memory budget** | 12,800 MB (no disk spill) |
| **Cache mode** | Liquid (TranscodeSqueezeEvict) |
| **Cache format observed** | Arrow (no squeeze triggered — no memory pressure) |

## Results — All Columns Sorted by Memory (Descending)

| # | Column | Memory (MB) | Approx Type |
|---|--------|------------:|-------------|
| 1 | Title | 12,089 | Utf8 (large strings) |
| 2 | URL | 11,587 | Utf8 (large strings) |
| 3 | Referer | 8,274 | Utf8 (large strings) |
| 4 | OriginalURL | 7,647 | Utf8 (large strings) |
| 5 | PageCharset | 2,024 | Utf8 |
| 6 | SearchPhrase | 1,631 | Utf8 |
| 7 | UserAgentMinor | 1,145 | Utf8 |
| 8 | BrowserCountry | 1,145 | Utf8 |
| 9 | ParamCurrency | 1,145 | Utf8 |
| 10 | FlashMinor2 | 1,142 | Utf8 |
| 11 | BrowserLanguage | 1,131 | Utf8 |
| 12 | HitColor | 859 | Utf8 |
| 13 | Params | 806 | Utf8 |
| 14 | UTMCampaign | 796 | Utf8 |
| 15 | MobilePhoneModel | 796 | Utf8 |
| 16 | UTMSource | 787 | Utf8 |
| 17 | UTMMedium | 776 | Utf8 |
| 18 | OpenstatSourceID | 776 | Utf8 |
| 19 | OpenstatServiceName | 774 | Utf8 |
| 20 | OpenstatAdID | 771 | Utf8 |
| 21 | FromTag | 770 | Utf8 |
| 22 | ClientEventTime | 770 | Int64 |
| 23 | LocalEventTime | 769 | Int64 |
| 24 | EventTime | 769 | Int64 |
| 25 | OpenstatCampaignID | 769 | Utf8 |
| 26 | UTMTerm | 768 | Utf8 |
| 27 | SocialSourcePage | 768 | Utf8 |
| 28 | RefererHash | 767 | Int64 |
| 29 | URLHash | 767 | Int64 |
| 30 | UserID | 766 | Int64 |
| 31 | UTMContent | 766 | Utf8 |
| 32 | FUniqID | 766 | Int64 |
| 33 | ParamPrice | 764 | Int64 |
| 34 | WatchID | 764 | Int64 |
| 35 | ParamOrderID | 764 | Utf8 |
| 36 | SocialAction | 764 | Utf8 |
| 37 | SocialNetwork | 764 | Utf8 |
| 38 | ClientIP | 384 | Int32 |
| 39 | RemoteIP | 384 | Int32 |
| 40 | HID | 383 | Int32 |
| 41 | FetchTiming | 383 | Int32 |
| 42 | ConnectTiming | 383 | Int32 |
| 43 | RegionID | 383 | Int32 |
| 44 | SendTiming | 383 | Int32 |
| 45 | IPNetworkID | 383 | Int32 |
| 46 | ResponseStartTiming | 383 | Int32 |
| 47 | ResponseEndTiming | 383 | Int32 |
| 48 | DNSTiming | 383 | Int32 |
| 49 | WindowName | 383 | Utf8 (short/empty) |
| 50 | CLID | 383 | Int32 |
| 51 | CodeVersion | 383 | Int32 |
| 52 | CounterID | 383 | Int32 |
| 53 | OpenerName | 383 | Utf8 (short/empty) |
| 54 | RefererRegionID | 383 | Int32 |
| 55 | SilverlightVersion3 | 383 | Int32 |
| 56 | URLRegionID | 383 | Int32 |
| 57–105 | *(49 columns)* | ~192 each | Int16 / small int |

*(Int16 tier includes: AdvEngineID, Age, ClientTimeZone, CookieEnable, CounterClass, DontCountHits, EventDate, FlashMajor, FlashMinor, GoodEvent, HTTPError, HasGCLID, HistoryLength, Income, Interests, IsArtifical, IsDownload, IsEvent, IsLink, IsMobile, IsNotBounce, IsOldCounter, IsParameter, IsRefresh, JavaEnable, JavascriptEnable, MobilePhone, NetMajor, NetMinor, OS, ParamCurrencyID, RefererCategoryID, ResolutionDepth, ResolutionHeight, ResolutionWidth, Robotness, SearchEngineID, Sex, SilverlightVersion1, SilverlightVersion2, SilverlightVersion4, SocialSourceNetworkID, TraficSourceID, URLCategoryID, UserAgent, UserAgentMajor, WindowClientHeight, WindowClientWidth, WithHash)*

## Summary by Size Tier

| Tier | Per-Column | Count | Total (GB) | % of Total |
|------|----------:|------:|-----------:|-----------:|
| XL strings (URL, Title, etc.) | 7.6–12.1 GB | 4 | **39.6 GB** | 46% |
| L strings (SearchPhrase, etc.) | 1.1–2.0 GB | 7 | **9.4 GB** | 11% |
| M strings + Int64 | 764–806 MB | 26 | **20.0 GB** | 23% |
| Int32 | ~383 MB | 19 | **7.3 GB** | 9% |
| Int16 / small | ~192 MB | 49 | **9.4 GB** | 11% |
| **TOTAL** | | **105** | **85.8 GB** | 100% |

## Key Findings

### 1. String columns dominate memory

The top 4 string columns (URL, Title, Referer, OriginalURL) alone consume **39.6 GB** — nearly half of total cache memory. These are used in only a handful of queries (Q20-Q23, Q27, Q33-Q34).

### 2. Numeric columns are manageable

The 49 Int16 columns total ~9.4 GB in raw Arrow. After Liquid transcode + bitpacking, these would compress to roughly **2-4 GB** — easily fitting in a modest memory budget.

The 19 Int32 columns total ~7.3 GB raw, compressing to roughly **3-5 GB** after squeeze.

### 3. These are RAW Arrow sizes (no compression)

The measurements show Arrow format (no squeeze was triggered because memory wasn't full). After Liquid transcode:
- **Int16 columns**: ~4-8x compression (bitpacking narrow values)
- **Int32 columns**: ~2-4x compression
- **Int64 columns**: ~1.5-2x compression
- **String columns**: ~2-3x compression (FSST)

### 4. Recommendation: Cache Budget Planning

| Strategy | Columns Cached | Estimated Squeezed Size | Covers Queries |
|----------|---------------|------------------------:|----------------|
| Numeric only (Int16) | 49 cols | ~2-3 GB | Q1-Q9, Q29, Q35-Q42 |
| Numeric (Int16 + Int32) | 68 cols | ~4-6 GB | + Q30-Q31, timing queries |
| All numeric (+ Int64) | 80 cols | ~8-10 GB | + Q15-Q19, Q25 |
| All columns | 105 cols | ~12.5 GB | All queries |

### 5. Columns to NEVER cache (read from Parquet directly)

These 4 columns consume 46% of memory but are only used in 7 queries:
- **URL** (11.6 GB) — Q20, Q21, Q22, Q23, Q27, Q33, Q34, Q36, Q38
- **Title** (12.1 GB) — Q22, Q37
- **Referer** (8.3 GB) — Q28
- **OriginalURL** (7.6 GB) — rarely used

For these queries, reading directly from Parquet (baseline behavior) is actually faster than caching + disk spill.
