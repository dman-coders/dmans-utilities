# Jellyfin Utility Scripts

## Available Functions

There are two ways to nteract with Jellyfin via these utilities:
1. **Via the Jellyfin script** - `Jellyfin ListCollections` will execute that command 
2. **By importing the functions into context and invoking them directly** `source JellyFin; Listcollections` will invoke the `Listcollections()` function directly.

Both approaches also require the appropriate environmnet variables to be set and depend on them heavily.
`source .env` is the recommended way to set them up for local testing.

The following examples assume you have a `.env` file
and have included the `Jellyfin` library.

```bash
source .env
source JellyFin
```

### ListCollections
Lists all collections (BoxSets) in your Jellyfin library.

**Usage:**
```bash
JellyFin ListCollections
# or 
source JellyFin; ListCollections
```

**Output:**
```json
[
  {
    "Name": "Cute",
    "Id": "5f408f9d50b7ddd6da73b69228fbf3c6",
    "ParentId": "8679d10569ec12981200c4116da3e90b",
    "ItemCount": null,
    "Path": "/var/lib/jellyfin/data/collections/Cute [boxset]"
  },
  ...
]
```

### CreateCollection
Creates a new collection (BoxSet) in Jellyfin.

**Usage:**
```bash
CreateCollection "Collection Name" [ItemIds]
```

**Examples:**
```bash
# Create empty collection
CreateCollection "My New Collection"

# Create collection and add items
CreateCollection "Best Videos" "item-id-1,item-id-2,item-id-3"
```

**Output:**
```json
{
  "Id": "46efac6124bd5d9c930d9cd46a41c520"
}
```

### MediaFolders
Lists all media libraries (CollectionFolders).

**Usage:**
```bash
MediaFolders
```

### Genres
Lists all genres found in your library.

**Usage:**
```bash
Genres
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
