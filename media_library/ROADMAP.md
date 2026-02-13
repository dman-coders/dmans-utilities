# Media Library & Jellyfin Integration Roadmap

## Future Enhancements

### For parallalProcessFiles (process_media.lib)

Now that the parallel processing function is centralized in `process_media.lib`, these enhancements are easier to implement:

#### 1. **Configurable Parallelism**
Allow adjusting the number of parallel jobs via environment variable:
```bash
PARALLEL_JOBS=${PARALLEL_JOBS:-4}
find "$@" -type f -print0 | xargs --null --max-procs=$PARALLEL_JOBS ...
```
This enables tuning for different hardware without code changes.

#### 2. **Fix Typo** (Breaking Change)
Rename `parallalProcessFiles` to `parallelProcessFiles` (correct spelling). Could add compatibility alias:
```bash
parallelProcessFiles() { ... }
parallalProcessFiles() { parallelProcessFiles "$@"; }  # backwards compat
```

#### 3. **Progress Reporting**
Add visibility into parallel processing:
- File counter (e.g., "Processing file 5/42")
- Progress bar
- Estimated time remaining

#### 4. **Error Handling**
Improve robustness:
- Collect failures and report summary
- Optional fail-fast mode to stop on first error
- Better error messages for debugging

---

### For Jellyfin Integration

#### Outstanding Implementation Tasks
From README-utilities.md:

1. **jellyfin-get-item** - Lookup item by path or ID
2. **jellyfin-add-to-collection** - Add items to existing collections
3. **jellyfin-remove-from-collection** - Remove items from collections
4. **jellyfin-update-tags** - Update tags on individual items
5. **sync-collections-from-medialibrary** - Main sync script (orchestrates the above)

**Notes:**
- Jellyfin Collections (BoxSets) do NOT support hierarchical nesting
- Use naming conventions (hyphens/colons) or multiple membership for hierarchical organization
- Collections correspond to "container tags" in media_library
- Tags correspond to "leaf tags" in media_library

---

### For Documentation Completion

#### README-about-image-wrangling.md
- Complete the "Database" section explaining tag hierarchy and storage
- Document the relationships between media_library tags and Jellyfin collections/tags
- Add examples of hierarchical tag mapping

---

**Last Updated:** 2025-02-14