# Complete End-to-End Query Flow in LiquidCache (Based on `main` Branch)

```sql
SELECT Title, COUNT(*) FROM hits
WHERE EventDate >= '2013-07-01' AND EventDate <= '2013-07-31'
GROUP BY Title ORDER BY COUNT(*) DESC LIMIT 10
```

This document traces the exact code path from SQL submission to result, showing every layer.

---

## PHASE 0: Session & Cache Setup

**File:** `src/datafusion-local/src/lib.rs` → `LiquidCacheLocalBuilder::build()`

```rust
let v = LiquidCacheLocalBuilder::new()
    .with_max_memory_bytes(cache_size)
    .with_cache_dir(cache_dir)
    .with_cache_policy(Box::new(LiquidPolicy::new()))
    .with_hydration_policy(Box::new(NoHydration::new()))
    .with_squeeze_policy(Box::new(TranscodeSqueezeEvict))
    .build(session_config)
    .await?;
// Returns: (SessionContext, LiquidCacheParquetRef)
```

This creates:
1. **`LiquidCache`** (`src/core/src/cache/core.rs`): The core cache engine with a memory budget, disk budget, cache policy, squeeze policy. Internally uses an `Index` (concurrent map of `EntryID → CacheEntry`) and a `t4::Store` for disk-backed entries.
2. **`LiquidCacheParquet`** (`src/datafusion/src/cache/mod.rs`): Wraps `LiquidCache` with Parquet-specific logic (file tracking, row groups, column metadata).
3. **`SessionContext`** with two physical optimizer rules registered:
   - `LineageOptimizer` — analyzes column expressions (date-part extraction, substring patterns) to annotate schema metadata
   - `LocalModeOptimizer` — rewrites `ParquetSource` → `LiquidParquetSource`

---

## PHASE 1: SQL Parsing & Logical Planning (DataFusion)

**Entry:** `ctx.sql("SELECT Title, COUNT(*) FROM hits WHERE ...")` → DataFusion's SQL planner

DataFusion produces this logical plan:
```
Sort: [pageviews DESC], fetch=10
  Projection: [Title, count(1) AS pageviews]
    Aggregate: groupBy=[Title], aggr=[COUNT(1)]
      Filter: EventDate >= '2013-07-01' AND EventDate <= '2013-07-31'
        TableScan: hits
```

DataFusion's logical optimizer applies:
- **Projection pushdown:** Only `Title` and `EventDate` needed from file
- **Filter pushdown:** WHERE moves into the scan layer

---

## PHASE 2: Physical Planning (DataFusion)

DataFusion converts to physical plan:
```
SortExec: TopK(fetch=10), expr=[pageviews DESC]
  ProjectionExec: [Title, count(1) AS pageviews]
    AggregateExec: mode=FinalPartitioned, gby=[Title], aggr=[count(1)]
      RepartitionExec: Hash([Title], 16)
        AggregateExec: mode=Partial, gby=[Title], aggr=[count(1)]
          DataSourceExec:
            source: ParquetSource
            projection: [Title]
            predicate: EventDate >= '2013-07-01' AND EventDate <= '2013-07-31'
```

**Key:** The `DataSourceExec` has `projection=[Title]` (output schema) but carries the predicate expression referencing `EventDate`. DataFusion's `pushdown_filters=true` means the predicate is evaluated row-by-row during scan, not after.

---

## PHASE 3: Physical Optimizer Rewrites

### 3a. LineageOptimizer

**File:** `src/datafusion/src/optimizers/lineage_opt.rs`

Walks the plan tree analyzing expressions above the scan. Looks for patterns like:
- `date_part('month', EventDate)` → annotates field metadata with `liquid.cache.date_mapping`
- `col LIKE '%pattern%'` → annotates with `liquid.cache.string_fingerprint`

For Q37, the predicate is a simple range comparison — no annotations added.

### 3b. LocalModeOptimizer

**File:** `src/datafusion/src/optimizers/mod.rs` → `try_optimize_parquet_source()` (line ~90)

```rust
fn try_optimize_parquet_source(plan, cache) {
    if let Some((file_scan_config, parquet_source)) =
        data_source_exec.downcast_to_file_source::<ParquetSource>()
    {
        // REPLACE ParquetSource with LiquidParquetSource
        let new_source = LiquidParquetSource::from_parquet_source(parquet_source, cache);
        new_config.file_source = Arc::new(new_source);
        // ...
    }
}
```

**File:** `src/datafusion/src/reader/plantime/source.rs` → `from_parquet_source()` (line 236)

