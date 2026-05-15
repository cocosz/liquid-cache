#[cfg(test)]
use crate::cache::cached_batch::CacheEntry;
use crate::sync::{Arc, RwLock};
use arrow::array::ArrayRef;
use arrow_schema::ArrowError;
use bytes::Bytes;

#[derive(Debug)]
pub struct CacheConfig {
    batch_size: usize,
    max_memory_bytes: usize,
    max_disk_bytes: usize,
}

impl CacheConfig {
    pub(super) fn new(batch_size: usize, max_memory_bytes: usize, max_disk_bytes: usize) -> Self {
        Self {
            batch_size,
            max_memory_bytes,
            max_disk_bytes,
        }
    }

    pub fn batch_size(&self) -> usize {
        self.batch_size
    }

    pub fn max_memory_bytes(&self) -> usize {
        self.max_memory_bytes
    }

    pub fn max_disk_bytes(&self) -> usize {
        self.max_disk_bytes
    }
}

// Helper methods
#[cfg(test)]
pub(crate) fn create_test_array(size: usize) -> CacheEntry {
    use arrow::array::Int64Array;
    use std::sync::Arc;

    CacheEntry::memory_arrow(Arc::new(Int64Array::from_iter_values(0..size as i64)))
}

// Helper methods
#[cfg(test)]
pub(crate) fn create_test_arrow_array(size: usize) -> ArrayRef {
    use arrow::array::Int64Array;
    Arc::new(Int64Array::from_iter_values(0..size as i64))
}

#[cfg(test)]
pub(crate) async fn create_cache_store(
    max_memory_bytes: usize,
    policy: Box<dyn super::policies::CachePolicy>,
) -> Arc<super::core::LiquidCache> {
    use crate::cache::{AlwaysHydrate, LiquidCacheBuilder, TranscodeSqueezeEvict};

    let batch_size = 128;

    let builder = LiquidCacheBuilder::new()
        .with_batch_size(batch_size)
        .with_max_memory_bytes(max_memory_bytes)
        .with_squeeze_policy(Box::new(TranscodeSqueezeEvict))
        .with_hydration_policy(Box::new(AlwaysHydrate::new()))
        .with_cache_policy(policy);
    builder.build().await
}

/// EntryID is a unique identifier for a batch of rows, i.e., the cache key.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Ord, PartialOrd, serde::Serialize)]
pub struct EntryID {
    val: usize,
}

impl From<usize> for EntryID {
    fn from(val: usize) -> Self {
        Self { val }
    }
}

impl From<EntryID> for usize {
    fn from(val: EntryID) -> Self {
        val.val
    }
}

/// Groups all batches of a column in a row group for coalesced disk IO.
///
/// When entries spill to disk, instead of writing each batch individually,
/// all batches sharing the same (file, row_group, column) are written as a
/// single contiguous entry. This reduces random IO from O(batches) to O(columns).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Ord, PartialOrd)]
pub struct DiskGroupID {
    /// Encoded as: file_id(16) | rg_id(16) | col_id(16) — same top-48-bit layout as EntryID.
    val: u64,
}

impl DiskGroupID {
    /// Create a new DiskGroupID from component IDs.
    pub fn new(file_id: u16, row_group_id: u16, column_id: u16) -> Self {
        let val = (file_id as u64) << 32 | (row_group_id as u64) << 16 | (column_id as u64);
        Self { val }
    }

    /// Extract this group from an EntryID by stripping the batch_id (lowest 16 bits).
    pub fn from_entry_id(entry_id: EntryID) -> Self {
        let v: usize = entry_id.into();
        let file_id = (v >> 48) as u16;
        let rg_id = ((v >> 32) & 0xFFFF) as u16;
        let col_id = ((v >> 16) & 0xFFFF) as u16;
        Self::new(file_id, rg_id, col_id)
    }

    /// Get the file id.
    pub fn file_id(&self) -> u16 {
        (self.val >> 32) as u16
    }

    /// Get the row group id.
    pub fn row_group_id(&self) -> u16 {
        ((self.val >> 16) & 0xFFFF) as u16
    }

    /// Get the column id.
    pub fn column_id(&self) -> u16 {
        (self.val & 0xFFFF) as u16
    }

    /// Convert to a u64 suitable for use as a disk store key.
    pub fn to_disk_key(&self) -> u64 {
        self.val
    }
}

impl From<u64> for DiskGroupID {
    fn from(val: u64) -> Self {
        Self { val }
    }
}

impl From<DiskGroupID> for u64 {
    fn from(val: DiskGroupID) -> Self {
        val.val
    }
}

/// States for liquid compressor.
pub struct LiquidCompressorStates {
    fsst_compressor: RwLock<Option<Arc<fsst::Compressor>>>,
}

impl std::fmt::Debug for LiquidCompressorStates {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "EtcCompressorStates")
    }
}

impl Default for LiquidCompressorStates {
    fn default() -> Self {
        Self::new()
    }
}

impl LiquidCompressorStates {
    /// Create a new instance of LiquidCompressorStates.
    pub fn new() -> Self {
        Self {
            fsst_compressor: RwLock::new(None),
        }
    }

    /// Create a new instance of LiquidCompressorStates with an fsst compressor.
    pub fn new_with_fsst_compressor(fsst_compressor: Arc<fsst::Compressor>) -> Self {
        Self {
            fsst_compressor: RwLock::new(Some(fsst_compressor)),
        }
    }

    /// Get the fsst compressor.
    pub fn fsst_compressor(&self) -> Option<Arc<fsst::Compressor>> {
        self.fsst_compressor.read().unwrap().clone()
    }

    /// Get the fsst compressor .
    pub fn fsst_compressor_raw(&self) -> &RwLock<Option<Arc<fsst::Compressor>>> {
        &self.fsst_compressor
    }
}

pub(crate) fn arrow_to_bytes(array: &ArrayRef) -> Result<Bytes, ArrowError> {
    use arrow::array::RecordBatch;
    use arrow::ipc::writer::StreamWriter;

    let mut bytes = Vec::new();

    // Create a record batch with the single array
    // We need to create a dummy field since we don't have the original field here
    let field =
        arrow_schema::Field::new("column", array.data_type().clone(), array.null_count() > 0);
    let schema = std::sync::Arc::new(arrow_schema::Schema::new(vec![field]));
    let batch = RecordBatch::try_new(schema.clone(), vec![array.clone()])?;

    let mut stream_writer = StreamWriter::try_new(&mut bytes, &schema)?;
    stream_writer.write(&batch)?;
    stream_writer.finish()?;

    Ok(Bytes::from(bytes))
}
