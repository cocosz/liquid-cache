use std::ops::Deref;
use std::sync::Arc;

use arrow::array::RecordBatch;
use arrow_schema::{DataType, Schema, SchemaRef};
use datafusion::datasource::physical_plan::parquet::{
    ParquetForwardBatchReader, ParquetForwardBatchReaderFactory, ParquetForwardPage,
};
use parquet::errors::{ParquetError, Result as ParquetResult};
use tokio::runtime::Runtime;

use crate::cache::{CachedColumnRef, LiquidCacheParquetRef, PageID, PageInsertJob, PageWindowProbe};

/// Liquid Cache configuration for a forward-only Parquet reader.
#[derive(Clone)]
pub struct LiquidForwardReaderConfig {
    /// Cache instance to probe and populate, or `None` to use Parquet directly.
    pub cache: Option<LiquidCacheParquetRef>,
    /// Stable file identity used by Liquid Cache.
    pub file_path: String,
    /// Full Arrow file schema used to identify the cached column.
    pub file_schema: SchemaRef,
    /// Root Arrow column index corresponding to the projected Parquet leaf.
    pub root_column_id: usize,
    /// Runtime used for asynchronous backfill and disk-backed cache reads.
    pub runtime: Arc<Runtime>,
    /// Upper bound on rows served per cache hit for fixed-width columns.
    /// A hit costs one probe regardless of width, so serving the page
    /// remainder (capped here by the caller's buffer capacity) lets sparse
    /// readers absorb later rows of the same page without another call.
    /// Zero restricts hits to the requested window.
    pub hit_serve_limit: usize,
}

/// A forward-only reader that probes Liquid Cache's page grid before
/// delegating misses to one retained DataFusion/Arrow Parquet reader.
///
/// The cache unit is the whole Parquet column page (see [`PageID`]) — the page
/// grid's granularity floor. A hit serves a zero-copy slice of the cached page
/// aligned to the same page-clamped window the Parquet path would return. A
/// miss decodes through the retained reader untouched; when the caller's
/// window is dense relative to the page, the whole page is decoded and
/// inserted in the background, deduplicated across readers.
pub struct LiquidForwardBatchReader {
    parquet: ParquetForwardBatchReader,
    factory: Arc<ParquetForwardBatchReaderFactory>,
    cache: Option<LiquidCacheParquetRef>,
    /// Per-row-group cached column handles; empty when the column is not cacheable.
    columns: Vec<CachedColumnRef>,
    /// Projected pages in row order (copied from the retained reader's OffsetIndex view).
    pages: Vec<ParquetForwardPage>,
    field: Arc<arrow_schema::Field>,
    /// Cached single-field schema, built once — hits must not allocate one per probe.
    hit_schema: SchemaRef,
    /// Rows a fixed-width hit may serve beyond the requested window (0 = window only).
    hit_serve_limit: usize,
    /// Queue for foreground-decoded page inserts; one lock-free send per page.
    insert_tx: Option<std::sync::mpsc::Sender<PageInsertJob>>,
    /// Locally buffered population jobs. Each channel send wakes a worker
    /// task, so per-page sends tax cold scans with thousands of wakeups;
    /// buffering makes the foreground cost a plain Vec push, flushed in bulk
    /// at reader drop (query end) or every [`Self::FLUSH_THRESHOLD`] pages.
    pending_jobs: Vec<PageInsertJob>,
    /// O(1) hint for [`Self::page_at`]: index of the last page served.
    page_hint: usize,
    runtime: Arc<Runtime>,
    position: usize,
}

/// A miss window at least this dense relative to its page promotes the whole
/// page into the cache. Doc-values callers grow their window on dense access
/// and shrink it on sparse access, so the window size is the density signal:
/// sparse probing never pollutes the cache, sustained scans promote quickly.
const PAGE_ADMISSION_FRACTION: usize = 8;

/// Whether a miss with `window` rows over a `page_rows`-row page is dense
/// enough to promote the whole page.
fn admits_page(window: usize, page_rows: usize) -> bool {
    window >= (page_rows / PAGE_ADMISSION_FRACTION).max(1)
}