```rust
pub fn from_parquet_source(source: ParquetSource, liquid_cache: LiquidCacheParquetRef) -> Self {
    let predicate = source.filter();  // The WHERE clause physical expression
    // Copies projection, table_schema from original source
    if let Some(predicate) = predicate {
        v = v.with_predicate(file_schema, predicate);
        // → creates PruningPredicate (for row group statistics pruning)
        // → creates PagePruningAccessPlanFilter (for page index pruning)
    }
}
```

After this pass, `DataSourceExec` now uses `LiquidParquetSource` (`file_type=liquid_parquet`).

---

## PHASE 4: Execution Begins — File Opening

When DataFusion executes the plan, it calls `create_file_opener()` on each partition:

**File:** `src/datafusion/src/reader/plantime/source.rs` → `create_file_opener()` (line 279)

```rust
fn create_file_opener(&self, object_store, base_config, partition) {
    let opener = LiquidParquetOpener::new(
        partition,
        self.projection,        // [Title]
        self.batch_size,        // 8192 (from LiquidCache config)
        self.limit,             // None
        self.predicate,         // EventDate >= ... AND EventDate <= ...
        self.table_schema,
        self.metrics,
        self.liquid_cache,      // LiquidCacheParquetRef
        reader_factory,
        self.reorder_filters,
        expr_adapter_factory,
        span,
    );
    Ok(Arc::new(opener))
}
```

**File:** `src/datafusion/src/reader/plantime/opener.rs` → `open()` (line 121)

This is the main file-opening async function. Steps:

### 4a. Load Parquet Metadata

```rust
let reader_metadata = ArrowReaderMetadata::load_async(&mut reader, options).await?;
// Loads file footer: row group metadata, column statistics, schema
```

### 4b. Schema Enrichment

```rust
let physical_file_schema = transfer_lineage_metadata_to_file_schema(
    logical_file_schema, physical_file_schema);
// Copies any liquid.cache.* metadata from logical schema to physical
```

### 4c. Row Group Pruning (Statistics-Based)

```rust
let predicate = pruning_predicate.as_ref();  // PruningPredicate for EventDate range
row_groups.prune_by_statistics(schema, parquet_schema, rg_metadata, predicate, metrics);
```

Uses min/max statistics from each row group's EventDate column metadata.
**Result:** `row_groups_pruned_statistics=226 total → 3 matched`

Only 3 out of 226 row groups have EventDate values in the range [2013-07-01, 2013-07-31].

### 4d. Bloom Filter Pruning (Optional)

```rust
row_groups.prune_by_bloom_filters(schema, &mut builder, predicate, metrics).await;
```
For Q37: bloom filters don't help further (statistics already pruned well).

### 4e. Page Index Pruning (Optional)

```rust
access_plan = page_pruning_predicate.prune_plan_with_page_index(...);
```
**Result:** `page_index_pages_pruned=0` (no additional pruning at page level).

### 4f. Build Row Filter from Predicate Expression

**File:** `src/datafusion/src/reader/plantime/row_filter.rs` → `build_row_filter()` (line 428)

```rust
pub fn build_row_filter(expr, physical_file_schema, metadata, reorder, metrics) {
    // Split conjunction: "A >= X AND A <= Y" → [pred1, pred2]
    let predicates = split_conjunction(expr);
    
    // Each becomes a FilterCandidate:
    let candidates: Vec<FilterCandidate> = predicates.iter()
        .map(|expr| FilterCandidateBuilder::new(expr, schema).build(metadata))
        .collect();
    
    // Convert to LiquidPredicates:
    candidates.into_iter().map(|candidate| {
        let projection = ProjectionMask::roots(schema_descr, candidate.projection);
        LiquidPredicate::try_new_with_metrics(candidate, projection, metrics...)
    }).collect()
    // → LiquidRowFilter { predicates: [pred_ge, pred_le] }
}
```

**`LiquidPredicate`** (`row_filter.rs` line 137):
```rust
pub struct LiquidPredicate {
    physical_expr: Arc<dyn PhysicalExpr>,   // rewritten with 0-based column indices
    physical_expr_physical_column_index: Arc<dyn PhysicalExpr>,  // original file column indices
    projection_mask: ProjectionMask,         // which columns needed (EventDate)
    rows_pruned: Count,
    rows_matched: Count,
    time: Time,
}
```

### 4g. Build LiquidStream

```rust
let liquid_cache = lc.register_or_get_file(file_loc, cache_full_schema);
// → CachedFile with file_id, schema

let stream = LiquidStreamBuilder::new(reader, metadata)
    .with_batch_size(8192)
    .with_row_groups(row_group_indexes)       // [3 surviving row groups]
    .with_projection(mask)                    // ProjectionMask for [Title]
    .with_selection(row_selection)            // from page index pruning
    .with_row_filter(row_filter)             // LiquidRowFilter
    .build(liquid_cache)?;
```

