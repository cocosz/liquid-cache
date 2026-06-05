//! Optimizers for the Parquet module

mod lineage_opt;

use std::sync::Arc;

use arrow_schema::{Field, Schema, SchemaRef};
use datafusion::{
    catalog::memory::DataSourceExec,
    common::tree_node::{Transformed, TreeNode, TreeNodeRecursion},
    config::ConfigOptions,
    datasource::{
        physical_plan::{FileSource, ParquetSource},
        source::DataSource,
        table_schema::TableSchema,
    },
    physical_expr_adapter::PhysicalExprAdapterFactory,
    physical_optimizer::PhysicalOptimizerRule,
    physical_plan::ExecutionPlan,
};
pub use lineage_opt::LineageOptimizer;

use arrow_schema::DataType;

use crate::{
    LiquidCacheParquetRef, LiquidParquetSource,
    optimizers::lineage_opt::{ColumnAnnotation, metadata_from_factory, serialize_date_part},
};

pub(crate) const DATE_MAPPING_METADATA_KEY: &str = "liquid.cache.date_mapping";
pub(crate) const STRING_FINGERPRINT_METADATA_KEY: &str = "liquid.cache.string_fingerprint";

/// Physical optimizer rule for local mode liquid cache
///
/// This optimizer rewrites DataSourceExec nodes that read Parquet files
/// to use LiquidParquetSource instead of the default ParquetSource
#[derive(Debug)]
pub struct LocalModeOptimizer {
    cache: LiquidCacheParquetRef,
}

impl LocalModeOptimizer {
    /// Create an optimizer with an existing cache instance
    pub fn new(cache: LiquidCacheParquetRef) -> Self {
        Self { cache }
    }

    /// Create an optimizer with an existing cache instance
    pub fn with_cache(cache: LiquidCacheParquetRef) -> Self {
        Self { cache }
    }
}

impl PhysicalOptimizerRule for LocalModeOptimizer {
    fn optimize(
        &self,
        plan: Arc<dyn ExecutionPlan>,
        _config: &ConfigOptions,
    ) -> Result<Arc<dyn ExecutionPlan>, datafusion::error::DataFusionError> {
        Ok(rewrite_data_source_plan(plan, &self.cache))
    }

    fn name(&self) -> &str {
        "LocalModeLiquidCacheOptimizer"
    }

    fn schema_check(&self) -> bool {
        // We deliberately enrich scan schemas with metadata describing variant/date
        // extractions, so allow the optimizer to adjust schema metadata.
        false
    }
}

/// Rewrite the data source plan to use liquid cache.
pub fn rewrite_data_source_plan(
    plan: Arc<dyn ExecutionPlan>,
    cache: &LiquidCacheParquetRef,
) -> Arc<dyn ExecutionPlan> {
    let rewritten = plan
        .transform_up(|node| try_optimize_parquet_source(node, cache))
        .unwrap();
    rewritten.data
}

fn try_optimize_parquet_source(
    plan: Arc<dyn ExecutionPlan>,
    cache: &LiquidCacheParquetRef,
) -> Result<Transformed<Arc<dyn ExecutionPlan>>, datafusion::error::DataFusionError> {
    let any_plan = plan.as_any();
    if let Some(data_source_exec) = any_plan.downcast_ref::<DataSourceExec>()
        && let Some((file_scan_config, parquet_source)) =
            data_source_exec.downcast_to_file_source::<ParquetSource>()
    {
        // Skip LC rewrite if all projected columns are uncacheable (string/binary).
        // These columns are never stored in the cache, so going through the LC
        // reader machinery adds pure overhead with no benefit.
        let file_schema = file_scan_config.file_schema();
        let has_cacheable_column = file_schema
            .fields()
            .iter()
            .any(|field| !is_uncacheable_type(field.data_type()));
        if !has_cacheable_column {
            return Ok(Transformed::no(plan));
        }

        let mut new_config = file_scan_config.clone();

        let mut new_source =
            LiquidParquetSource::from_parquet_source(parquet_source.clone(), cache.clone());
        if let Some(expr_adapter_factory) = file_scan_config.expr_adapter_factory.as_ref() {
            let new_schema =
                enrich_source_schema(file_scan_config.file_schema(), expr_adapter_factory);
            let table_partition_cols = new_source.table_schema().table_partition_cols();
            let new_table_schema =
                TableSchema::new(Arc::new(new_schema), table_partition_cols.clone());
            new_source = new_source.with_table_schema(new_table_schema);
        }

        new_config.file_source = Arc::new(new_source);
        let new_file_source: Arc<dyn DataSource> = Arc::new(new_config);
        let new_plan = Arc::new(DataSourceExec::new(new_file_source));

        return Ok(Transformed::new(
            new_plan,
            true,
            TreeNodeRecursion::Continue,
        ));
    }
    Ok(Transformed::no(plan))
}

