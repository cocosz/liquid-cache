use std::ops::Deref;
use std::sync::Arc;

use arrow::array::{ArrayRef, BooleanBufferBuilder, RecordBatch};
use arrow_schema::{DataType, Schema, SchemaRef};
use datafusion::datasource::physical_plan::parquet::{
    ParquetForwardBatchReader, ParquetForwardBatchReaderFactory,
};
use parquet::errors::{ParquetError, Result as ParquetResult};
use tokio::runtime::Runtime;

use crate::cache::{BatchID, CachedColumnRef, LiquidCacheParquetRef};

/// Liquid Cache configuration for a forward-only Parquet reader.
pub struct LiquidForwardReaderConfig {
    /// Cache instance to probe and populate, or `None` to use Parquet directly.
    pub cache: Option<LiquidCacheParquetRef>,
    /// Stable file identity used by Liquid Cache.
    pub file_path: String,
    /// Full Arrow file schema used to identify the cached column.
    pub file_schema: SchemaRef,
    /// Root Arrow column index corresponding to the projected Parquet leaf.
    pub root_column_id: usize,
    /// Runtime used for cache reads and asynchronous backfill.
    pub runtime: Arc<Runtime>,
}

struct CacheRowGroup {
    start: usize,
    row_count: usize,
    column: CachedColumnRef,
}

impl CacheRowGroup {
    fn end(&self) -> usize {
        self.start + self.row_count
    }
}

/// A forward-only reader that probes Liquid Cache before delegating misses to
/// one retained DataFusion/Arrow Parquet reader.
pub struct LiquidForwardBatchReader {
    parquet: ParquetForwardBatchReader,
    factory: Arc<ParquetForwardBatchReaderFactory>,
    cache: Option<LiquidCacheParquetRef>,
    cache_row_groups: Vec<CacheRowGroup>,
    cache_batch_size: usize,
    runtime: Arc<Runtime>,
    position: usize,
}

impl LiquidForwardBatchReader {
    /// Opens the foreground Parquet reader and prepares optional Liquid Cache
    /// column handles.
    pub fn try_new(
        factory: Arc<ParquetForwardBatchReaderFactory>,
        config: LiquidForwardReaderConfig,
    ) -> ParquetResult<Self> {
        let parquet = factory.open()?;
        let mut cache_row_groups = Vec::new();
        let cache = config.cache;
        let cache_batch_size = cache.as_ref().map_or(1, |cache| cache.batch_size());

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
        let cacheable =
            cache.is_some() && !parquet.is_repeated() && is_cacheable_type(field.data_type());

        if cacheable {
            let cache = cache.as_ref().expect("cache checked above");
            let file = cache.register_or_get_file(config.file_path, config.file_schema);
            let mut start = 0usize;
            for (index, row_group) in parquet.metadata().row_groups().iter().enumerate() {
                let row_count = usize::try_from(row_group.num_rows()).map_err(|_| {
                    ParquetError::General(format!("negative row count for row group {index}"))
                })?;
                let column = file
                    .create_column(index as u64, config.root_column_id as u64, true)
                    .ok_or_else(|| {
                        ParquetError::General(format!(
                            "column {} is outside the Liquid Cache file schema",
                            config.root_column_id
                        ))
                    })?;
                cache_row_groups.push(CacheRowGroup {
                    start,
                    row_count,
                    column,
                });
                start += row_count;
            }
        }

        Ok(Self {
            parquet,
            factory,
            cache,
            cache_row_groups,
            cache_batch_size,
            runtime: config.runtime,
            position: 0,
        })
    }

    /// Returns a cached slice when present; otherwise decodes through the
    /// retained Parquet reader. Dense misses trigger deduplicated background
    /// backfill of the containing aligned Liquid Cache batch.
    pub fn read_batch_at(
        &mut self,
        target_row: usize,
        max_rows: usize,
    ) -> ParquetResult<Option<RecordBatch>> {
        self.validate_read(target_row, max_rows)?;
        if target_row == self.row_count() {
            return Ok(None);
        }

        if let Some(batch) = self.read_cached(target_row, max_rows)? {
            self.position = target_row + batch.num_rows();
            return Ok(Some(batch));
        }

        let batch = self.parquet.read_batch_at(target_row, max_rows)?;
        self.position = self.parquet.position();
        if batch.is_some() && max_rows >= (self.cache_batch_size / 8).max(1) {
            self.schedule_backfill(target_row);
        }
        Ok(batch)
    }