impl LiquidForwardBatchReader {
    /// Opens the foreground Parquet reader and prepares optional Liquid Cache
    /// column handles.
    pub fn try_new(
        factory: Arc<ParquetForwardBatchReaderFactory>,
        config: LiquidForwardReaderConfig,
    ) -> ParquetResult<Self> {
        let parquet = factory.open()?;

        let field = config
            .file_schema
            .fields()
            .get(config.root_column_id)
            .cloned()
            .ok_or_else(|| {
                ParquetError::General(format!(
                    "root column {} is outside Arrow schema with {} fields",
                    config.root_column_id,
                    config.file_schema.fields().len()
                ))
            })?;
        let cacheable = config.cache.is_some()
            && !parquet.is_repeated()
            && is_cacheable_type(field.data_type());

        let (cache, columns, pages) = if cacheable {
            let cache = config.cache.expect("cache checked above");
            let file = cache.register_or_get_file(config.file_path, config.file_schema);
            let row_groups = parquet.metadata().num_row_groups();
            let columns = (0..row_groups)
                .map(|row_group| {
                    file.create_column(row_group as u64, config.root_column_id as u64, true)
                        .ok_or_else(|| {
                            ParquetError::General(format!(
                                "column {} is outside the Liquid Cache file schema",
                                config.root_column_id
                            ))
                        })
                })
                .collect::<ParquetResult<Vec<_>>>()?;
            let pages = parquet.pages().to_vec();
            (Some(cache), columns, pages)
        } else {
            (None, Vec::new(), Vec::new())
        };

        let hit_schema = Arc::new(Schema::new(vec![Arc::clone(&field)]));
        // Extended hit windows only for fixed-width columns: variable-width
        // pages can hold megabytes, so serving beyond the window would trade
        // one probe for a giant copy.
        let hit_serve_limit = if field.data_type().primitive_width().is_some() {
            config.hit_serve_limit
        } else {
            0
        };

        let insert_tx = cache
            .as_ref()
            .filter(|_| !columns.is_empty())
            .map(|cache| cache.page_insert_queue(&config.runtime));
        if let Some(cache) = cache.as_ref() {
            // Population workers yield while this reader is open (released in Drop).
            cache.reader_opened();
        }

        Ok(Self {
            parquet,
            factory,
            cache,
            columns,
            pages,
            field,
            hit_schema,
            hit_serve_limit,
            insert_tx,
            pending_jobs: Vec::new(),
            page_hint: 0,
            runtime: config.runtime,
            position: 0,
        })
    }

    /// Returns a page-grid slice when the containing page is cached; otherwise
    /// decodes through the retained Parquet reader. Dense misses trigger
    /// deduplicated background backfill of the whole containing page.
    pub fn read_batch_at(
        &mut self,
        target_row: usize,
        max_rows: usize,
    ) -> ParquetResult<Option<RecordBatch>> {
        self.validate_read(target_row, max_rows)?;
        if target_row == self.parquet.row_count() {
            return Ok(None);
        }

        let page = self.page_at(target_row);
        if let Some(page) = page.as_ref() {
            if let Some(batch) = self.read_cached_page(page, target_row, max_rows)? {
                self.position = target_row + batch.num_rows();
                return Ok(Some(batch));
            }
        }

        let batch = self.parquet.read_batch_at(target_row, max_rows)?;
        self.position = self.parquet.position();
        if let (Some(page), Some(_)) = (page, batch.as_ref()) {
            // Dense misses are admitted for population unconditionally; sparse
            // misses are second-chance candidates counted by the drainer.
            self.enqueue_page_insert(&page, admits_page(max_rows, page.row_count));
        }
        Ok(batch)
    }

    /// Current logical position, including batches served by Liquid Cache.
    pub fn position(&self) -> usize {
        self.position
    }

    /// Rewinds to row zero by rebuilding only the inner Parquet reader.
    ///
    /// Sharing a forward-only cursor between interleaved consumers (concurrent
    /// segment-search slices) makes backward seeks routine; a full reopen —
    /// object-store head, page-index load, cache re-registration, per-row-group
    /// column handles — showed up as the top native cost under profile. Reset
    /// retains everything except the decoder itself.
    pub fn reset(&mut self) -> ParquetResult<()> {
        self.flush_pending_jobs();
        self.parquet = self.factory.open()?;
        self.position = 0;
        self.page_hint = 0;
        Ok(())
    }