---

## PHASE 5: Stream Execution — Per Row Group

**File:** `src/datafusion/src/reader/runtime/liquid_stream.rs` → `LiquidStream::poll_next()` (line 399)

```rust
fn poll_next(self, cx) -> Poll<Option<Result<RecordBatch>>> {
    loop {
        match state {
            StreamState::Init => {
                let row_group_idx = self.row_groups.pop_front()?;
                let context = self.reader.plan_row_group(row_group_idx, ...);
                let batch_reader = build_liquid_cache_reader(reader, context, schema);
                self.state = StreamState::ReadFromCache(batch_reader);
            }
            StreamState::ReadFromCache(reader) => {
                match reader.poll_next(cx) {
                    Ready(Some(Ok(batch))) => return Ready(Some(Ok(batch))),
                    Ready(None) => { /* row group done, go to Init for next */ }
                    Pending => return Pending,
                }
            }
        }
    }
}
```

### 5a. plan_row_group()

**File:** `liquid_stream.rs` → `ReaderFactory::plan_row_group()` (line 47)

```rust
fn plan_row_group(&mut self, row_group_idx, selection, projection, batch_size) {
    // Extract predicate projection (which columns predicates need):
    let predicate_projection = filter.predicates().map(|p| p.projection());
    // → ProjectionMask for [EventDate]
    
    // Build cache_projection = output projection ∪ predicate projection:
    let mut cache_projection = projection.clone();    // [Title]
    cache_projection.union(&predicate_projection);    // [Title, EventDate]
    
    // Resolve to column IDs:
    let cache_column_ids = get_root_column_ids(schema_descr, &cache_projection);
    // → e.g., [15, 93] (Title=col15, EventDate=col93 in file schema)
    
    let projection_column_ids = get_root_column_ids(schema_descr, &projection);
    // → [15] (Title only — what goes into output)
    
    let predicate_column_ids = get_root_column_ids(schema_descr, &predicate_projection);
    // → [93] (EventDate — used to mark as predicate column)
    
    // Create CachedRowGroup:
    let cached_row_group = self.cached_file.create_row_group(row_group_idx, predicate_column_ids);
    
    PlanningContext {
        cached_row_group,
        projection_column_ids: [15],     // Title
        cache_column_ids: [15, 93],      // Title + EventDate
        ...
    }
}
```

### 5b. CachedRowGroup Creation

**File:** `src/datafusion/src/cache/mod.rs` → `CachedFile::create_row_group()` (line 194)

```rust
pub fn create_row_group(&self, row_group_id, predicate_column_ids) {
    // Creates a CachedColumn for EVERY column in the file schema (105 columns):
    let columns = self.file_schema.fields().iter().enumerate().map(|(idx, field)| {
        let is_predicate_column = predicate_column_ids.contains(&idx);
        (idx, field, is_predicate_column)
    });
    
    CachedRowGroup::new(cache_store, row_group_id, file_id, &columns)
}
```

**File:** `src/datafusion/src/cache/mod.rs` → `CachedRowGroup::new()` (line 48)

```rust
fn new(cache_store, row_group_idx, file_idx, columns) {
    for (column_id, field, is_predicate_column) in columns {
        let column = CachedColumn::new(field, cache_store, column_access_path, is_predicate_column);
        // Stores in both by_id and by_name maps
    }
}
```

**File:** `src/datafusion/src/cache/column.rs` → `CachedColumn::new()` (line 69)

```rust
pub fn new(field, cache_store, column_access_path, is_predicate_column) {
    let expression = infer_expression(field);
    // For EventDate (Date32, no date_mapping metadata): expression = None
    // For Title (Utf8View, no string_fingerprint metadata): expression = None
    
    if is_predicate_column {
        // EventDate: register a squeeze hint as PredicateColumn
        cache_store.add_squeeze_hint(&hint_entry_id, CacheExpression::PredicateColumn);
    }
    
    Self { field, cache_store, column_path, expression }
}
```

### 5c. build_liquid_cache_reader()

**File:** `liquid_stream.rs` → `build_liquid_cache_reader()` (line 155)

