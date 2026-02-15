# process_media.lib - Pending Refactoring

## Priority Issues

### 4. **Duplicate SQL WHERE Patterns**
**Issue:** Multiple functions use similar SQL patterns
**Opportunity:** Consolidate into helper functions like `update_tag_field()`
**Priority:** Low-Medium

---

### 6. **Tag Resolution Standardization**
**Status:** Mostly consistent but not fully standardized
**Opportunity:** Could add `resolve_tag_safely()` helper for consistency
**Priority:** Low