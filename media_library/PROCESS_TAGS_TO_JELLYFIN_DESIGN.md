# process-tags-to-jellyfin: Phased Implementation Design

## Executive Summary

This design document outlines a phased approach to synchronizing EXIF Subject keywords from media files into Jellyfin collections. The script adapts logic from the SQLite-based `process-tags-to-db` to use the Jellyfin API instead, creating collections dynamically and managing item membership.

---

## 1. Top-Level Script Structure

### Entry Point: `process-tags-to-jellyfin`

**Location:** `/Users/dman/bin/dmans-utilities/media_library/process-tags-to-jellyfin`

**Command-line Interface:**
```
Usage: process-tags-to-jellyfin [OPTIONS] FILE|DIRECTORY [...]

Options:
  --dry-run              Extract and print tags, skip Jellyfin API writes
  --append               Add new tags to existing collections (default)
  --replace              Replace all tags/collections (use with caution)
  --hierarchical         Create parent-child collection relationships (future)
  --parallel             Use parallel processing for multiple files
  --loglevel LEVEL       Set logging verbosity (default: NOTICE)
  --test-connection      Verify Jellyfin API connection and exit
  --help                 Show this help message
```

**Exit Codes:**
- `0`: Success
- `1`: Critical error (file not found, API failure, invalid input)
- `2`: Partial success (no tags found, but processing continued)

---

## 2. Functional Architecture

### Phase 1: File Information Extraction

#### `extract_and_validate_file_tags()`
- **Purpose:** Extract EXIF tags from single media file
- **Input:** Absolute file path
- **Output:** Newline-separated deduplicated tags
- **Exit:** 0 on success, 1 on error
- **Calls:** `extract_exif_tags()` from process_media.lib
- **Error Handling:** File not found → error | No EXIF support → graceful | Empty tags → graceful

#### `validate_file_for_processing()`
- **Purpose:** Pre-check file before processing
- **Input:** File path
- **Exit:** 0 = valid, 1 = invalid
- **Checks:** File existence, readability, MIME type support

---

### Phase 2: Jellyfin State Gathering

#### `find_jellyfin_item_for_file()`
- **Purpose:** Locate Jellyfin Item by file path
- **Input:** Absolute file path
- **Output:** JSON item object (Id, Name, Path, Type)
- **Exit:** 0 on success, 1 if not found
- **Calls:** `GetItemByPath()` from JellyFin script
- **Error Handling:** Path not in library → error | Item not found → error

#### `get_item_current_collections()`
- **Purpose:** Retrieve all collections containing item
- **Input:** Jellyfin Item ID
- **Output:** JSON array of collections `[{Id, Name, ItemCount}, ...]`
- **Exit:** 0 on success, 1 on API error
- **Calls:** `FindItemCollections()` from JellyFin script
- **Error Handling:** No collections → return empty array (not an error)

#### `get_item_current_tags()`
- **Purpose:** Retrieve Tags field of item
- **Input:** Jellyfin Item ID
- **Output:** JSON array of tag strings `["tag1", "tag2", ...]`
- **Exit:** 0 on success, 1 on API error
- **Calls:** `GetItem()` with --fields Tags
- **Error Handling:** No Tags field → return empty array

---

### Phase 3: Comparison & Analysis

#### `compare_tags_to_collections()`
- **Purpose:** Match EXIF tags against collection names
- **Input:** Newline-separated EXIF tags + JSON array of existing collections
- **Output:** JSON with three keys:
  ```json
  {
    "to_create": ["tag1", "tag2"],
    "to_add": ["collection_id_1", "collection_id_2"],
    "already_member": ["collection_id_3"]
  }
  ```
- **Exit:** 0 always (no API calls, pure data transformation)
- **Matching:** Case-insensitive against collection Name fields

#### `match_tag_to_collection_name()`
- **Purpose:** Helper function for single tag-to-name matching
- **Input:** EXIF tag string + collection name
- **Exit:** 0 = match, 1 = no match
- **Handling:** Case-insensitive, supports hierarchical tags

---

### Phase 4: Collection Management & Updates

#### `create_missing_collections()`
- **Purpose:** Create new collections for tags without matches
- **Input:** Newline-separated tag names + Item ID to add as member
- **Output:** JSON mapping tag → collection_id
- **Exit:** 0 if all successful, 1 if any fail
- **Calls:** `CreateCollection()` from JellyFin for each tag
- **Error Handling:** Logs each attempt | Returns 1 on any failure