```rust
fn build_liquid_cache_reader(reader_factory, context, schema) {
    LiquidCacheReader::new(LiquidCacheReaderConfig {
        batch_size: 8192,
        selection: context.selection,
        row_filter: reader_factory.filter.take(),     // LiquidRowFilter [pred_ge, pred_le]
        cached_row_group: context.cached_row_group,
        projection_columns: context.projection_column_ids,  // [15] (Title)
        schema,                                        // Schema([Title])
        parquet_fallback: ParquetFallbackConfig {
            cache_projection,                          // [Title, EventDate]
            cache_column_ids: [15, 93],                // Title + EventDate
            cache_batch_size: 8192,
            row_count,
            ...
        },
    })
}
```

---

## PHASE 6: Batch Reader — The Hot Loop

**File:** `src/datafusion/src/reader/runtime/liquid_cache_reader.rs`

The `LiquidCacheReader` is a `Stream` that produces `RecordBatch` items.

### Stream State Machine

```rust
impl Stream for LiquidCacheReader {
    fn poll_next(self, cx) {
        loop {
            match state {
                ReaderState::Ready(inner) => {
                    // Get next batch's RowSelection (8192 rows worth)
                    let selection = take_next_batch(&mut inner.selection, batch_size);
                    // Spawn async processing
                    let future = inner.next_batch(row_filter, selection);
                    self.state = ReaderState::Processing(future);
                }
                ReaderState::Processing(fut) => {
                    match fut.poll(cx) {
                        Ready((inner, filter, ProcessResult::Emit(batch))) => {
                            return Ready(Some(batch));
                        }
                        Ready((inner, filter, ProcessResult::Skip)) => {
                            continue;  // all rows filtered, try next batch
                        }
                        Pending => return Pending,
                    }
                }
            }
        }
    }
}
```

### next_batch() — Per-Batch Entry Point

**File:** `liquid_cache_reader.rs` → `LiquidCacheReaderInner::next_batch()` (line 262)

```rust
fn next_batch(self, row_filter, selection) -> BoxFuture<...> {
    Box::pin(async move {
        inner.last_pull = None;  // reset memoized Parquet read

        let result = match inner.build_predicate_filter(&mut row_filter, selection).await {
            Ok(selection) => match inner.read_from_cache(&selection).await {
                Ok(Some(batch)) => {
                    inner.current_batch_id.inc();
                    ProcessResult::Emit(Ok(batch))
                }
                Ok(None) => {
                    inner.current_batch_id.inc();
                    ProcessResult::Skip   // all rows pruned
                }
                Err(e) => ProcessResult::Emit(Err(e)),
            },
            Err(e) => ProcessResult::Emit(Err(e)),
        };

        (inner, row_filter, result)
    })
}
```

**Two main steps per batch:**
1. `build_predicate_filter()` — evaluate WHERE clause → `BooleanBuffer`
2. `read_from_cache()` — read projected columns for surviving rows → `RecordBatch`

---

### STEP A: build_predicate_filter() — WHERE Clause Evaluation

**File:** `liquid_cache_reader.rs` line 290

```rust
async fn build_predicate_filter(&mut self, row_filter, selection) -> Result<BooleanBuffer> {
    let mut input_selection = row_selector_to_boolean_buffer(&selection);
    // Converts RowSelection to a BooleanBuffer (e.g., [true; 8192])
    
    let Some(filter) = row_filter.as_mut() else {
        return Ok(input_selection);  // no filter → return all rows
    };

    for predicate in filter.predicates_mut() {
        // predicates = ["EventDate >= 2013-07-01", "EventDate <= 2013-07-31"]
        
        if input_selection.count_set_bits() == 0 { break; }
        
        // TRY 1: evaluate predicate using CACHED data
        let boolean_array = match self.cached_row_group
            .evaluate_selection_with_predicate(batch_id, &input_selection, predicate)
            .await
        {
            Some(result) => result?,   // ← cache had the data, evaluated successfully
            None => {
                // TRY 2: cache miss → read from Parquet, fill cache, then evaluate
                self.evaluate_predicate_after_materialize(&input_selection, predicate).await?
            }
        };

        // AND the predicate result into the running selection:
        let boolean_mask = boolean_array.into_parts().0;
        input_selection = boolean_buffer_and_then(&input_selection, &boolean_mask);
    }

    Ok(input_selection)
}
```

#### Path A1: Cache Hit for Predicate (Hot Query)

**File:** `src/datafusion/src/cache/mod.rs` → `evaluate_selection_with_predicate()` (line 98)

```rust
pub async fn evaluate_selection_with_predicate(&self, batch_id, selection, predicate) {
    let column_ids = predicate.predicate_column_ids();
    // → [93] (EventDate file column index)
    
    if column_ids.len() == 1 {
        let column_id = column_ids[0];  // 93
        let cache = self.get_column(column_id as u64)?;  // CachedColumn for EventDate
        return cache.eval_predicate_with_filter(batch_id, selection, predicate).await;
    }
    // (multi-column OR path omitted for clarity)
}
```