    /// Current logical position, including batches served by Liquid Cache.
    pub fn position(&self) -> usize {
        self.position
    }

    fn validate_read(&self, target_row: usize, max_rows: usize) -> ParquetResult<()> {
        if target_row > self.row_count() {
            return Err(ParquetError::General(format!(
                "row {target_row} is beyond Parquet row count {}",
                self.row_count()
            )));
        }
        if target_row < self.position {
            return Err(ParquetError::General(format!(
                "backward seek from {} to {target_row} is not supported",
                self.position
            )));
        }
        if target_row < self.row_count() && max_rows == 0 {
            return Err(ParquetError::General(
                "forward batch size must be greater than zero".to_string(),
            ));
        }
        Ok(())
    }

    fn read_cached(
        &self,
        target_row: usize,
        max_rows: usize,
    ) -> ParquetResult<Option<RecordBatch>> {
        let Some(row_group) = self.cache_row_group(target_row) else {
            return Ok(None);
        };
        let local_row = target_row - row_group.start;
        let batch_start = local_row / self.cache_batch_size * self.cache_batch_size;
        let batch_len = self.cache_batch_size.min(row_group.row_count - batch_start);
        let offset = local_row - batch_start;
        let rows = max_rows.min(batch_len - offset);
        let batch_id = BatchID::from_row_id(batch_start, self.cache_batch_size);

        let mut selection = BooleanBufferBuilder::new(batch_len);
        selection.append_n(offset, false);
        selection.append_n(rows, true);
        selection.append_n(batch_len - offset - rows, false);
        let selection = selection.finish();
        let Some(array) = self.runtime.block_on(
            row_group
                .column
                .get_arrow_array_with_filter(batch_id, &selection),
        ) else {
            return Ok(None);
        };
        let schema = Arc::new(Schema::new(vec![row_group.column.field()]));
        Ok(Some(RecordBatch::try_new(schema, vec![array])?))
    }

    fn schedule_backfill(&self, target_row: usize) {
        let Some(cache) = self.cache.as_ref() else {
            return;
        };
        let Some(row_group) = self.cache_row_group(target_row) else {
            return;
        };
        let local_row = target_row - row_group.start;
        let batch_start = local_row / self.cache_batch_size * self.cache_batch_size;
        let global_start = row_group.start + batch_start;
        let row_count = self.cache_batch_size.min(row_group.row_count - batch_start);
        let batch_id = BatchID::from_row_id(batch_start, self.cache_batch_size);
        let entry_id = row_group.column.entry_id(batch_id);
        if !cache.try_start_backfill(entry_id) {
            return;
        }
        let column = Arc::clone(&row_group.column);
        let factory = Arc::clone(&self.factory);
        let cache = Arc::clone(cache);

        self.runtime.spawn(async move {
            let decoded = tokio::task::spawn_blocking(move || {
                let mut reader = factory.open()?;
                reader.read_range_at(global_start, row_count)
            })
            .await;

            match decoded {
                Ok(Ok(Some(batch))) if batch.num_rows() == row_count => {
                    let array: ArrayRef = Arc::clone(batch.column(0));
                    let _ = column.insert(batch_id, array).await;
                }
                Ok(Ok(Some(batch))) => log::warn!(
                    "Liquid forward backfill at row {global_start} returned {} of {row_count} rows",
                    batch.num_rows()
                ),
                Ok(Ok(None)) => {
                    log::warn!("Liquid forward backfill ended before row {global_start}")
                }
                Ok(Err(error)) => {
                    log::warn!("Liquid forward backfill failed at row {global_start}: {error}")
                }
                Err(error) => {
                    log::warn!("Liquid forward backfill task failed at row {global_start}: {error}")
                }
            }
            cache.finish_backfill(entry_id);
        });
    }

