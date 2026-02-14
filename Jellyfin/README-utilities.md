# Jellyfin Integration Utilities

## Quick Start

Two ways to use these utilities:

1. **CLI mode:** `./JellyFin ListCollections`
2. **Library mode:** `source JellyFin; ListCollections`

Both require `.env` to be sourced first:
```bash
source .env
./JellyFin <command> [options]
```

## Available Functions

**System Information:**
- `TestConnection` - Verify connection to Jellyfin server
- `SystemInfo` - Get server information and version
- `MediaFolders` - List all media libraries
- `Genres` - List all genres in the library
- `Tags` - List all tags available in the library

**Item Queries:**
- `Items` - Query items with flexible filtering (type, tags, genres, recursive, limit, pagination)
- `GetItem` - Get detailed information about a specific item
- `GetItemByPath` - Look up an item by filesystem path
- `Hierarchy` - Display library hierarchy as a tree

**Collections (BoxSets):**
- `ListCollections` - List all collections
- `CreateCollection` - Create a new collection (with optional items)
- `CollectionItems` - List items in a collection
- `AddItemToCollection` - Add items to a collection
- `RemoveItemFromCollection` - Remove items from a collection
- `FindItemCollections` - Find all collections containing an item

**Item Modifications:**
- `UpdateItem` - Update general item properties
- `UpdateTags` - Update tags on an item (append, replace, or clear modes)

For detailed usage and options, use `--help` with any command:
```bash
./JellyFin ListCollections --help
./JellyFin GetItem --help
./JellyFin CreateCollection --help
```

## Important Findings

### Collections Do NOT Support Nesting
After testing, we confirmed that **Jellyfin Collections (BoxSets) do not support hierarchical nesting**. All collections exist at the same flat level.

**Implication for hierarchical media_library tags:**
- media_library: `Location/Inside/Bedroom`
- Jellyfin options:
  - Option A: `Location-Inside-Bedroom` (hyphen delimiter)
  - Option B: `Location: Inside: Bedroom` (colon delimiter)
  - Option C: Create separate collections: `Location`, `Inside`, `Bedroom` (items in multiple)

**Recommendation:** Use naming conventions (Option A or B) for hierarchical organization, or use multiple collection membership (Option C) where appropriate.

### Collections vs Tags for Organization

**Use Collections for:**
- Major topics/categories (Bondage, Deepthroat, FFM, Instructional)
- Primary browsing/navigation
- Categories you want prominent in UI with cover art
- Corresponds to your **container tags** in media_library

**Use Tags for:**
- Minor attributes (anatomy, dress sexy, flirty)
- Filtering/search refinement
- Technical metadata (source attribution)
- Corresponds to your **leaf tags** in media_library

### Multiple Membership
Items can belong to multiple collections, which maintains the flexibility of your hierarchical tag system even though collections themselves are flat.

## Next Steps

To complete the integration toolkit, you'll need:

1. **jellyfin-get-item** - Lookup item by path or ID
2. **jellyfin-add-to-collection** - Add items to existing collections
3. **jellyfin-remove-from-collection** - Remove items from collections
4. **jellyfin-update-tags** - Update tags on individual items
5. **sync-collections-from-medialibrary** - Main sync script

See JELLYFIN_DATA_MODEL.md for detailed API documentation and integration strategies.
