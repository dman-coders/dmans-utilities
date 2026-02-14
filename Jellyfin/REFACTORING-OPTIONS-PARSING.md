# JellyFin Options Parsing Refactoring

## Summary

Standardized argument parsing across JellyFin command functions to use consistent, extensible `case` statement pattern instead of naive positional checking.

## Changes Made

### 1. **GetItem()** (lines 251-335)
**Before:** Naive positional parsing
```bash
if [ "$2" = "--fields" ]; then
    FIELDS="$3"
fi
```

**After:** Full `case` statement with options
- `--fields FIELD1,FIELD2` - Fields to include
- `--output format` - Output format: json (default), raw
- `--help` - Show help

**Backward Compatible:** ✅ Yes, still works as `GetItem ITEM_ID --fields Name`

---

### 2. **ListCollections()** (lines 337-385)
**Before:** Naive positional parsing
```bash
[ "$1" = "--fields" ] && FIELDS="$2"
```

**After:** Full `case` statement with options
- `--fields FIELD1,FIELD2` - Fields to include (default: Path,ParentId,ItemCount)
- `--limit N` - Limit results
- `--output format` - Output format: summary (default), full
- `--help` - Show help

**Enhancement:** Now supports `--output full` to get all fields vs. default summary

---

### 3. **CreateCollection()** (lines 387-515)
**Before:** Positional-only with limited flexibility
```bash
CreateCollection "Name" "id1,id2,id3"
```

**After:** Both legacy positional AND new option-style supported
```bash
# Legacy (still works)
CreateCollection "Name" "id1,id2,id3"

# New style
CreateCollection --name "Name" --items "id1,id2,id3" --is-locked
```

**New Options:**
- `--name NAME` - Collection name (required)
- `--items ID1,ID2,...` - Comma-separated item IDs
- `--items-space ID1 ID2...` - Space-separated item IDs (more shell-friendly)
- `--parent-id ID` - Parent collection ID (for future nesting support)
- `--is-locked` - Lock the collection
- `--output format` - Output format: id (default), full
- `--help` - Show help

**Backward Compatible:** ✅ Yes, detects legacy positional form and handles it

---

## Pattern Used (Exemplar: Items())

All refactored functions now follow this pattern:

```bash
FunctionName() {
    # Declare all variables
    local REQUIRED_ARG="$1"
    shift

    local OPTION_VAR=""
    local FLAG=false

    # Parse options in a loop
    while [[ $# -gt 0 ]]; do
        case $1 in
            --option-with-value)
                OPTION_VAR="$2"
                shift 2
                ;;
            --flag)
                FLAG=true
                shift
                ;;
            --help)
                # Show help text
                return 0
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Now use variables with confidence
    # Option order is now irrelevant
}
```

## Benefits of This Refactoring

✅ **Extensible** - Add new options without breaking existing calls
✅ **Position-Independent** - Options can appear in any order
✅ **Self-Documenting** - `--help` shows all available options
✅ **Consistent** - All functions follow same pattern
✅ **Backward Compatible** - Existing scripts keep working
✅ **Scalable** - Easy to add new flags, values, complex option combinations
✅ **Provably Correct** - Pattern already proven in Items(), UpdateTags(), Hierarchy()

## Testing Recommendations

```bash
# GetItem - basic and with options
JellyFin GetItem "item-id"
JellyFin GetItem "item-id" --fields Id,Name
JellyFin GetItem "item-id" --fields Id,Name --output raw
JellyFin GetItem "item-id" --help

# ListCollections - with new output modes
JellyFin ListCollections
JellyFin ListCollections --output full
JellyFin ListCollections --limit 10
JellyFin ListCollections --help

# CreateCollection - both legacy and new style
JellyFin CreateCollection "Test 1"
JellyFin CreateCollection "Test 2" "id1,id2"  # legacy
JellyFin CreateCollection --name "Test 3" --items "id1,id2" --is-locked
JellyFin CreateCollection --help
```

## Functions Not Yet Refactored

These functions use naive or incomplete argument handling and could benefit from similar refactoring:

- `GetItemByPath()` - Currently takes one positional arg only, could add filtering/output options
- `CollectionItems()` - Delegates to Items(), already inherits good pattern
- Other utility functions as needed

---

**Date:** 2025-02-14
**Pattern Source:** Items() function (lines 148-235)
**Files Modified:** JellyFin