#### `add_item_to_collections()`
- **Purpose:** Add item to multiple existing collections
- **Input:** Item ID + comma-separated collection IDs
- **Exit:** 0 on success, 1 on failure
- **Calls:** API for each collection ID
- **Idempotent:** Adding item already in collection is safe/silent

#### `update_item_tags_on_jellyfin()` (Optional)
- **Purpose:** Sync EXIF tags to Jellyfin Tags field
- **Input:** Item ID + newline-separated tags + mode (append/replace)
- **Exit:** 0 on success, 1 on API error
- **Conditional:** Only called if --update-tags flag set

---

### Orchestration

#### `process_single_file()`
- **Purpose:** Master function orchestrating all 4 phases
- **Input:** File path + processing options
- **Exit:** 0 = success, 1 = error, 2 = partial/warning
- **Flow:**
  1. Validate file
  2. Extract EXIF tags (Phase 1) → skip if no tags (return 2)
  3. Find item in Jellyfin (Phase 2a) → stop if not found (return 1)
  4. Get current collections & tags (Phase 2b, 2c)
  5. Compare tags to collections (Phase 3)
  6. Report findings (stop if --dry-run)
  7. Create missing collections (Phase 4a)
  8. Add item to collections (Phase 4b)
  9. Verify results → return 0

---

## 3. Data Flow

```
INPUT: File path(s)
  ↓
[Validate File] → extract_and_validate_file_tags()
  ↓ (tags found)
[Phase 1: Extract Tags] → TAG_ARRAY
  ↓
[Phase 2: Gather Jellyfin State]
  ├─ find_jellyfin_item_for_file() → ITEM_JSON
  ├─ get_item_current_collections() → COLLECTIONS_JSON
  └─ get_item_current_tags() → TAGS_JSON
  ↓
[Phase 3: Compare] → compare_tags_to_collections()
  ↓
  PLAN = {to_create, to_add, already_member}
  ↓
[If --dry-run: print plan and exit 0]
  ↓
[Phase 4a: Create Collections] → create_missing_collections()
  ↓
[Phase 4b: Add to Collections] → add_item_to_collections()
  ↓
[Phase 4c: Update Tags] (optional) → update_item_tags_on_jellyfin()
  ↓
[Verify & Report]
  ↓
OUTPUT: Exit code (0=success, 1=error, 2=partial)
```

---

## 4. Error Handling Strategy

| Phase | Scenario | Action | Exit |
|-------|----------|--------|------|
| Validate | File not found | Skip | 1 |
| Validate | Not readable | Skip | 1 |
| 1: Extract | No EXIF tags | Continue | 2 |
| 1: Extract | Extraction fails | Continue | 1 |
| 2a: Find Item | Not in Jellyfin | Skip file | 1 |
| 2b: Collections | API error | Stop & fail | 1 |
| 2c: Tags | API error | Log, continue | 0* |
| 3: Compare | (N/A - no API) | N/A | N/A |
| 4a: Create | Single fail | Stop & fail | 1 |
| 4b: Add | Single fail | Stop & fail | 1 |
| 4c: Update | API error | Log, continue | 0* |

\* = error in optional step doesn't block success

**Validation Layers:**
1. Input: File existence, readability, MIME type
2. API: Verify env vars set, test connection
3. State: Verify item still exists after lookup, verify IDs valid
4. Idempotency: Adding item already in collection is safe

---

## 5. Edge Cases

| Case | Action |
|------|--------|
| No EXIF tags found | Exit with code 2 (warning) |
| Item not in Jellyfin | Exit with code 1 (error) |
| Hierarchical tags (e.g., "Location/Indoor") | Create flat or nested (future --hierarchical) |
| Collection already exists | Skip creation, add item to existing |
| Item already in collection | Skip adding (idempotent) |
| Duplicate tags in EXIF | Deduplicate automatically |
| Tag name conflicts (case-sensitive) | Use case-insensitive matching |
| Long tag names (>255 chars) | Let Jellyfin truncate, log warning |
| Special characters in tags | Let API handle validation, log error |
| API rate limiting | Log error, suggest --sequential mode |

---

## 6. Logging & Output

**Using feedback_functions.lib:**
- `log_section()` - High-level phase headers
- `log_subsection()` - Sub-phase details
- `log_info()` - Informational messages
- `log_success()` - Successful operations
- `log_debug()` - Detailed diagnostic output
- `log_error()` - Error conditions
- `log_warning()` - Non-fatal issues

