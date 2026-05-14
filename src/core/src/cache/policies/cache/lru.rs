//! LRU (Least Recently Used) cache eviction policy.
//!
//! Evicts entries that haven't been accessed for the longest time.
//! Uses a doubly-linked list with entries moved to the back on access.
//! Victims are taken from the front (least recently used).

use crate::cache::cached_batch::CachedBatchType;
use crate::cache::utils::EntryID;
use crate::sync::Mutex;
use ahash::AHashMap;
use std::ptr::NonNull;

use super::CachePolicy;
use super::doubly_linked_list::{DoublyLinkedList, DoublyLinkedNode, drop_boxed_node};

/// LRU cache eviction policy.
///
/// On insert: entry goes to the back of the list (most recently used).
/// On access: entry moves to the back of the list.
/// On eviction: entries are taken from the front (least recently used).
#[derive(Debug)]
pub struct LruPolicy {
    inner: Mutex<LruInner>,
}

#[derive(Debug)]
struct LruInner {
    list: DoublyLinkedList<EntryID>,
    map: AHashMap<EntryID, NonNull<DoublyLinkedNode<EntryID>>>,
}

// Safety: We control access via Mutex and never expose raw pointers outside.
unsafe impl Send for LruInner {}
unsafe impl Sync for LruInner {}

impl LruPolicy {
    /// Create a new LRU policy.
    pub fn new() -> Self {
        Self {
            inner: Mutex::new(LruInner {
                list: DoublyLinkedList::new(),
                map: AHashMap::new(),
            }),
        }
    }
}

impl Default for LruPolicy {
    fn default() -> Self {
        Self::new()
    }
}

impl CachePolicy for LruPolicy {
    fn find_memory_victim(&self, cnt: usize) -> Vec<EntryID> {
        let mut inner = self.inner.lock().unwrap();
        let mut victims = Vec::with_capacity(cnt);

        for _ in 0..cnt {
            // Pop from the front (least recently used)
            let Some(node_ptr) = inner.list.head() else {
                break;
            };
            let entry_id = unsafe { node_ptr.as_ref().data };
            unsafe { inner.list.unlink(node_ptr) };
            inner.map.remove(&entry_id);
            unsafe { drop_boxed_node(node_ptr) };
            victims.push(entry_id);
        }

        victims
    }

    fn find_disk_victim(&self, _cnt: usize) -> Vec<EntryID> {
        vec![]
    }

    fn notify_insert(&self, entry_id: &EntryID, _batch_type: CachedBatchType) {
        let mut inner = self.inner.lock().unwrap();

        // If already present, remove old position first
        if let Some(node_ptr) = inner.map.remove(entry_id) {
            unsafe { inner.list.unlink(node_ptr) };
            unsafe { drop_boxed_node(node_ptr) };
        }

        // Insert at the back (most recently used)
        let node = DoublyLinkedNode::new(*entry_id);
        let node_ptr = NonNull::new(Box::into_raw(node)).unwrap();
        unsafe { inner.list.push_back(node_ptr) };
        inner.map.insert(*entry_id, node_ptr);
    }

    fn notify_access(&self, entry_id: &EntryID, _batch_type: CachedBatchType) {
        let mut inner = self.inner.lock().unwrap();

        let Some(&node_ptr) = inner.map.get(entry_id) else {
            return;
        };

        // Move to the back (most recently used)
        unsafe {
            inner.list.unlink(node_ptr);
            inner.list.push_back(node_ptr);
        }
    }

    fn notify_remove(&self, entry_id: &EntryID) {
        let mut inner = self.inner.lock().unwrap();

        if let Some(node_ptr) = inner.map.remove(entry_id) {
            unsafe { inner.list.unlink(node_ptr) };
            unsafe { drop_boxed_node(node_ptr) };
        }
    }
}

impl Drop for LruPolicy {
    fn drop(&mut self) {
        let mut inner = self.inner.lock().unwrap();
        unsafe { inner.list.drop_all() };
        inner.map.clear();
    }
}
