use arrow::{
    array::{Array, ArrayRef, BooleanArray, BooleanBufferBuilder},
    buffer::BooleanBuffer,
    compute::prep_null_mask_filter,
    record_batch::RecordBatch,
};
use arrow_schema::{ArrowError, DataType, Field, Schema};
use liquid_cache::cache::{CacheExpression, CacheFull, LiquidCache, LiquidExpr, MemoryEntry};
use parquet::arrow::arrow_reader::ArrowPredicate;

use crate::{
    LiquidPredicate,
    cache::{BatchID, ColumnAccessPath, PageID, ParquetArrayID},
    optimizers::{DATE_MAPPING_METADATA_KEY, STRING_FINGERPRINT_METADATA_KEY},
};
use std::sync::Arc;

/// A column in the cache.
#[derive(Debug)]
pub struct CachedColumn {
    cache_store: Arc<LiquidCache>,
    field: Arc<Field>,
    column_path: ColumnAccessPath,
    expression: Option<Arc<CacheExpression>>,
    /// Whether this column is used in a predicate (WHERE clause).
    /// In predicate-only mode, only predicate columns are cached.
    is_predicate_column: bool,
}

/// A reference to a cached column.
pub type CachedColumnRef = Arc<CachedColumn>;

fn infer_expression(field: &Field) -> Option<CacheExpression> {
    if let Some(mapping) = field.metadata().get(DATE_MAPPING_METADATA_KEY)
        && matches!(
            field.data_type(),
            DataType::Date32 | DataType::Timestamp(_, _)
        )
        && let Some(expr) = CacheExpression::try_from_date_part_str(mapping)
    {
        return Some(expr);
    }
    if field
        .metadata()
        .contains_key(STRING_FINGERPRINT_METADATA_KEY)
        && is_string_type(field.data_type())
    {
        return Some(CacheExpression::substring_search());
    }
    None
}

/// Error type for inserting an arrow array into the cache.
#[derive(Debug)]
pub enum InsertArrowArrayError {
    /// The array is already cached.
    AlreadyCached,
    /// The cache does not have enough disk budget to accept the array.
    CacheFull,
}

impl From<CacheFull> for InsertArrowArrayError {
    fn from(_: CacheFull) -> Self {
        Self::CacheFull
    }
}

impl CachedColumn {
    pub(crate) fn new(
        field: Arc<Field>,
        cache_store: Arc<LiquidCache>,
        column_access_path: ColumnAccessPath,
        is_predicate_column: bool,
    ) -> Self {
        let expression = infer_expression(field.as_ref()).map(Arc::new);
        if let Some(expr) = expression.as_ref() {
            let hint_entry_id = column_access_path.entry_id(BatchID::from_raw(0)).into();
            cache_store.add_squeeze_hint(&hint_entry_id, expr.clone());
        } else if is_predicate_column {
            let hint_entry_id = column_access_path.entry_id(BatchID::from_raw(0)).into();
            cache_store
                .add_squeeze_hint(&hint_entry_id, Arc::new(CacheExpression::PredicateColumn));
        }
        Self {
            field,
            cache_store,
            column_path: column_access_path,
            expression,
            is_predicate_column,
        }
    }

    /// row_id must be on a batch boundary.
    pub(crate) fn entry_id(&self, batch_id: BatchID) -> ParquetArrayID {
        self.column_path.entry_id(batch_id)
    }

    pub(crate) fn is_cached(&self, batch_id: BatchID) -> bool {
        self.cache_store.is_cached(&self.entry_id(batch_id).into())
    }

    /// Returns the Arrow field metadata for this cached column.
    pub fn field(&self) -> Arc<Field> {
        self.field.clone()
    }

    /// Returns the expression metadata associated with this column, if any.
    pub fn expression(&self) -> Option<Arc<CacheExpression>> {
        self.expression.clone()
    }

    /// Returns whether this column is a predicate column (used in WHERE clause).
    pub fn is_predicate_column(&self) -> bool {
        self.is_predicate_column
    }

    fn array_to_record_batch(&self, array: ArrayRef) -> RecordBatch {
        let schema = Arc::new(Schema::new(vec![self.field.clone()]));
        RecordBatch::try_new(schema, vec![array]).unwrap()
    }