/// Returns true if the given data type is never cached by Liquid Cache.
/// String, binary, and dictionary-of-string/binary types are uncacheable.
pub fn is_uncacheable_type(dt: &DataType) -> bool {
    match dt {
        DataType::Utf8 | DataType::Utf8View | DataType::LargeUtf8 => true,
        DataType::Binary | DataType::BinaryView | DataType::LargeBinary => true,
        DataType::Dictionary(_, value_type) => is_uncacheable_type(value_type.as_ref()),
        _ => false,
    }
}

fn enrich_source_schema(
    file_schema: &SchemaRef,
    expr_adapter_factory: &Arc<dyn PhysicalExprAdapterFactory>,
) -> Schema {
    let mut new_fields = vec![];
    for field in file_schema.fields() {
        if let Some(annotation) = metadata_from_factory(expr_adapter_factory, field.name()) {
            new_fields.push(process_field_annotation(field, annotation));
        } else {
            new_fields.push(field.clone());
        }
    }
    Schema::new(new_fields)
}

fn process_field_annotation(field: &Arc<Field>, annotation: ColumnAnnotation) -> Arc<Field> {
    let mut field_metadata = field.metadata().clone();
    match annotation {
        ColumnAnnotation::DatePart(unit) => {
            field_metadata.insert(
                DATE_MAPPING_METADATA_KEY.to_string(),
                serialize_date_part(&unit),
            );
        }
        ColumnAnnotation::VariantPaths(_) => {}
        ColumnAnnotation::SubstringSearch => {
            field_metadata.insert(
                STRING_FINGERPRINT_METADATA_KEY.to_string(),
                "substring".into(),
            );
        }
    }
    Arc::new(Field::clone(field.as_ref()).with_metadata(field_metadata))
}

#[cfg(test)]
mod tests {
    use datafusion::{datasource::physical_plan::FileScanConfig, prelude::SessionContext};
    use liquid_cache::{
        cache::{AlwaysHydrate, squeeze_policies::TranscodeSqueezeEvict},
        cache_policies::LiquidPolicy,
    };

    use crate::LiquidCacheParquet;

    use super::*;

    async fn create_test_cache() -> LiquidCacheParquetRef {
        let tmp_dir = tempfile::tempdir().unwrap();
        let store = t4::mount(tmp_dir.path().join("liquid_cache.t4"))
            .await
            .unwrap();
        Arc::new(
            LiquidCacheParquet::new(
                8192,
                1000000,
                usize::MAX,
                store,
                Box::new(LiquidPolicy::new()),
                Box::new(TranscodeSqueezeEvict),
                Box::new(AlwaysHydrate::new()),
            )
            .await,
        )
    }

    async fn rewrite_plan_inner(plan: Arc<dyn ExecutionPlan>) {
        let expected_schema = plan.schema();
        let liquid_cache = create_test_cache().await;
        let rewritten = rewrite_data_source_plan(plan, &liquid_cache);

        rewritten
            .apply(|node| {
                if let Some(plan) = node.as_any().downcast_ref::<DataSourceExec>() {
                    let data_source = plan.data_source();
                    let any_source = data_source.as_any();
                    let source = any_source.downcast_ref::<FileScanConfig>().unwrap();
                    let file_source = source.file_source();
                    let any_file_source = file_source.as_any();
                    let _parquet_source = any_file_source
                        .downcast_ref::<LiquidParquetSource>()
                        .unwrap();
                    let schema = source.file_schema().as_ref();
                    assert_eq!(schema, expected_schema.as_ref());
                }
                Ok(TreeNodeRecursion::Continue)
            })
            .unwrap();
    }

    #[tokio::test]
    async fn test_plan_rewrite() {
        let ctx = SessionContext::new();
        ctx.register_parquet(
            "nano_hits",
            "../../examples/nano_hits.parquet",
            Default::default(),
        )
        .await
        .unwrap();
        let df = ctx
            .sql("SELECT * FROM nano_hits WHERE \"URL\" like 'https://%' limit 10")
            .await
            .unwrap();
        let plan = df.create_physical_plan().await.unwrap();
        rewrite_plan_inner(plan.clone()).await;
    }