**File:** `src/datafusion/src/cache/column.rs` → `eval_predicate_with_filter()` (line 109)

```rust
pub async fn eval_predicate_with_filter(&self, batch_id, filter, predicate) {
    let entry_id = self.entry_id(batch_id).into();
    
    // Build a LiquidExpr from the physical expression:
    let liquid_expr = LiquidExpr::try_new(
        predicate.physical_expr(),  // e.g., col(0) >= ScalarValue::Date32(15887)
        self.field.data_type(),     // Date32
        self.expression.as_deref(), // None (no date-part annotation for plain EventDate)
    );
    // LiquidExpr wraps the PhysicalExpr for evaluation on Liquid/Arrow arrays

    if let Some(liquid_expr) = liquid_expr
        && let Some(boolean_array) = self.cache_store
            .eval_predicate(&entry_id, &liquid_expr)
            .with_selection(filter)
            .await
            // ↑ THIS IS THE CACHE READ
    {
        return Some(Ok(boolean_array));  // ✓ Predicate evaluated from cache
    }
    
    // Fallback: try to get raw array from cache and evaluate manually
    let array = self.get_arrow_array_with_filter(batch_id, filter).await?;
    let record_batch = self.array_to_record_batch(array);
    let boolean_array = predicate.evaluate(record_batch)?;
    Some(Ok(boolean_array))
}
```

**File:** `src/core/src/cache/builders.rs` → `EvaluatePredicate` (line 314)

```rust
pub struct EvaluatePredicate<'a> {
    storage: &'a LiquidCache,
    entry_id: &'a EntryID,
    predicate: &'a LiquidExpr,
    selection: Option<&'a BooleanBuffer>,
}

impl EvaluatePredicate {
    pub async fn read(self) -> Option<BooleanArray> {
        self.storage.eval_predicate_internal(self.entry_id, self.selection, self.predicate).await
    }
}
```

**File:** `src/core/src/cache/core.rs` → `eval_predicate_internal()` (line 862)

```rust
pub(crate) async fn eval_predicate_internal(&self, entry_id, selection_opt, predicate) {
    // ★ INCREMENT COUNTER ★
    self.observer.on_eval_predicate();
    
    // ★ CACHE LOOKUP ★
    let batch = self.index.get(entry_id)?;
    // Returns None if not cached (cold start)
    // Returns Some(Arc<CacheEntry>) if found
    
    self.cache_policy.notify_access(entry_id, batch_type);  // LRU bookkeeping
    
    match batch.as_ref() {
        CacheEntry::MemoryArrow(array) => {
            // Filter rows by selection, then evaluate predicate
            let filtered = arrow::compute::filter(array, &selection_array)?;
            Some(self.eval_predicate_on_array(filtered, predicate))
        }
        CacheEntry::MemoryLiquid(array) => {
            // ★ FASTEST PATH: evaluate predicate directly on compressed Liquid array
            Some(array.try_eval_predicate(predicate, selection))
            // No decompression needed — Liquid format supports direct comparison
        }
        CacheEntry::MemorySqueezedLiquid(array) => {
            // Evaluate on squeezed form (may short-circuit via date32 expression)
            self.eval_predicate_on_squeezed(array, selection_opt, predicate).await
        }
        CacheEntry::DiskArrow { .. } => {
            // Read from disk, hydrate to memory, then evaluate
            let array = self.read_disk_arrow_array(entry_id).await;
            self.maybe_hydrate(...);
            Some(self.eval_predicate_on_array(filtered, predicate))
        }
        CacheEntry::DiskLiquid { .. } => {
            // Read from disk, hydrate to memory, then evaluate
            let liquid = self.read_disk_liquid_array(entry_id).await;
            self.maybe_hydrate(...);
            Some(liquid.try_eval_predicate(predicate, selection))
        }
    }
}
```

**For Q37 hot runs:** EventDate is transcoded into `MemoryLiquid` format (bitpacked Date32). The predicate `>= 2013-07-01` is evaluated DIRECTLY on the compressed Liquid array — no Arrow materialization needed. The counter `eval_predicate` increments once per batch per predicate.

#### Path A2: Cache Miss for Predicate (Cold Start, Iteration 0)

If `self.index.get(entry_id)` returns `None` (first time accessing this batch):

Back in `build_predicate_filter()`:
```rust
None => {
    self.evaluate_predicate_after_materialize(&input_selection, predicate).await?
}
```