    fn validate_read(&self, target_row: usize, max_rows: usize) -> ParquetResult<()> {
        if target_row > self.parquet.row_count() {
            return Err(ParquetError::General(format!(
                "row {target_row} is beyond Parquet row count {}",
                self.parquet.row_count()
            )));
        }
        if target_row < self.position {
            return Err(ParquetError::General(format!(
                "backward seek from {} to {target_row} is not supported",
                self.position
            )));
        }
        if target_row < self.parquet.row_count() && max_rows == 0 {
            return Err(ParquetError::General(
                "forward batch size must be greater than zero".to_string(),
            ));
        }
        Ok(())
    }

    /// The cacheable page containing `target_row`, or `None` when the column
    /// is not cacheable or the page is all-null (served from metadata without
    /// I/O, so caching it would only waste budget). Forward readers visit
    /// pages in row order, so the previous index (or its successor) answers
    /// almost every probe in O(1); the binary search is a cold-start/jump
    /// fallback — at ~14 cache-cold accesses over thousands of pages it costs
    /// more than the cache-index lookup itself.
    fn page_at(&mut self, target_row: usize) -> Option<ParquetForwardPage> {
        if self.columns.is_empty() {
            return None;
        }
        let contains = |page: &ParquetForwardPage| {
            target_row >= page.first_row && target_row < page.first_row + page.row_count
        };
        let index = if self.pages.get(self.page_hint).is_some_and(contains) {
            self.page_hint
        } else if self.pages.get(self.page_hint + 1).is_some_and(contains) {
            self.page_hint + 1
        } else {
            self.pages
                .partition_point(|page| page.first_row + page.row_count <= target_row)
        };
        self.page_hint = index;
        self.pages
            .get(index)
            .filter(|page| target_row >= page.first_row && !page.all_null)
            .cloned()
    }

    /// Serves rows starting at `target_row` from a cached whole-page entry.
    ///
    /// Memory-resident entries are read synchronously (no runtime entry):
    /// Arrow pages return zero-copy slices, liquid pages decode only the
    /// window. Fixed-width hits serve up to `hit_serve_limit` rows — the page
    /// remainder when possible — so later rows of the same page are absorbed
    /// by the caller's resident batch without another probe. Disk-backed
    /// entries fall back to the async path with the requested window.
    fn read_cached_page(
        &self,
        page: &ParquetForwardPage,
        target_row: usize,
        max_rows: usize,
    ) -> ParquetResult<Option<RecordBatch>> {
        let column = &self.columns[page.row_group_index];
        let page_id = PageID::from_page_index(page.page_index);
        let offset = target_row - page.first_row;
        let remaining = page.row_count - offset;
        let rows = max_rows.max(self.hit_serve_limit).min(remaining);

        let array = match column.read_page_window_sync(page_id, offset, rows, page.row_count) {
            PageWindowProbe::Served(array) => array,
            // Pure miss: return after the single sync index probe.
            PageWindowProbe::Absent => return Ok(None),
            PageWindowProbe::DiskBacked => {
                // One async read with the plain window.
                let rows = max_rows.min(remaining);
                match self
                    .runtime
                    .block_on(column.get_page_rows(page_id, offset, rows, page.row_count))
                {
                    Some(array) => array,
                    None => return Ok(None),
                }
            }
        };
        Ok(Some(RecordBatch::try_new(
            Arc::clone(&self.hit_schema),
            vec![array],
        )?))
    }

