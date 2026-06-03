#!/bin/bash
set -e

# Measure per-column memory usage in LiquidCache
# Runs one column at a time with sleep between to let OS caches settle.
#
# Usage: ./run_column_memory.sh

rm -rf outputs/column_memory
mkdir -p outputs/column_memory/queries
mkdir -p outputs/column_memory/results

# All columns from the hits.parquet schema
ALL_COLS=(
  WatchID JavaEnable GoodEvent EventTime EventDate CounterID
  ClientIP RegionID UserID CounterClass OS UserAgent
  IsRefresh RefererCategoryID RefererRegionID URLCategoryID URLRegionID
  ResolutionWidth ResolutionHeight ResolutionDepth
  FlashMajor FlashMinor FlashMinor2 NetMajor NetMinor
  UserAgentMajor UserAgentMinor CookieEnable JavascriptEnable IsMobile MobilePhone
  MobilePhoneModel IPNetworkID TraficSourceID SearchEngineID AdvEngineID
  IsArtifical WindowClientWidth WindowClientHeight
  ClientTimeZone ClientEventTime
  SilverlightVersion1 SilverlightVersion2 SilverlightVersion3 SilverlightVersion4
  PageCharset CodeVersion IsLink IsDownload IsNotBounce
  FUniqID HID IsOldCounter IsEvent IsParameter
  DontCountHits WithHash HitColor LocalEventTime
  Age Sex Income Interests Robotness
  RemoteIP HistoryLength
  Title URL Referer SearchPhrase
  HTTPError SendTiming DNSTiming ConnectTiming
  ResponseStartTiming ResponseEndTiming FetchTiming
  SocialSourceNetworkID SocialSourcePage SocialNetwork SocialAction
  ParamPrice ParamOrderID ParamCurrencyID ParamCurrency
  HasGCLID RefererHash URLHash CLID
  OpenstatServiceName OpenstatCampaignID OpenstatAdID OpenstatSourceID
  UTMSource UTMMedium UTMCampaign UTMContent UTMTerm FromTag
  Params WindowName OpenerName
  BrowserLanguage BrowserCountry OriginalURL
)

echo "=== Running per-column memory measurement ==="
echo "Total columns: ${#ALL_COLS[@]}"
echo "Memory budget: 12800MB (no spill)"
echo ""

IDX=0
for col in "${ALL_COLS[@]}"; do
  IDX=$((IDX + 1))
  echo "[$IDX/${#ALL_COLS[@]}] Measuring: $col"

  # Create single-query manifest
  QUERY_FILE="outputs/column_memory/queries/${col}.sql"
  echo "SELECT COUNT(DISTINCT \"${col}\") FROM hits" > "$QUERY_FILE"

  cat > outputs/column_memory/manifest_${col}.json << EOF
{
  "name": "ColumnMemory_${col}",
  "tables": {
    "hits": "benchmark/clickbench/data/hits.parquet"
  },
  "queries": ["${QUERY_FILE}"]
}
EOF

  cargo run --release --bin in_process -- \
    --manifest outputs/column_memory/manifest_${col}.json \
    --bench-mode liquid \
    --max-memory-mb 12800 \
    --iteration 2 \
    --output outputs/column_memory/results/${col}.json \
    2>/dev/null

  echo "    Done: $col"

  # Sleep 2 seconds between columns to let caches settle
  sleep 2
done

echo ""
echo "=== All columns measured ==="
echo "Parse results: python3 parse_column_memory.py"