**File:** `liquid_cache_reader.rs` → `evaluate_predicate_after_materialize()` (line 418)

```rust
async fn evaluate_predicate_after_materialize(&mut self, selection, predicate) {
    // Read ALL cache columns from Parquet AND fill cache:
    let record_batch = self.read_parquet_batch_and_fill_cache(self.current_batch_id).await?;
    // ↑ This reads [Title, EventDate] from Parquet and inserts into cache
    
    // Now try cache evaluation again (it was just inserted):
    if let Some(result) = self.cached_row_group
        .evaluate_selection_with_predicate(batch_id, selection, predicate).await
    {
        return result;  // Should succeed now
    }
    
    // Final fallback: evaluate predicate on raw Arrow arrays from Parquet
    // (handles cases where data couldn't be cached due to memory pressure)
    let arrays = predicate_column_ids.map(|id| parquet_array(&record_batch, id));
    let predicate_batch = RecordBatch::try_new(schema, arrays)?;
    predicate.evaluate(predicate_batch)
}
```

---

### STEP B: read_from_cache() — Projection Read (SELECT Columns)

**File:** `liquid_cache_reader.rs` line 310

```rust
async fn read_from_cache(&mut self, selection: &BooleanBuffer) -> Result<Option<RecordBatch>> {
    let selected_rows = selection.count_set_bits();
    if selected_rows == 0 {
        return Ok(None);  // entire batch filtered out → skip
    }
    
    if self.projection_columns.is_empty() {
        // COUNT(*) with no projected columns → return empty batch with row count
        return Ok(Some(RecordBatch::with_row_count(selected_rows)));
    }

    let mut arrays = Vec::with_capacity(self.projection_columns.len());
    
    for column_idx in self.projection_columns.clone() {
        // projection_columns = [15] (Title)
        
        let column = self.cached_row_group.get_column(column_idx as u64)?;
        // → CachedColumn for Title
        
        // TRY CACHE:
        let array = column.get_arrow_array_with_filter(self.current_batch_id, selection).await;
```

**File:** `src/datafusion/src/cache/column.rs` → `get_arrow_array_with_filter()` (line 160)

```rust
pub async fn get_arrow_array_with_filter(&self, batch_id, filter) -> Option<ArrayRef> {
    let entry_id = self.entry_id(batch_id).into();
    self.cache_store
        .get(&entry_id)
        .with_selection(filter)
        .with_optional_expression_hint(self.expression())
        .read()
        .await
}
```

**File:** `src/core/src/cache/builders.rs` → `Get::read()` (line 257)

```rust
pub async fn read(self) -> Option<ArrayRef> {
    self.storage.observer().on_get(self.selection.is_some());  // increments `get` counter
    self.storage.read_arrow_array(self.entry_id, self.selection, self.expression_hint).await
}
```

**File:** `src/core/src/cache/core.rs` → `read_arrow_array()` (line 595)

```rust
pub(crate) async fn read_arrow_array(&self, entry_id, selection, expression) -> Option<ArrayRef> {
    let batch = self.index.get(entry_id)?;
    // Returns None if entry not cached → triggers Parquet fallback
    
    self.cache_policy.notify_access(entry_id, batch_type);
    
    match batch.as_ref() {
        CacheEntry::MemoryArrow(array) => {
            // Filter by selection and return
            let filtered = arrow::compute::filter(array, &selection_array).ok()?;
            Some(filtered)
        }
        CacheEntry::MemoryLiquid(array) => {
            // Decompress Liquid to Arrow, apply filter
            Some(array.filter(selection))
        }
        CacheEntry::MemorySqueezedLiquid(array) => {
            // May use expression hint to avoid full decompression
            self.read_squeezed_array(array, entry_id, expression, selection).await
        }
        CacheEntry::DiskArrow { .. } | CacheEntry::DiskLiquid { .. } => {
            // Read from disk, hydrate, apply filter
            self.read_disk_array(batch, entry_id, expression, selection).await
        }
    }
}
```

**For Q37, Hot Run:**
- Title was inserted into cache during the cold run (via `read_parquet_batch_and_fill_cache`)
- On hot runs, `self.index.get(entry_id)` finds Title in cache
- Returns the cached array (likely `MemoryLiquid` after transcode)
- The `get` counter increments (visible as `get` in stats)

**For Q37, Cold Run (first call for this batch):**
- `self.index.get(entry_id)` returns `None`
- Back in `read_from_cache()`:

```rust
        let array = match array {
            Some(array) => array,  // ← cache hit path
            None => {
                // PARQUET FALLBACK:
                let record_batch = self.read_parquet_batch_and_fill_cache(batch_id).await?;
                let array = self.parquet_array(&record_batch, column_idx)?;
                filter_array(array, selection)?
            }
        };
        arrays.push(array);
    }
    
    Ok(Some(RecordBatch::try_new(self.schema.clone(), arrays)?))
}
```

---

### Parquet Fallback & Cache Fill

**File:** `liquid_cache_reader.rs` → `read_parquet_batch_and_fill_cache()` (line 370)

```rust
async fn read_parquet_batch_and_fill_cache(&mut self, batch_id) -> Result<RecordBatch> {
    // Memoization: if we already read this batch (for predicate eval), reuse it
    if let Some((pulled_batch_id, record_batch)) = &self.last_pull
        && *pulled_batch_id == batch_id
    {
        return Ok(record_batch.clone());
    }

    // Read from Parquet file (ACTUAL DISK IO):
    let record_batch = self.parquet_fallback.fetch_batch(batch_id).await?;
    // Reads columns [Title, EventDate] (the cache_column_ids) from the Parquet file
    
    // Fill cache with ALL columns we just read:
    for (col_idx, file_column_id) in self.parquet_fallback.cache_column_ids.iter() {
        // file_column_id iterates: [15 (Title), 93 (EventDate)]
        let column = self.cached_row_group.get_column(file_column_id)?;
        let array = record_batch.column(col_idx).clone();
        
        match column.insert(batch_id, array).await {
            Ok(()) => {}                              // inserted successfully
            Err(InsertArrowArrayError::AlreadyCached) => {}  // another thread beat us
            Err(InsertArrowArrayError::CacheFull) => {}      // no memory/disk budget
        }
    }

    self.last_pull = Some((batch_id, record_batch.clone()));
    Ok(record_batch)
}
```

**File:** `src/datafusion/src/cache/column.rs` → `insert()` (line 174)

```rust
pub async fn insert(self: &Arc<Self>, batch_id, array) -> Result<(), InsertArrowArrayError> {
    if self.is_cached(batch_id) {
        return Err(InsertArrowArrayError::AlreadyCached);
    }
    self.cache_store.insert(self.entry_id(batch_id).into(), array).await?;
    Ok(())
}
```

**File:** `src/core/src/cache/core.rs` → `insert()` inserts the Arrow array into the cache index, subject to memory budget. The cache policy (TranscodeSqueezeEvict) will:
1. Accept the array as `MemoryArrow`
2. Transcode it to `MemoryLiquid` (compressed format) on a background task
3. If memory is full, squeeze to `MemorySqueezedLiquid` or evict to disk

---

## PHASE 7: Output Assembly

After `read_from_cache()` returns a `RecordBatch` (with schema `[Title]` and only rows passing the date filter), it flows up through:

1. `LiquidCacheReader` → emits batch to `LiquidStream`
2. `LiquidStream` → applies output projection (identity for Q37)
3. DataFusion's `AggregateExec` → accumulates GROUP BY Title, COUNT(*)
4. `RepartitionExec` → hash-partitions by Title across 16 threads
5. Final `AggregateExec` → merges partial aggregates
6. `SortExec` TopK → keeps top 10 by count DESC
7. Result returned to caller

---

## Summary: Cache Usage on Hot Query

| Operation | What It Does | Cache Used? | Counter |
|-----------|-------------|-------------|---------|
| Row group pruning | Skip row groups by statistics | No (Parquet metadata only) | `row_groups_pruned_statistics` |
| Predicate eval (EventDate) | Evaluate `>= 2013-07-01` on each batch | **YES** — reads from `MemoryLiquid` | `eval_predicate` |
| Projection read (Title) | Materialize Title values for surviving rows | **YES** — reads from cache if available | `get` / `get_with_selection` |
| Cache fill (cold start) | Insert arrays after Parquet read | YES — populates cache for future runs | (no counter) |

### On Main Branch (Default Behavior)

On `main`, ALL columns (including strings like Title) are cached. So for the hot run:
- `eval_predicate` counts for EventDate filter evaluation
- `get`/`get_with_selection` counts for Title projection read from cache
- Both Title AND EventDate are in `MemoryLiquid` format

The difference with our `skip-string-columns` branch is that Title would NOT be cached (returns None, always reads from Parquet), while on `main` it IS cached and served from memory on hot runs.

---

## Visual Flow (Main Branch, Hot Query)