    /// Queues the page for background population. The foreground cost is one
    /// lock-free channel send of page coordinates — no index probes, no locks,
    /// no array retention. Deduplication (including pages whose insert or
    /// transcode is already in flight), decode, insert, and transcode all
    /// happen in the queue's single drainer with a reused reader; see
    /// [`LiquidCacheParquet::page_insert_queue`].
    fn enqueue_page_insert(&mut self, page: &ParquetForwardPage, admitted: bool) {
        let Some(cache) = self.cache.as_ref() else {
            return;
        };
        if self.insert_tx.is_none() {
            return;
        }
        let column = &self.columns[page.row_group_index];
        let page_id = PageID::from_page_index(page.page_index);
        self.pending_jobs.push(PageInsertJob {
            cache: Arc::clone(cache),
            column: Arc::clone(column),
            factory: Arc::clone(&self.factory),
            page_id,
            entry_id: column.page_entry_id(page_id),
            first_row: page.first_row,
            row_count: page.row_count,
            queued_at: std::time::Instant::now(),
            admitted,
        });
        if self.pending_jobs.len() >= Self::FLUSH_THRESHOLD {
            self.flush_pending_jobs();
        }
    }

    /// Bulk-sends buffered population jobs; at most one worker wakeup per flush.
    fn flush_pending_jobs(&mut self) {
        let Some(insert_tx) = self.insert_tx.as_ref() else {
            return;
        };
        for job in self.pending_jobs.drain(..) {
            let _ = insert_tx.send(job);
        }
    }

    /// Effectively flush-on-drop: a query's touches are handed to the
    /// population workers only when its reader closes, so zero worker wakeups
    /// or queue traffic occur while the query runs. The threshold only bounds
    /// pathological single-reader lifetimes (~13MB of buffered jobs).
    const FLUSH_THRESHOLD: usize = 100_000;
}

impl Drop for LiquidForwardBatchReader {
    fn drop(&mut self) {
        self.flush_pending_jobs();
        if let Some(cache) = self.cache.as_ref() {
            cache.reader_closed();
        }
    }
}

impl Deref for LiquidForwardBatchReader {
    type Target = ParquetForwardBatchReader;

    fn deref(&self) -> &Self::Target {
        &self.parquet
    }
}