    /// Evaluates a predicate on a cached column.
    pub async fn eval_predicate_with_filter(
        &self,
        batch_id: BatchID,
        filter: &BooleanBuffer,
        predicate: &mut LiquidPredicate,
    ) -> Option<Result<BooleanArray, ArrowError>> {
        let entry_id = self.entry_id(batch_id).into();
        let liquid_expr = LiquidExpr::try_new(
            Arc::clone(predicate.physical_expr()),
            self.field.data_type(),
            self.expression.as_deref(),
        );

        if let Some(liquid_expr) = liquid_expr
            && let Some(boolean_array) = self
                .cache_store
                .eval_predicate(&entry_id, &liquid_expr)
                .with_selection(filter)
                .await
        {
            let predicate_filter = match boolean_array.null_count() {
                0 => boolean_array,
                _ => prep_null_mask_filter(&boolean_array),
            };
            return Some(Ok(predicate_filter));
        }

        let array = self.get_arrow_array_with_filter(batch_id, filter).await?;
        let record_batch = self.array_to_record_batch(array);
        let boolean_array = match predicate.evaluate(record_batch) {
            Ok(arr) => arr,
            Err(err) => return Some(Err(err)),
        };
        let predicate_filter = match boolean_array.null_count() {
            0 => boolean_array,
            _ => prep_null_mask_filter(&boolean_array),
        };
        Some(Ok(predicate_filter))
    }

    fn liquid_expr_for(
        &self,
        expr: Arc<dyn datafusion::physical_plan::PhysicalExpr>,
    ) -> Option<LiquidExpr> {
        LiquidExpr::try_new(expr, self.field.data_type(), self.expression.as_deref())
    }

    pub(crate) fn liquid_expr_for_predicate(
        &self,
        expr: Arc<dyn datafusion::physical_plan::PhysicalExpr>,
    ) -> Option<LiquidExpr> {
        self.liquid_expr_for(expr)
    }

    /// Get an arrow array with a filter applied.
    /// Returns None for non-predicate columns or string predicate columns
    /// (only numeric predicate columns are cached and served from cache).
    pub async fn get_arrow_array_with_filter(
        &self,
        batch_id: BatchID,
        filter: &BooleanBuffer,
    ) -> Option<ArrayRef> {
        if !self.is_predicate_column || is_string_type(self.field.data_type()) {
            return None;
        }
        let entry_id = self.entry_id(batch_id).into();
        let result = self
            .cache_store
            .get(&entry_id)
            .with_selection(filter)
            .with_optional_expression_hint(self.expression())
            .read()
            .await;
        if result.is_some() {
            self.cache_store.observer().runtime_stats().incr_cache_hit();
        } else {
            self.cache_store.observer().runtime_stats().incr_cache_miss();
        }
        result
    }

    #[cfg(test)]
    pub(crate) async fn get_arrow_array_test_only(&self, batch_id: BatchID) -> Option<ArrayRef> {
        let entry_id = self.entry_id(batch_id).into();
        self.cache_store.get(&entry_id).await
    }

    /// Insert an array into the cache.
    /// Only numeric predicate columns are cached; string predicates and
    /// non-predicate columns return CacheFull.
    pub async fn insert(
        self: &Arc<Self>,
        batch_id: BatchID,
        array: ArrayRef,
    ) -> Result<(), InsertArrowArrayError> {
        if !self.is_predicate_column || is_string_type(self.field.data_type()) {
            return Err(InsertArrowArrayError::CacheFull);
        }

        if self.is_cached(batch_id) {
            return Err(InsertArrowArrayError::AlreadyCached);
        }

        self.cache_store
            .insert(self.entry_id(batch_id).into(), array)
            .await?;
        Ok(())
    }

    // ── Page grid ─────────────────────────────────────────────────────────
    //
    // Page-grid entries are whole Parquet column pages keyed by their
    // OffsetIndex ordinal (see [`PageID`]). Unlike the batch-grid methods
    // above, these are not restricted to predicate columns or non-string
    // types: the doc-values path caches any column it reads, and the liquid
    // transcoder handles strings natively.

    /// Whether the whole page is resident in the cache.
    pub fn is_page_cached(&self, page_id: PageID) -> bool {
        self.cache_store
            .is_cached(&self.column_path.entry_id(page_id.slot()).into())
    }