    fn cache_row_group(&self, target_row: usize) -> Option<&CacheRowGroup> {
        let index = self
            .cache_row_groups
            .partition_point(|row_group| row_group.end() <= target_row);
        self.cache_row_groups
            .get(index)
            .filter(|row_group| target_row >= row_group.start && target_row < row_group.end())
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
            DataType::Boolean | DataType::Date32 | DataType::Date64 | DataType::Timestamp(_, _)
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
            vec![Arc::new(Int32Array::from_iter_values(0..16))],
        )
        .unwrap();
        let properties = WriterProperties::builder()
            .set_data_page_row_count_limit(4)
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
            16,
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
            8,
            usize::MAX,
            usize::MAX,
            store,
            Box::new(LiquidPolicy::new()),
            Box::new(TranscodeSqueezeEvict),
            Box::new(AlwaysHydrate::new()),
        )))
    }

    #[test]
    fn delegates_to_parquet_when_cache_is_disabled() {
        let (runtime, schema, factory) = test_input();
        let mut reader = LiquidForwardBatchReader::try_new(
            factory,
            LiquidForwardReaderConfig {
                cache: None,
                file_path: "data.parquet".to_string(),
                file_schema: schema,
                root_column_id: 0,
                runtime,
            },
        )
        .unwrap();

        let batch = reader.read_batch_at(1, 2).unwrap().unwrap();
        assert_eq!(values(&batch), vec![1, 2]);
    }

    #[test]
    fn reads_selected_rows_from_liquid_cache() {
        let (runtime, schema, factory) = test_input();
        let cache = test_cache(&runtime);
        let file = cache.register_or_get_file("data.parquet".to_string(), Arc::clone(&schema));
        let column = file.create_column(0, 0, true).unwrap();
        runtime
            .block_on(column.insert(
                BatchID::from_row_id(0, 8),
                Arc::new(Int32Array::from_iter_values(0..8)),
            ))
            .unwrap();

        let mut reader = LiquidForwardBatchReader::try_new(
            factory,
            LiquidForwardReaderConfig {
                cache: Some(cache),
                file_path: "data.parquet".to_string(),
                file_schema: schema,
                root_column_id: 0,
                runtime,
            },
        )
        .unwrap();
        let batch = reader.read_batch_at(2, 2).unwrap().unwrap();
        assert_eq!(values(&batch), vec![2, 3]);
        assert_eq!(reader.position(), 4);
    }

    #[test]
    fn dense_miss_backfills_aligned_liquid_batch() {
        let (runtime, schema, factory) = test_input();
        let cache = test_cache(&runtime);
        let file = cache.register_or_get_file("data.parquet".to_string(), Arc::clone(&schema));
        let column = file.create_column(0, 0, true).unwrap();
        let batch_id = BatchID::from_row_id(0, 8);
        let mut reader = LiquidForwardBatchReader::try_new(
            factory,
            LiquidForwardReaderConfig {
                cache: Some(cache),
                file_path: "data.parquet".to_string(),
                file_schema: schema,
                root_column_id: 0,
                runtime: Arc::clone(&runtime),
            },
        )
        .unwrap();

        let foreground = reader.read_batch_at(0, 8).unwrap().unwrap();
        assert_eq!(values(&foreground), vec![0, 1, 2, 3, 4, 5, 6, 7]);

        let cached = (0..100).find_map(|_| {
            let array = runtime.block_on(column.get_arrow_array_test_only(batch_id));
            if array.is_none() {
                std::thread::sleep(std::time::Duration::from_millis(10));
            }
            array
        });
        let cached = cached.expect("background backfill did not populate Liquid Cache");
        assert_eq!(
            cached
                .as_any()
                .downcast_ref::<Int32Array>()
                .unwrap()
                .values(),
            &[0, 1, 2, 3, 4, 5, 6, 7]
        );
    }
}
