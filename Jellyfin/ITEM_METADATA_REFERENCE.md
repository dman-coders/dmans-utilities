# Jellyfin Item Metadata Reference

## Overview

This document demonstrates how to retrieve complete metadata context for a Jellyfin item, including tags, genres, parent albums, and collections. The existing API functions provide all necessary capabilities to gather this information.

## Quick Example

```bash
TESTFILE="/Volumes/x-files/goodstuff/wild/IMG_3423.GIF"
jf GetItemByPath "$TESTFILE"
```

## Complete Metadata Walkthrough

The following script demonstrates retrieving all metadata associated with an item:

### Step 1: Get the Item

```bash
TESTFILE="/Volumes/x-files/goodstuff/wild/IMG_3423.GIF"
ITEM=$(jf GetItemByPath "$TESTFILE" 2>/dev/null)
ITEM_ID=$(echo "$ITEM" | jq -r '.Id')
ALBUM_ID=$(echo "$ITEM" | jq -r '.AlbumId')

echo "Item ID: $ITEM_ID"
echo "Album ID: $ALBUM_ID"
echo "Tags: $(echo "$ITEM" | jq -c '.Tags')"
echo "Genres: $(echo "$ITEM" | jq -c '.Genres')"
```

**Sample Response:**
```
Item ID: 6b0f492411e8967a524359a262dcb631
Album ID: 50b8ed580c380848378e6033099a72d7
Tags: ["B&W"]
Genres: ["Black and White"]
```

### Step 2: Get Parent Album Details

```bash
ALBUM=$(jf GetItem "$ALBUM_ID" 2>/dev/null)
echo "Album: $(echo "$ALBUM" | jq -r '.Name')"
echo "Album Path: $(echo "$ALBUM" | jq -r '.Path')"
```

**Sample Response:**
```
Album: wild
Album Path: /mnt/raid1/X/goodstuff/wild
```

### Step 3: Find Collections Containing Item

```bash
COLLECTIONS=$(jf FindItemCollections "$ITEM_ID" 2>/dev/null)
COLL_COUNT=$(echo "$COLLECTIONS" | jq 'length' 2>/dev/null)
echo "Collections containing this item: $COLL_COUNT"
echo "$COLLECTIONS" | jq -r '.[] | .Name' 2>/dev/null
```

**Sample Response:**
```
Collections containing this item: 1
Short Black & White clips
```

### Step 4: Reference Available Tags and Genres

```bash
echo "Total tags in library:"
jf Tags 2>/dev/null | jq 'length'

echo "Sample tags:"
jf Tags 2>/dev/null | jq -r '.[]' | head -10
```

**Sample Response:**
```
Total tags in library:
47

Sample tags:
Orgasm
PMV
Prone bone
Pussy Grip
regardscoupable
Reverse facefuck
Reverse Piledriver
Rimming
Rythmic
sexy pics
```

## Complete Demonstration Script

```bash
#!/bin/bash
# Complete item metadata retrieval demonstration

TESTFILE="/Volumes/x-files/goodstuff/wild/IMG_3423.GIF"

echo "=== STEP 1: Get Item ==="
ITEM=$(jf GetItemByPath "$TESTFILE" 2>/dev/null)
ITEM_ID=$(echo "$ITEM" | jq -r '.Id')
ALBUM_ID=$(echo "$ITEM" | jq -r '.AlbumId')

echo "Item ID: $ITEM_ID"
echo "Album ID: $ALBUM_ID"
echo "Tags: $(echo "$ITEM" | jq -c '.Tags')"
echo "Genres: $(echo "$ITEM" | jq -c '.Genres')"
echo ""

echo "=== STEP 2: Get Parent Album Details ==="
ALBUM=$(jf GetItem "$ALBUM_ID" 2>/dev/null)
echo "Album: $(echo "$ALBUM" | jq -r '.Name')"
echo "Album Path: $(echo "$ALBUM" | jq -r '.Path')"
echo ""

echo "=== STEP 3: Find Collections Containing Item ==="
COLLECTIONS=$(jf FindItemCollections "$ITEM_ID" 2>/dev/null)
COLL_COUNT=$(echo "$COLLECTIONS" | jq 'length' 2>/dev/null)
echo "Collections containing this item: $COLL_COUNT"
echo "$COLLECTIONS" | jq -r '.[] | .Name' 2>/dev/null
echo ""

echo "=== STEP 4: All Available Tags/Genres (sample) ==="
echo "Total tags in library:"
jf Tags 2>/dev/null | jq 'length'
echo ""
echo "Sample tags:"
jf Tags 2>/dev/null | jq -r '.[] | select(. | contains("Black") or contains("B&W"))' 2>/dev/null
```