    /// Entry id of a page-grid entry (for backfill deduplication).
    pub fn page_entry_id(&self, page_id: PageID) -> ParquetArrayID {
        self.column_path.entry_id(page_id.slot())
    }

    /// Reads one whole cached Parquet data page.
    pub async fn get_page(&self, page_id: PageID) -> Option<ArrayRef> {
        let entry_id = self.column_path.entry_id(page_id.slot()).into();
        let result = self.cache_store.get(&entry_id).read().await;
        self.record_page_read(result.is_some());
        result
    }

    /// Reads `[offset, offset + len)` from one cached Parquet data page,
    /// decoding only the requested rows when the entry is liquid-transcoded.
    ///
    /// `page_rows` must be the page's full row count — the length of the array
    /// inserted through [`Self::insert_page`], which only ever stores whole
    /// pages. Sparse readers depend on this: materializing a 32-row window
    /// must not pay for an 8K-row page.
    pub async fn get_page_rows(
        &self,
        page_id: PageID,
        offset: usize,
        len: usize,
        page_rows: usize,
    ) -> Option<ArrayRef> {
        debug_assert!(offset + len <= page_rows);
        let entry_id = self.column_path.entry_id(page_id.slot()).into();
        let result = if offset == 0 && len == page_rows {
            // Whole-page read: skip the selection so MemoryArrow entries
            // return a zero-copy clone.
            self.cache_store.get(&entry_id).read().await
        } else {
            let mut selection = BooleanBufferBuilder::new(page_rows);
            selection.append_n(offset, false);
            selection.append_n(len, true);
            selection.append_n(page_rows - offset - len, false);
            let selection = selection.finish();
            self.cache_store
                .get(&entry_id)
                .with_selection(&selection)
                .read()
                .await
        };
        self.record_page_read(result.is_some());
        result
    }

    /// Synchronously serves `[offset, offset + len)` of a memory-resident
    /// page: Arrow entries return a zero-copy slice, liquid entries decode
    /// only the window. Returns `None` when the entry is absent or disk-backed
    /// — callers fall back to the async [`Self::get_page_rows`] path. This is
    /// the sparse-read hot path: no runtime entry, no allocation beyond the
    /// selection bitmap for liquid entries.
    pub fn read_page_window_sync(
        &self,
        page_id: PageID,
        offset: usize,
        len: usize,
        page_rows: usize,
    ) -> Option<ArrayRef> {
        debug_assert!(offset + len <= page_rows);
        let entry_id = self.column_path.entry_id(page_id.slot()).into();
        let entry = self.cache_store.try_read_memory(&entry_id)?;
        let result = match entry {
            MemoryEntry::Arrow(array) => {
                if array.len() != page_rows {
                    return None;
                }
                if offset == 0 && len == page_rows {
                    array
                } else {
                    array.slice(offset, len)
                }
            }
            MemoryEntry::Liquid(array) => {
                if array.len() != page_rows {
                    return None;
                }
                let mut selection = BooleanBufferBuilder::new(page_rows);
                selection.append_n(offset, false);
                selection.append_n(len, true);
                selection.append_n(page_rows - offset - len, false);
                array.filter(&selection.finish())
            }
        };
        self.record_page_read(true);
        Some(result)
    }

    fn record_page_read(&self, hit: bool) {
        if hit {
            self.cache_store.observer().runtime_stats().incr_cache_hit();
        } else {
            self.cache_store
                .observer()
                .runtime_stats()
                .incr_cache_miss();
        }
    }

    /// Inserts one whole decoded Parquet data page.
    pub async fn insert_page(
        self: &Arc<Self>,
        page_id: PageID,
        array: ArrayRef,
    ) -> Result<(), InsertArrowArrayError> {
        if self.is_page_cached(page_id) {
            return Err(InsertArrowArrayError::AlreadyCached);
        }
        self.cache_store
            .insert(self.column_path.entry_id(page_id.slot()).into(), array)
            .await?;
        Ok(())
    }
}

fn is_string_type(data_type: &DataType) -> bool {
    match data_type {
        DataType::Utf8 | DataType::Utf8View | DataType::LargeUtf8 => true,
        DataType::Binary | DataType::BinaryView | DataType::LargeBinary => true,
        DataType::Dictionary(_, value_type) => is_string_type(value_type.as_ref()),
        _ => false,
    }
}