    #[test]
    fn test_is_uncacheable_type() {
        use arrow_schema::DataType;

        // String/binary types are uncacheable
        assert!(is_uncacheable_type(&DataType::Utf8));
        assert!(is_uncacheable_type(&DataType::Utf8View));
        assert!(is_uncacheable_type(&DataType::LargeUtf8));
        assert!(is_uncacheable_type(&DataType::Binary));
        assert!(is_uncacheable_type(&DataType::BinaryView));
        assert!(is_uncacheable_type(&DataType::LargeBinary));

        // Dictionary wrapping string is uncacheable
        assert!(is_uncacheable_type(&DataType::Dictionary(
            Box::new(DataType::Int32),
            Box::new(DataType::Utf8),
        )));

        // Numeric types are cacheable (not uncacheable)
        assert!(!is_uncacheable_type(&DataType::Int8));
        assert!(!is_uncacheable_type(&DataType::Int16));
        assert!(!is_uncacheable_type(&DataType::Int32));
        assert!(!is_uncacheable_type(&DataType::Int64));
        assert!(!is_uncacheable_type(&DataType::UInt32));
        assert!(!is_uncacheable_type(&DataType::Float32));
        assert!(!is_uncacheable_type(&DataType::Float64));
        assert!(!is_uncacheable_type(&DataType::Date32));
        assert!(!is_uncacheable_type(&DataType::Boolean));

        // Dictionary wrapping numeric is cacheable
        assert!(!is_uncacheable_type(&DataType::Dictionary(
            Box::new(DataType::Int32),
            Box::new(DataType::Int64),
        )));
    }

    /// When ALL projected columns are uncacheable (string-only), the optimizer
    /// should NOT rewrite ParquetSource to LiquidParquetSource.
    #[tokio::test]
    async fn test_skip_rewrite_all_string_projection() {
        let ctx = SessionContext::new();
        ctx.register_parquet(
            "nano_hits",
            "../../examples/nano_hits.parquet",
            Default::default(),
        )
        .await
        .unwrap();
        // Select only string columns — URL and Title are Utf8
        let df = ctx
            .sql("SELECT \"URL\", \"Title\" FROM nano_hits LIMIT 10")
            .await
            .unwrap();
        let plan = df.create_physical_plan().await.unwrap();

        let liquid_cache = create_test_cache().await;
        let rewritten = rewrite_data_source_plan(plan, &liquid_cache);

        // The rewritten plan should still use ParquetSource, NOT LiquidParquetSource
        let mut found_parquet_source = false;
        rewritten
            .apply(|node| {
                if let Some(data_source_exec) = node.as_any().downcast_ref::<DataSourceExec>() {
                    let data_source = data_source_exec.data_source();
                    let any_source = data_source.as_any();
                    let source = any_source.downcast_ref::<FileScanConfig>().unwrap();
                    let file_source = source.file_source();
                    // Should be ParquetSource, not LiquidParquetSource
                    assert!(
                        file_source.as_any().downcast_ref::<ParquetSource>().is_some(),
                        "Expected ParquetSource for all-string projection, got LiquidParquetSource"
                    );
                    found_parquet_source = true;
                }
                Ok(TreeNodeRecursion::Continue)
            })
            .unwrap();
        assert!(found_parquet_source, "Should have found a DataSourceExec node");
    }

    /// When at least one projected column is cacheable (numeric), the optimizer
    /// SHOULD rewrite to LiquidParquetSource.
    #[tokio::test]
    async fn test_rewrite_applied_with_numeric_column() {
        let ctx = SessionContext::new();
        ctx.register_parquet(
            "nano_hits",
            "../../examples/nano_hits.parquet",
            Default::default(),
        )
        .await
        .unwrap();
        // WatchID is Int64 (cacheable) + URL is Utf8 (uncacheable)
        let df = ctx
            .sql("SELECT \"WatchID\", \"URL\" FROM nano_hits LIMIT 10")
            .await
            .unwrap();
        let plan = df.create_physical_plan().await.unwrap();

        let liquid_cache = create_test_cache().await;
        let rewritten = rewrite_data_source_plan(plan, &liquid_cache);

        // Should have been rewritten to LiquidParquetSource
        let mut found_liquid_source = false;
        rewritten
            .apply(|node| {
                if let Some(data_source_exec) = node.as_any().downcast_ref::<DataSourceExec>() {
                    let data_source = data_source_exec.data_source();
                    let any_source = data_source.as_any();
                    let source = any_source.downcast_ref::<FileScanConfig>().unwrap();
                    let file_source = source.file_source();
                    assert!(
                        file_source.as_any().downcast_ref::<LiquidParquetSource>().is_some(),
                        "Expected LiquidParquetSource for mixed projection"
                    );
                    found_liquid_source = true;
                }
                Ok(TreeNodeRecursion::Continue)
            })
            .unwrap();
        assert!(found_liquid_source, "Should have found a DataSourceExec node");
    }
}
