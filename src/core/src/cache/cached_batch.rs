//! Cached batch types.

use std::{fmt::Display, sync::Arc};

use arrow::array::ArrayRef;
use arrow_schema::DataType;

use crate::cache::utils::DiskGroupID;
use crate::liquid_array::{LiquidArrayRef, LiquidSqueezedArrayRef};

/// A cached entry storing data in various formats.
#[derive(Debug, Clone)]
pub enum CacheEntry {
    /// Cached batch in memory as Arrow array.
    MemoryArrow(ArrayRef),
    /// Cached batch in memory as liquid array.
    MemoryLiquid(LiquidArrayRef),
    /// Cached batch in memory as squeezed liquid array.
    MemorySqueezedLiquid(LiquidSqueezedArrayRef),
    /// Cached batch on disk as liquid array.
    DiskLiquid {
        /// Original Arrow data type.
        data_type: DataType,
        /// Byte length of the persisted backing data.
        disk_bytes: usize,
    },
    /// Cached batch on disk as Arrow array.
    DiskArrow {
        /// Original Arrow data type.
        data_type: DataType,
        /// Byte length of the persisted backing data.
        disk_bytes: usize,
    },
    /// Cached batch on disk as part of a coalesced column group.
    /// All batches sharing the same (file, row_group, column) are stored
    /// as a single contiguous disk entry, reducing random IO to one read per column.
    DiskCoalesced {
        /// Original Arrow data type.
        data_type: DataType,
        /// Which disk group this batch belongs to.
        disk_group: DiskGroupID,
        /// Index of this batch within the coalesced blob.
        batch_index: u16,
        /// Total number of batches in this coalesced group.
        total_batches: u16,
        /// Total byte size of the entire coalesced group on disk.
        group_disk_bytes: usize,
    },
}

impl CacheEntry {
    /// Construct a cached batch stored as an in-memory Arrow array.
    pub fn memory_arrow(array: ArrayRef) -> Self {
        Self::MemoryArrow(array)
    }

    /// Construct a cached batch stored as an in-memory Liquid array.
    pub fn memory_liquid(array: LiquidArrayRef) -> Self {
        Self::MemoryLiquid(array)
    }

    /// Construct a cached batch stored as an in-memory squeezed Liquid array.
    pub fn memory_squeezed_liquid(array: LiquidSqueezedArrayRef) -> Self {
        Self::MemorySqueezedLiquid(array)
    }

    /// Construct a cached batch stored on disk as Liquid bytes.
    pub fn disk_liquid(data_type: DataType, disk_bytes: usize) -> Self {
        Self::DiskLiquid {
            data_type,
            disk_bytes,
        }
    }

    /// Construct a cached batch stored on disk as Arrow bytes.
    pub fn disk_arrow(data_type: DataType, disk_bytes: usize) -> Self {
        Self::DiskArrow {
            data_type,
            disk_bytes,
        }
    }

    /// Construct a cached batch stored on disk as part of a coalesced column group.
    pub fn disk_coalesced(
        data_type: DataType,
        disk_group: DiskGroupID,
        batch_index: u16,
        total_batches: u16,
        group_disk_bytes: usize,
    ) -> Self {
        Self::DiskCoalesced {
            data_type,
            disk_group,
            batch_index,
            total_batches,
            group_disk_bytes,
        }
    }

    /// Memory usage reported by the underlying representation.
    pub fn memory_usage_bytes(&self) -> usize {
        match self {
            Self::MemoryArrow(array) => array.get_array_memory_size(),
            Self::MemoryLiquid(array) => array.get_array_memory_size(),
            Self::MemorySqueezedLiquid(array) => array.get_array_memory_size(),
            Self::DiskLiquid { .. } | Self::DiskArrow { .. } | Self::DiskCoalesced { .. } => 0,
        }
    }

    /// Reference count (if any) of the backing storage.
    pub fn reference_count(&self) -> usize {
        match self {
            Self::MemoryArrow(array) => Arc::strong_count(array),
            Self::MemoryLiquid(array) => Arc::strong_count(array),
            Self::MemorySqueezedLiquid(array) => Arc::strong_count(array),
            Self::DiskLiquid { .. } | Self::DiskArrow { .. } | Self::DiskCoalesced { .. } => 0,
        }
    }
}

impl Display for CacheEntry {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::MemoryArrow(_) => write!(f, "MemoryArrow"),
            Self::MemoryLiquid(_) => write!(f, "MemoryLiquid"),
            Self::MemorySqueezedLiquid(_) => write!(f, "MemorySqueezedLiquid"),
            Self::DiskLiquid { .. } => write!(f, "DiskLiquid"),
            Self::DiskArrow { .. } => write!(f, "DiskArrow"),
            Self::DiskCoalesced { .. } => write!(f, "DiskCoalesced"),
        }
    }
}

/// The type of the cached batch.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize)]
pub enum CachedBatchType {
    /// Cached batch in memory as Arrow array.
    MemoryArrow,
    /// Cached batch in memory as liquid array.
    MemoryLiquid,
    /// Cached batch in memory as squeezed liquid array.
    MemorySqueezedLiquid,
    /// Cached batch on disk as liquid array.
    DiskLiquid,
    /// Cached batch on disk as Arrow array.
    DiskArrow,
    /// Cached batch on disk as part of a coalesced column group.
    DiskCoalesced,
}

impl From<&CacheEntry> for CachedBatchType {
    fn from(batch: &CacheEntry) -> Self {
        match batch {
            CacheEntry::MemoryArrow(_) => Self::MemoryArrow,
            CacheEntry::MemoryLiquid(_) => Self::MemoryLiquid,
            CacheEntry::MemorySqueezedLiquid(_) => Self::MemorySqueezedLiquid,
            CacheEntry::DiskLiquid { .. } => Self::DiskLiquid,
            CacheEntry::DiskArrow { .. } => Self::DiskArrow,
            CacheEntry::DiskCoalesced { .. } => Self::DiskCoalesced,
        }
    }
}