```
┌──────────────────────────────────────────────────────────────────┐
│  DataFusion SQL → Logical Plan → Physical Plan                    │
│  LocalModeOptimizer: ParquetSource → LiquidParquetSource         │
└─────────────────────────────────┬────────────────────────────────┘
                                  │
                                  ▼
┌──────────────────────────────────────────────────────────────────┐
│  LiquidParquetOpener::open()                                      │
│  • Load Parquet metadata                                          │
│  • Row group pruning (statistics) → 226 → 3 RGs                  │
│  • Build LiquidRowFilter from predicate                           │
│  • Create LiquidStream                                            │
└─────────────────────────────────┬────────────────────────────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              ▼                   ▼                   ▼
         Row Group 0         Row Group 1        Row Group 2
              │                   │                   │
              ▼                   ▼                   ▼
┌──────────────────────────────────────────────────────────────────┐
│  Per-Batch Loop (8192 rows/batch, ~57 batches per RG)             │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ STEP A: build_predicate_filter()                            │  │
│  │                                                             │  │
│  │ For each predicate (EventDate >= X, EventDate <= Y):        │  │
│  │   → CachedRowGroup.evaluate_selection_with_predicate()      │  │
│  │     → CachedColumn(EventDate).eval_predicate_with_filter()  │  │
│  │       → LiquidCache.eval_predicate(entry_id, expr)          │  │
│  │         → index.get(entry_id) → MemoryLiquid(EventDate)     │  │
│  │         → liquid_array.try_eval_predicate(expr, selection)  │  │
│  │         → BooleanArray (which rows pass date filter)        │  │
│  │         → counter: eval_predicate++                         │  │
│  │                                                             │  │
│  │ Result: BooleanBuffer (only matching rows are true)         │  │
│  └─────────────────────────────┬──────────────────────────────┘  │
│                                │                                  │
│                                ▼                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ STEP B: read_from_cache(selection)                          │  │
│  │                                                             │  │
│  │ For column Title (projection_columns = [15]):               │  │
│  │   → CachedColumn(Title).get_arrow_array_with_filter()       │  │
│  │     → LiquidCache.get(entry_id).with_selection(filter)      │  │
│  │       → index.get(entry_id) → MemoryLiquid(Title)           │  │
│  │       → liquid_array.filter(selection)                      │  │
│  │       → Returns filtered Arrow array                        │  │
│  │       → counter: get++, get_with_selection++                │  │
│  │                                                             │  │
│  │ Result: RecordBatch([Title], filtered rows only)            │  │
│  └─────────────────────────────┬──────────────────────────────┘  │
│                                │                                  │
└────────────────────────────────┼──────────────────────────────────┘
                                 │
                                 ▼
                    → AggregateExec (GROUP BY Title)
                    → RepartitionExec (Hash by Title)
                    → AggregateExec (merge)
                    → SortExec TopK (top 10 by count)
                    → Result
```

---

## Key Counters Explained (Main Branch)

| Counter | What triggers it | Code location |
|---------|-----------------|---------------|
| `get` | Any call to `LiquidCache.get()` (projection read) | `core.rs` → `Get::read()` → `observer.on_get()` |
| `get_with_selection` | `get()` with a selection filter attached | same as above, when `selection.is_some()` |
| `eval_predicate` | Predicate evaluation on cached data | `core.rs` → `eval_predicate_internal()` → `observer.on_eval_predicate()` |
| `get_squeezed_success` | Squeezed array served without IO | `core.rs` → `read_squeezed_array()` → `observer.on_get_squeezed_success()` |
| `get_squeezed_needs_io` | Squeezed array needed disk read | `core.rs` → IO events |
| `read_io_count` | Any disk read (DiskArrow or DiskLiquid) | `observer.rs` → `record_internal(IoRead*)` |
| `write_io_count` | Any disk write (eviction to disk) | `observer.rs` → `record_internal(IoWrite*)` |
| `disk_evictions` | Entry evicted from disk | `observer.rs` → `record_internal(DiskEvict*)` |
| `try_read_liquid_calls` | Direct Liquid array read (for multi-column OR) | `core.rs` → `try_read_liquid()` |

---

## Cold vs Hot: What Changes

| Aspect | Cold (Iteration 0) | Hot (Iteration 1+) |
|--------|--------------------|--------------------|
| Row group pruning | Uses Parquet statistics | Same (Parquet metadata) |
| Predicate eval | `index.get()` = None → Parquet fallback → fills cache | `index.get()` = MemoryLiquid → direct eval |
| Projection read | `index.get()` = None → Parquet fallback → fills cache | `index.get()` = MemoryLiquid → direct filter |
| Disk IO | Yes (reading Parquet pages) | None (all in memory) |
| Time | ~149ms (metadata + IO + transcode) | ~94ms (pure compute) |
