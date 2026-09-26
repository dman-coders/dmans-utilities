# Jellyfin API Optimization WIP

## Current Work: GetItemByPath via Folder Hierarchy Walking

### Breakthrough Finding

Querying by `ParentId` (folder) returns items with full Path field, avoiding pagination issues:
```bash
jf Items --parent-id {FolderId} --type Video,Photo
# Returns small, manageable result set with exact Path values
```

### Working Strategy

1. Start with library root ItemId
2. Split target path into components
3. Walk folder tree:
   - For each component, query folders: `Items --parent-id {CurrentFolderId} --type Folder`
   - Find matching folder by Name (exact match)
   - Use that folder's Id as next ParentId
4. At deepest folder, query files and match by exact Path

### Known Issues

**jq Context Error**: Piping inside select() fails
```jq
.[] | select($target | startswith(.Path))  # ❌ Error
```

**Solution**: Capture field first
```jq
.[] | select(.Path as $p | $target | startswith($p))  # ✅ Works
```

### Implementation Plan

Need to implement folder walking in GetItemByPath:
1. Extract path components: `/mnt/raid1/X/HOWTO/deepthroat all the way/practice for depth.gif`
   → `["HOWTO", "deepthroat all the way", "practice for depth.gif"]`
2. Start at library root
3. For each component (except last):
   - Query `Items --parent-id {FolderId} --type Folder --fields Name,Id`
   - Find folder where Name equals component (exact match)
   - Save its Id for next iteration
4. For last component (filename):
   - Query `Items --parent-id {FolderId} --type Video,Photo --fields Path,... `
   - Match by exact Path

This avoids searchTerm limitations and pagination issues entirely.

### Reference

- Working manual test: `/tmp/test_hierarchy.sh` (Step 3 proves ParentId approach works)
- Key API parameter: `--parent-id` on Items function
- Essential jq pattern: `.Path as $p | $target | startswith($p)` for context