fn is_cacheable_type(data_type: &DataType) -> bool {
    data_type.is_numeric()
        || matches!(
            data_type,
            DataType::Boolean
                | DataType::Date32
                | DataType::Date64
                | DataType::Timestamp(_, _)
                | DataType::Utf8
                | DataType::LargeUtf8
                | DataType::Utf8View
                | DataType::Binary
                | DataType::LargeBinary
                | DataType::BinaryView
        )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::LiquidCacheParquet;
    use arrow::array::{Array, Int32Array};
    use arrow_schema::Field;
    use bytes::Bytes;
    use datafusion::datasource::listing::PartitionedFile;
    use datafusion::datasource::physical_plan::parquet::{
        DefaultParquetFileReaderFactory, ParquetFileReaderFactory,
    };
    use liquid_cache::cache::AlwaysHydrate;
    use liquid_cache::cache::squeeze_policies::TranscodeSqueezeEvict;
    use liquid_cache::cache_policies::LiquidPolicy;
    use object_store::ObjectStoreExt;
    use object_store::memory::InMemory;
    use object_store::path::Path;
    use parquet::arrow::ArrowWriter;
    use parquet::arrow::ProjectionMask;
    use parquet::file::metadata::{PageIndexPolicy, ParquetMetaDataReader};
    use parquet::file::properties::WriterProperties;

    const PAGE_ROWS: usize = 4;
    const TOTAL_ROWS: usize = 16;

    fn test_input() -> (
        Arc<Runtime>,
        SchemaRef,
        Arc<ParquetForwardBatchReaderFactory>,
    ) {
        let schema = Arc::new(Schema::new(vec![Field::new(
            "value",
            DataType::Int32,
            false,
        )]));
        let batch = RecordBatch::try_new(
            Arc::clone(&schema),
            vec![Arc::new(Int32Array::from_iter_values(0..TOTAL_ROWS as i32))],
        )
        .unwrap();
        let properties = WriterProperties::builder()
            .set_data_page_row_count_limit(PAGE_ROWS)
            .set_write_batch_size(PAGE_ROWS)
            .set_offset_index_disabled(false)
            .build();
        let mut data = Vec::new();
        let mut writer =
            ArrowWriter::try_new(&mut data, Arc::clone(&schema), Some(properties)).unwrap();
        writer.write(&batch).unwrap();
        writer.close().unwrap();
        let data = Bytes::from(data);
        let metadata = Arc::new(
            ParquetMetaDataReader::new()
                .with_page_index_policy(PageIndexPolicy::Required)
                .parse_and_finish(&data)
                .unwrap(),
        );
        let projection = ProjectionMask::leaves(metadata.file_metadata().schema_descr(), [0]);

        let runtime = Arc::new(Runtime::new().unwrap());
        let store = Arc::new(InMemory::new());
        runtime
            .block_on(store.put(&Path::from("data.parquet"), data.clone().into()))
            .unwrap();
        let reader_factory: Arc<dyn ParquetFileReaderFactory> =
            Arc::new(DefaultParquetFileReaderFactory::new(store));
        let factory = Arc::new(ParquetForwardBatchReaderFactory::new(
            reader_factory,
            PartitionedFile::new("data.parquet", data.len() as u64),
            metadata,
            projection,
            TOTAL_ROWS,
            Arc::clone(&runtime),
        ));
        (runtime, schema, factory)
    }

    fn values(batch: &RecordBatch) -> Vec<i32> {
        batch
            .column(0)
            .as_any()
            .downcast_ref::<Int32Array>()
            .unwrap()
            .values()
            .to_vec()
    }

    fn test_cache(runtime: &Runtime) -> Arc<LiquidCacheParquet> {
        let cache_dir = tempfile::tempdir().unwrap();
        let store = runtime
            .block_on(t4::mount_with_options(
                cache_dir.path().join("liquid-cache.t4"),
                t4::MountOptions {
                    direct_io: false,
                    dsync: false,
                    ..Default::default()
                },
            ))
            .unwrap();
        Arc::new(runtime.block_on(LiquidCacheParquet::new(
            8192,
            usize::MAX,
            usize::MAX,
            store,
            Box::new(LiquidPolicy::new()),
            Box::new(TranscodeSqueezeEvict),
            Box::new(AlwaysHydrate::new()),
        )))
    }

    fn liquid_reader(
        factory: Arc<ParquetForwardBatchReaderFactory>,
        schema: SchemaRef,
        cache: Option<Arc<LiquidCacheParquet>>,
        runtime: Arc<Runtime>,
    ) -> LiquidForwardBatchReader {
        liquid_reader_with_limit(factory, schema, cache, runtime, 0)
    }

    fn liquid_reader_with_limit(
        factory: Arc<ParquetForwardBatchReaderFactory>,
        schema: SchemaRef,
        cache: Option<Arc<LiquidCacheParquet>>,
        runtime: Arc<Runtime>,
        hit_serve_limit: usize,
    ) -> LiquidForwardBatchReader {
        LiquidForwardBatchReader::try_new(
            factory,
            LiquidForwardReaderConfig {
                cache,
                file_path: "data.parquet".to_string(),
                file_schema: schema,
                root_column_id: 0,
                runtime,
                hit_serve_limit,
            },
        )
        .unwrap()
    }

    #[test]
    fn delegates_to_parquet_when_cache_is_disabled() {
        let (runtime, schema, factory) = test_input();
        let mut reader = liquid_reader(factory, schema, None, runtime);

        let batch = reader.read_batch_at(1, 2).unwrap().unwrap();
        assert_eq!(values(&batch), vec![1, 2]);
    }

    #[test]
    fn serves_window_from_cached_whole_page() {
        let (runtime, schema, factory) = test_input();
        let cache = test_cache(&runtime);
        let file = cache.register_or_get_file("data.parquet".to_string(), Arc::clone(&schema));
        let column = file.create_column(0, 0, true).unwrap();
        // Page 1 covers rows [4, 8): insert the WHOLE page — the grid's only unit.
        runtime
            .block_on(column.insert_page(
                PageID::from_page_index(1),
                Arc::new(Int32Array::from_iter_values(4..8)),
            ))
            .unwrap();

        let mut reader = liquid_reader(factory, schema, Some(cache), runtime);
        let batch = reader.read_batch_at(5, 2).unwrap().unwrap();
        assert_eq!(values(&batch), vec![5, 6]);
        assert_eq!(reader.position(), 7);

        // The cached window is clamped at the page end, exactly like Parquet.
        let batch = reader.read_batch_at(7, 8).unwrap().unwrap();
        assert_eq!(values(&batch), vec![7]);
        assert_eq!(reader.position(), 8);
    }

    #[test]
    fn page_and_batch_keys_do_not_collide() {
        let (runtime, schema, _factory) = test_input();
        let cache = test_cache(&runtime);
        let file = cache.register_or_get_file("data.parquet".to_string(), Arc::clone(&schema));
        let column = file.create_column(0, 0, true).unwrap();

        // Batch-grid entry 0 (scan path) and page-grid entry 0 (doc-values
        // path) must live in disjoint key spaces.
        runtime
            .block_on(column.insert(
                crate::cache::BatchID::from_row_id(0, 8192),
                Arc::new(Int32Array::from_iter_values(0..TOTAL_ROWS as i32)),
            ))
            .unwrap();
        assert!(!column.is_page_cached(PageID::from_page_index(0)));

        runtime
            .block_on(column.insert_page(
                PageID::from_page_index(0),
                Arc::new(Int32Array::from_iter_values(0..PAGE_ROWS as i32)),
            ))
            .unwrap();
        let page = runtime
            .block_on(column.get_page(PageID::from_page_index(0)))
            .unwrap();
        assert_eq!(page.len(), PAGE_ROWS);
    }

    #[test]
    fn window_read_materializes_only_requested_rows() {
        let (runtime, schema, _factory) = test_input();
        let cache = test_cache(&runtime);
        let file = cache.register_or_get_file("data.parquet".to_string(), Arc::clone(&schema));
        let column = file.create_column(0, 0, true).unwrap();
        runtime
            .block_on(column.insert_page(
                PageID::from_page_index(0),
                Arc::new(Int32Array::from_iter_values(0..PAGE_ROWS as i32)),
            ))
            .unwrap();

        // Interior window: exactly the requested rows come back.
        let window = runtime
            .block_on(column.get_page_rows(PageID::from_page_index(0), 1, 2, PAGE_ROWS))
            .unwrap();
        assert_eq!(
            window
                .as_any()
                .downcast_ref::<Int32Array>()
                .unwrap()
                .values(),
            &[1, 2]
        );

        // Whole-page window uses the selection-free (zero-copy) path.
        let whole = runtime
            .block_on(column.get_page_rows(PageID::from_page_index(0), 0, PAGE_ROWS, PAGE_ROWS))
            .unwrap();
        assert_eq!(whole.len(), PAGE_ROWS);
    }

    #[test]
    fn fixed_width_hit_serves_page_remainder_up_to_limit() {
        let (runtime, schema, factory) = test_input();
        let cache = test_cache(&runtime);
        let file = cache.register_or_get_file("data.parquet".to_string(), Arc::clone(&schema));
        let column = file.create_column(0, 0, true).unwrap();
        runtime
            .block_on(column.insert_page(
                PageID::from_page_index(1),
                Arc::new(Int32Array::from_iter_values(4..8)),
            ))
            .unwrap();

        let mut reader =
            liquid_reader_with_limit(factory, schema, Some(cache), runtime, TOTAL_ROWS);
        // Window of 1 row, but the hit serves the page remainder [5, 8).
        let batch = reader.read_batch_at(5, 1).unwrap().unwrap();
        assert_eq!(values(&batch), vec![5, 6, 7]);
        assert_eq!(reader.position(), 8);
    }

    #[test]
    fn partial_page_read_backfills_via_background_decode() {
        let (runtime, schema, factory) = test_input();
        let cache = test_cache(&runtime);
        let file = cache.register_or_get_file("data.parquet".to_string(), Arc::clone(&schema));
        let column = file.create_column(0, 0, true).unwrap();
        let mut reader = liquid_reader(
            factory,
            schema,
            Some(Arc::clone(&cache)),
            Arc::clone(&runtime),
        );

        // Mid-page landing: foreground decodes rows [5, 8) of page 1 only, so
        // the whole page must come from the background reader.
        let foreground = reader.read_batch_at(5, PAGE_ROWS).unwrap().unwrap();
        assert_eq!(values(&foreground), vec![5, 6, 7]);
        drop(reader); // population yields while readers are open

        let page_id = PageID::from_page_index(1);
        let cached = (0..100).find_map(|_| {
            let array = runtime.block_on(column.get_page(page_id));
            if array.is_none() {
                std::thread::sleep(std::time::Duration::from_millis(10));
            }
            array
        });
        let cached = cached.expect("partial-page miss did not backfill the whole page");
        assert_eq!(
            cached
                .as_any()
                .downcast_ref::<Int32Array>()
                .unwrap()
                .values(),
            &[4, 5, 6, 7]
        );
    }

    #[test]
    fn in_flight_page_is_not_resubmitted() {
        let (runtime, schema, factory) = test_input();
        let cache = test_cache(&runtime);
        let file = cache.register_or_get_file("data.parquet".to_string(), Arc::clone(&schema));
        let column = file.create_column(0, 0, true).unwrap();
        let page_id = PageID::from_page_index(1);
        let entry_id = column.page_entry_id(page_id);

        // Simulate an in-flight transcode: the reservation is held.
        assert!(cache.try_start_backfill(entry_id));

        let mut full_reader = liquid_reader(
            Arc::clone(&factory),
            Arc::clone(&schema),
            Some(Arc::clone(&cache)),
            Arc::clone(&runtime),
        );
        let mut partial_reader = liquid_reader(
            factory,
            schema,
            Some(Arc::clone(&cache)),
            Arc::clone(&runtime),
        );
        // Both a whole-page read (direct-insert path) and a partial read
        // (decode path) must skip submission while the reservation is held.
        let full = full_reader.read_batch_at(4, PAGE_ROWS).unwrap().unwrap();
        assert_eq!(values(&full), vec![4, 5, 6, 7]);
        let partial = partial_reader.read_batch_at(5, 1).unwrap().unwrap();
        assert_eq!(values(&partial), vec![5]);

        std::thread::sleep(std::time::Duration::from_millis(100));
        assert!(
            runtime.block_on(column.get_page(page_id)).is_none(),
            "page was inserted despite an in-flight reservation"
        );
        // A second reservation attempt for the same page must also lose.
        assert!(!cache.try_start_backfill(entry_id));
        cache.finish_backfill(entry_id);
    }

    #[test]
    fn dense_miss_backfills_whole_page() {
        let (runtime, schema, factory) = test_input();
        let cache = test_cache(&runtime);
        let file = cache.register_or_get_file("data.parquet".to_string(), Arc::clone(&schema));
        let column = file.create_column(0, 0, true).unwrap();
        let mut reader = liquid_reader(
            factory,
            schema,
            Some(Arc::clone(&cache)),
            Arc::clone(&runtime),
        );

        // Dense window (full page) → foreground rows from Parquet, whole page
        // backfilled in the background.
        let foreground = reader.read_batch_at(4, PAGE_ROWS).unwrap().unwrap();
        assert_eq!(values(&foreground), vec![4, 5, 6, 7]);
        drop(reader); // population yields while readers are open

        let page_id = PageID::from_page_index(1);
        let cached = (0..100).find_map(|_| {
            let array = runtime.block_on(column.get_page(page_id));
            if array.is_none() {
                std::thread::sleep(std::time::Duration::from_millis(10));
            }
            array
        });
        let cached = cached.expect("background backfill did not populate the page grid");
        assert_eq!(
            cached
                .as_any()
                .downcast_ref::<Int32Array>()
                .unwrap()
                .values(),
            &[4, 5, 6, 7]
        );
    }

    #[test]
    fn sparse_windows_are_not_admitted_dense_windows_are() {
        // Doc-values cursors shrink their window on sparse access and grow it
        // on dense access, so the window is the admission signal.
        assert!(!admits_page(1, 8192), "sparse probe must not promote");
        assert!(!admits_page(1023, 8192), "just below the fraction");
        assert!(admits_page(1024, 8192), "at the fraction boundary");
        assert!(admits_page(8192, 8192), "full-page scans promote");
        assert!(admits_page(1, 4), "tiny pages floor the threshold at 1 row");
    }
}
