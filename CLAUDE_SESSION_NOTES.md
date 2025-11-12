# Media Metadata Management - Claude Session Notes

**Date:** 2025-11-10

## Current Objective

Build media metadata management tools that integrate the `media_library` (local SQLite-based tag system) with Jellyfin API for comprehensive media organization.

## Context Gathered

### media_library System
Located in: `/Volumes/dman/bin/dmans-utilities/media_library/`

**Core Components:**
- **process_media.lib** - Main library with SQLite database functions
  - Database: `~/.media_processing/media.sqlite`
  - Tables: `tag_types`, `tags`, `synonyms`
  - Tag types: `container` (hierarchical parent tags) and `leaf` (end tags)
  - Hierarchical tag support with slash notation (e.g., `Location/Inside/Bedroom`)
  - Functions: `ensure_tag_exists()`, `set_synonym_for()`, `dump_tags()`, `update_tag_hierarchy()`

**Key Utilities:**
- `process-metadata` - Adds UUID, provenance, filename as description, directory as keyword
- `duplicate-exif-from-webp` - Copies EXIF between webp and gif files
- `move-file-to-uuid-archive` - Archives files by UUID

**Test Files:**
- `test_ensure_tag_exists.sh`
- `test_db_constraints.sh`
- `test_parent_child.sh`
- `test_update_hierarchy.sh`

### Jellyfin Integration
Located in: `/Volumes/dman/bin/dmans-utilities/Jellyfin/`

**Configuration:**
- `.env` file contains:
  - `JELLYFIN_API_KEY=3858cc6b509b4baca16a3943641561ea`
  - `JELLYFIN_HOST=granite.local`
  - `JELLYFIN_PORT=8096`
  - API endpoint: `http://granite.local:8096`

**Current Scripts:**
- `TestConnection` - Basic curl test with auth header
- `Genres` - Query library genres
- `MediaFolders` - List media folders with name, collection type, path

**API Documentation:**
- Swagger UI: http://granite.local:8096/api-docs/swagger/index.html
- OpenAPI spec (likely): http://granite.local:8096/api-docs/openapi.json

## Latest Update: 2025-11-12

### media_library Refactoring Complete ✓

**Task:** Extract duplicated `parallalProcessFiles` function to shared library

**Completed:**
- Added `parallalProcessFiles()` to `process_media.lib`
- Updated 4 scripts to source the library:
  - `process-metadata`
  - `process-clips` (with additional `processWebpFile` export)
  - `duplicate-exif-from-webp`
  - `process-dirname-as-keyword`
- Removed ~40 lines of duplicated code
- Maintained atomic script philosophy
- No changes to external behavior or invocation

**Documentation:**
- `REFACTORING-parallalProcessFiles.md` - Analysis and options
- `REFACTORING-COMPLETE.md` - Summary of changes

**Recommendation:** Test each script with sample files to verify functionality

---

## Current Status: Phase 2 - Core API Operations (In Progress)

### Completed Tasks ✓

1. **ERD and Documentation** (JELLYFIN_DATA_MODEL.md)
   - Complete Mermaid ERD showing entity relationships
   - Comprehensive documentation of all entities
   - API endpoint reference with examples
   - Best practices for querying
   - Integration strategies for media_library

2. **Utility Scripts Created**
   - `ListCollections` - List all collections with IDs and paths
   - `CreateCollection` - Create new collections (with optional initial items)

### Key Findings

**Collections (BoxSets) Architecture:**
- ✓ Items CAN be in multiple collections
- ✓ Collections stored in `/var/lib/jellyfin/data/collections/`
- ✗ Collections do NOT support hierarchical nesting (all flat)
- Recommendation: Use naming conventions for hierarchy (e.g., "Location: Inside: Bedroom")

**Organizational Strategy:**
- **Collections** = Major topics/categories (corresponds to container tags)
  - Better UX: prominent display, cover art, descriptions
  - Use for primary browsing (Bondage, Instructional, FFM, etc.)