**Dry-run Output:**
```
Phase 1: Extracting EXIF tags
  Found 5 tags: [tag1, tag2, tag3, tag4, tag5]

Phase 2: Gathering Jellyfin state
  Item ID: abc123...
  Current collections: 2
  Current tags: [existing_tag1, existing_tag2]

Phase 3: Comparison
  Tags to create: 3
  Collections to add: 2
  Already member: 0

DRY-RUN MODE: The following would happen:
  Would create 3 new collections
  Would add item to 2 collection(s)
  No changes made to Jellyfin
```

---

## 7. Required Libraries & Dependencies

### Sourcing Order (Important!)
1. `feedback_functions.lib` - Used by all others
2. `process_media.lib` - Provides extract_exif_tags()
3. `jellyfin-utils.lib` - Path mapping utilities
4. `JellyFin` script - API operations

### Environment Variables
```
JELLYFIN_HOST                   # Jellyfin server hostname
JELLYFIN_PORT                   # API port (usually 8096)
JELLYFIN_API_KEY                # API authentication key
JELLYFIN_USERID                 # User ID for operations
JELLYFIN_ROOT_DATA_FOLDER       # Server-side path
JELLYFIN_LOCAL_DATA_FOLDER      # Local/mapped path
```

### Key Function Signatures

**Phase 1:**
```bash
extract_exif_tags "$filepath"
```

**Phase 2:**
```bash
$jf GetItemByPath "$server_path"
$jf FindItemCollections "$item_id"
$jf GetItem "$item_id" --fields Tags
```

**Phase 4:**
```bash
$jf CreateCollection --name "TagName" --items "$item_id"
$jf AddItemToCollection "$collection_id" "$item_id"
```

---

## 8. Implementation Status

### ✅ Completed
- [x] Create process-tags-to-jellyfin script skeleton
- [x] Implement Phase 1 functions (extract_and_validate_file_tags)
- [x] Implement Phase 2 functions (find_jellyfin_item_for_file, get_item_current_collections, get_item_current_tags)
- [x] Implement Phase 3 functions (compare_tags_to_collections with jq)
- [x] Implement Phase 4 functions (create_missing_collections, add_item_to_collections)
- [x] Implement orchestration (process_single_file, main entry point)
- [x] Add command-line argument parsing (--dry-run, --append, --replace, --help)
- [x] Add --dry-run support with action planning
- [x] Add comprehensive logging via feedback_functions.lib (LOGLEVEL=8 for debug)
- [x] Test with single file (dry-run first, then real)
- [x] Test idempotency (running twice has no effect on already-synced items)
- [x] Test error cases (partial success handling)
- [x] Verified compatibility with bash 3.2 (macOS)

### 🔄 Implemented but Not Yet Tested at Scale
- [ ] --parallel support (flag parsed but not used yet)
- [ ] Directory recursion (not implemented, flags as unimplemented)
- [ ] Multiple files in batch

### ⏳ Future Enhancements (Not Implemented)
- [ ] --hierarchical flag: Create parent-child collection relationships
- [ ] --update-tags flag: Sync tags to Jellyfin Tags field
- [ ] Directory recursion and batch processing
- [ ] Parallel processing with --parallel flag
- [ ] Performance optimizations (caching)
- [ ] Reverse sync: Jellyfin collections → EXIF metadata

---

## 9. Testing Strategy

**Unit Tests (per function):**
- Extract tags from various EXIF files
- Comparison logic with mock data
- Tag-to-name matching with hierarchical tags

**Integration Tests:**
- Full workflow on single file (--dry-run first)
- Files with no tags
- Items already in collections
- Existing collection names

**Manual Testing:**
```bash
# Dry-run on single file
./process-tags-to-jellyfin --dry-run /path/to/media.mp4

# Dry-run on directory
./process-tags-to-jellyfin --dry-run /path/to/media/

# Actual run with debug logging
LOGLEVEL=DEBUG ./process-tags-to-jellyfin /path/to/media.mp4

# Batch processing
find /path/to/media -type f -name "*.mp4" | \
    xargs ./process-tags-to-jellyfin --parallel
```

---

## 10. Future Enhancements

- `--hierarchical` flag: Create parent-child collection relationships
- Reverse sync: Sync Jellyfin collections back to EXIF metadata
- Tag synonym support: Integrate with media_library tag system
- Performance: Cache path→itemid mappings
- UI: Real-time sync dashboard showing progress and statistics