**Full Output:**
```
=== STEP 1: Get Item ===
Item ID: 6b0f492411e8967a524359a262dcb631
Album ID: 50b8ed580c380848378e6033099a72d7
Tags: ["B&W"]
Genres: ["Black and White"]

=== STEP 2: Get Parent Album Details ===
Album: wild
Album Path: /mnt/raid1/X/goodstuff/wild

=== STEP 3: Find Collections Containing Item ===
Collections containing this item: 1
Short Black & White clips

=== STEP 4: All Available Tags/Genres (sample) ===
Total tags in library:
47

Sample tags:
B&W
```

## API Reference

### Available Functions for Metadata Retrieval

| Function | Purpose | Example |
|----------|---------|---------|
| `GetItemByPath` | Retrieve item by file path | `jf GetItemByPath "/path/to/file.gif"` |
| `GetItem` | Retrieve item by ID | `jf GetItem "6b0f4924..."` |
| `FindItemCollections` | Find BoxSets containing an item | `jf FindItemCollections "6b0f4924..."` |
| `ListCollections` | List all BoxSet collections | `jf ListCollections` |
| `Tags` | Get all available tags | `jf Tags` |
| `Genres` | Get all available genres | `jf Genres` |

### Item Properties

From `GetItemByPath` response:

| Property | Type | Description |
|----------|------|-------------|
| `Id` | string | Unique item identifier |
| `Name` | string | Item name/title |
| `Path` | string | Filesystem path on server |
| `Type` | string | Item type (Photo, Video, etc.) |
| `Tags` | array | Custom tags applied to item (max 47 in library) |
| `Genres` | array | Genre classifications |
| `AlbumId` | string | Parent album/folder ID |
| `AlbumName` | string | Parent album name |

## Data Relationships

```
Item (from GetItemByPath)
├─ .Id                    → use in FindItemCollections, GetItem
├─ .Tags[]                → match against Tags vocabulary (47 available)
├─ .Genres[]              → match against Genres vocabulary
├─ .AlbumId               → use in GetItem to fetch parent details
│  └─ Parent Album        → .Name, .Path, .RecursiveItemCount, .ChildCount
└─ FindItemCollections()  → returns BoxSet collections containing this item
   └─ Collections[].Name  → e.g., "Short Black & White clips"
```

## Jellyfin Metadata Concepts

### Tags
- Custom, user-defined categorizations
- Flat list (no hierarchy)
- 47 available tags in sample library
- Example: "B&W", "PMV", "Orgasm"

### Genres
- System-provided genre classifications
- Example: "Black and White"
- Can have multiple genres per item

### Collections (BoxSets)
- Explicit groupings of items
- Queried via `FindItemCollections`
- Example: "Short Black & White clips"
- Items can belong to multiple collections

### Albums (Parent Folders)
- Hierarchical folder structure
- Retrieved via AlbumId
- Contain metadata like RecursiveItemCount, ChildCount
- AlbumId establishes direct parent-child relationship

## Summary

The existing Jellyfin API utilities provide comprehensive access to:

1. **Direct item metadata** - Tags, Genres, Type from GetItemByPath
2. **Hierarchical context** - Parent album via AlbumId
3. **Collection membership** - FindItemCollections for BoxSet associations
4. **Library vocabulary** - Tags and Genres functions for context

No additional wrapper functions are required to access this metadata. The demonstrated workflow shows that all necessary information can be gathered using existing functions with straightforward jq filtering.

## Use Cases

### Example 1: Find all items with a specific tag

```bash
TAG="B&W"
jf Items --recursive --limit 5000 2>/dev/null | \
  jq -r ".[] | select(.Tags[] == \"$TAG\") | .Name"
```

### Example 2: Find items in a specific collection

```bash
COLLECTION_ID="collection-id-here"
jf Items --parent-id "$COLLECTION_ID" 2>/dev/null | \
  jq -r '.[] | "\(.Name) (ID: \(.Id))"'
```

### Example 3: Get complete context for a file

```bash
FILE="/path/to/file.gif"
ITEM=$(jf GetItemByPath "$FILE" 2>/dev/null)
ITEM_ID=$(echo "$ITEM" | jq -r '.Id')
ALBUM=$(jf GetItem "$(echo "$ITEM" | jq -r '.AlbumId')" 2>/dev/null)
COLLECTIONS=$(jf FindItemCollections "$ITEM_ID" 2>/dev/null)

echo "Item: $(echo "$ITEM" | jq -r '.Name')"
echo "Album: $(echo "$ALBUM" | jq -r '.Name')"
echo "Tags: $(echo "$ITEM" | jq -c '.Tags')"
echo "Genres: $(echo "$ITEM" | jq -c '.Genres')"
echo "Collections: $(echo "$COLLECTIONS" | jq -c '[.[].Name]')"
```

## Notes

- All functions support `2>/dev/null` to suppress debug logging
- Use `LOGLEVEL=7` to enable verbose logging for troubleshooting
- jq is used for JSON parsing and filtering throughout examples
- The `/tmp/test_*.sh` scripts from development contain additional examples