- **Tags** = Minor attributes/filters (corresponds to leaf tags)
  - Use for secondary characteristics (anatomy, dress sexy, flirty)
  - Less prominent but useful for filtering

## Proposed Next Steps (After API Access Resolved)

### Phase 1: Jellyfin API Understanding
1. **Fetch API specification** (blocked - needs local access)
   - Download OpenAPI/Swagger JSON spec
   - Extract schemas for: BaseItem, Library, Collection, Tag, Genre
   - Identify key endpoints for CRUD operations

2. **Create documentation**
   - ERD diagram (Mermaid)
   - Object model summary
   - API endpoint reference for core operations

### Phase 2: Core API Operations
3. **Build Jellyfin utility library** (similar to process_media.lib)
   - Authentication helpers
   - GET/POST/PUT/DELETE wrappers
   - Error handling

4. **Implement key operations**
   - Query items by library/collection
   - Add/update/delete tags on items
   - Create and manage collections
   - Batch operations

### Phase 3: Integration
5. **Metadata sync tools**
   - Export media_library tags → Jellyfin
   - Import Jellyfin metadata → media_library
   - Bidirectional sync with conflict resolution

6. **Tag mapping**
   - Translate hierarchical tags (Location/Inside/Bedroom) to flat Jellyfin tags
   - Handle synonym resolution

7. **Workflow automation**
   - Process new media through media_library pipeline
   - Auto-import to Jellyfin with metadata
   - Monitor and update

### Phase 4: Reporting & Maintenance
8. **Query and reporting tools**
   - Find untagged items
   - Identify metadata inconsistencies
   - Generate statistics

9. **Maintenance utilities**
   - Cleanup orphaned tags
   - Validate data integrity
   - Backup and restore

## Files to Reference

### Modified (per git status):
- `media_library/README-about-image-wrangling.md`
- `media_library/check-schema`
- `media_library/process_media.lib`
- `media_library/test_db_constraints.sh`
- `media_library/test_ensure_tag_exists.sh`

### New/Untracked:
- `Jellyfin/` - All files

## Recommended Workaround for API Access

Since Claude cannot access granite.local, user should:

1. **Download API spec locally:**
   ```bash
   cd /Volumes/dman/bin/dmans-utilities/Jellyfin
   source .env
   curl -s "http://$JELLYFIN_HOST:$JELLYFIN_PORT/api-docs/openapi.json" > jellyfin-api-spec.json
   ```

2. **Query sample data:**
   ```bash
   # Get a sample item
   curl -s -H "Authorization: MediaBrowser Token=\"$JELLYFIN_API_KEY\"" \
        "http://$JELLYFIN_HOST:$JELLYFIN_PORT/Items?Limit=1&IncludeItemTypes=Photo" \
        > sample-item.json

   # Get collections
   curl -s -H "Authorization: MediaBrowser Token=\"$JELLYFIN_API_KEY\"" \
        "http://$JELLYFIN_HOST:$JELLYFIN_PORT/Collections" \
        > collections.json

   # Get tags
   curl -s -H "Authorization: MediaBrowser Token=\"$JELLYFIN_API_KEY\"" \
        "http://$JELLYFIN_HOST:$JELLYFIN_PORT/Items/Filters" \
        > filters-tags.json
   ```

3. **Resume session with Claude** - Provide the downloaded JSON files for analysis

## Architecture Notes

The current system is deliberately **atomic** - small shell scripts performing discrete tasks. This is intentional for flexibility and composability.

Future integration should maintain this philosophy:
- Small, focused scripts
- Clear input/output contracts
- Easy to test and debug
- Composable into larger workflows

## Questions to Resolve

1. What is the primary workflow? Jellyfin → media_library or media_library → Jellyfin?
2. Should tags sync bidirectionally or one-way?
3. How to handle hierarchical tags in flat Jellyfin tag system?
4. Should synonyms be expanded when pushing to Jellyfin?
5. What triggers sync operations? Manual script, cron job, file watcher?

---

**Session interrupted due to network connectivity issues accessing granite.local:8096**

**To resume:** Download API specs and sample data using above curl commands, then restart Claude session.
