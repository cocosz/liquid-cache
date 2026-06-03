@bharath-techie Love the watermark idea — gradual pressure instead of a hard cliff makes a lot of sense. So something like:

- **Low watermark (e.g. 70%):** background eviction starts, removes unleased entries best-effort. Queries keep caching normally.
- **High watermark (e.g. 90%):** aggressive eviction. If still can't free enough (everything leased), new inserts skip caching and fall back to Parquet.

A few questions:

1. Should the low watermark eviction run as a background task (periodic / on a timer), or trigger inline during `write_batch_to_disk` when we cross the threshold?

2. For the eviction target at low watermark — should we evict down to some target (e.g. back to 50%) to avoid thrashing, or just evict enough to get back below the low watermark?

3. Should the watermark thresholds be user-configurable, or are sensible defaults enough for now?
