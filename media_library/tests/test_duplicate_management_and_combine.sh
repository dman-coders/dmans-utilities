#!/usr/bin/env bash

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$TEST_SCRIPT_DIR/test.sqlite"
source "$TEST_SCRIPT_DIR/../process_media.lib"
source "$TEST_SCRIPT_DIR/test_framework.sh"

init_test_suite "Duplicate Management and Combine Tags"

setup_test_db

# Test 1: Adding tags with different cases should NOT create duplicates
begin_test "Case-insensitive duplicate detection - Happy vs happy"
ensure_tag_exists "Happy"
initial_count=$(sql_fast "SELECT COUNT(*) FROM tags;")

ensure_tag_exists "happy"
final_count=$(sql_fast "SELECT COUNT(*) FROM tags;")

assert_equals "$initial_count" "$final_count" "No duplicate created for case variant"

# Verify both names resolve to the same tag
result=$(get_tag_data "Happy")
parse_tag_data "$result"
happy_canonical="$tag_name"

result=$(get_tag_data "happy")
parse_tag_data "$result"
happy_canonical2="$tag_name"

assert_equals "$happy_canonical" "$happy_canonical2" "Both 'Happy' and 'happy' resolve to same tag"

# Test 2: Create Feelings container with happy as child
begin_test "Create Feelings container"
ensure_tag_exists "Feelings" "container"
result=$(get_tag_data "Feelings")
assert_not_empty "$result" "Feelings container created"
parse_tag_data "$result"
assert_equals "container" "$type" "Feelings is a container"

# Test 3: Add happy as child of Feelings
begin_test "Add happy as child of Feelings"
set_parent "happy" "Feelings"
result=$(get_tag_data "happy")
parse_tag_data "$result"
assert_equals "Feelings" "$parent" "happy parent is Feelings"

# Test 4: Create Emotions container
begin_test "Create Emotions container"
ensure_tag_exists "Emotions" "container"
result=$(get_tag_data "Emotions")
assert_not_empty "$result" "Emotions container created"
parse_tag_data "$result"
assert_equals "container" "$type" "Emotions is a container"

# Test 5: Create and add Sad as child of Emotions
begin_test "Create Sad as child of Emotions"
ensure_tag_exists "Sad" "leaf" "Emotions"
result=$(get_tag_data "Sad")
parse_tag_data "$result"
assert_equals "Emotions" "$parent" "Sad parent is Emotions"
assert_equals "leaf" "$type" "Sad is a leaf tag"

# Test 6: Add unhappy as synonym for sad
begin_test "Add unhappy as synonym for sad"
set_synonym "Sad" "unhappy"
result=$(get_tag_data "unhappy")
assert_not_empty "$result" "unhappy synonym created"
parse_tag_data "$result"
assert_equals "Sad" "$tag_name" "unhappy resolves to Sad"

# Test 7: Combine Feelings and Emotions
begin_test "Combine Feelings and Emotions into Feelings"
combine_tags "Emotions" "Feelings"

# Verify Emotions is deleted
result=$(get_tag_data "Emotions")
assert_empty "$result" "Emotions tag is deleted"

# Test 8: Verify Sad (previously under Emotions) is now under Feelings
begin_test "Verify Sad is now child of Feelings after combine"
result=$(get_tag_data "Sad")
parse_tag_data "$result"
assert_equals "Feelings" "$parent" "Sad parent is now Feelings"

# Test 9: Verify happy is still child of Feelings
begin_test "Verify happy remains child of Feelings"
result=$(get_tag_data "happy")
parse_tag_data "$result"
assert_equals "Feelings" "$parent" "happy parent is still Feelings"

# Test 10: Verify unhappy still works as synonym for Sad
begin_test "Verify unhappy synonym still works after combine"
result=$(get_tag_data "unhappy")
assert_not_empty "$result" "unhappy synonym still works"
parse_tag_data "$result"
assert_equals "Sad" "$tag_name" "unhappy still resolves to Sad"

# Test 11: Verify both happy and Sad are children of Feelings
begin_test "Verify both Happy and Sad are children of Feelings"
children=$(get_tag_children "Feelings")

# Check that Happy (canonical form) is a child
if echo "$children" | grep -q "Happy"; then
  assert_true "true" "Happy is a child of Feelings"
else
  assert_true "false" "Happy is a child of Feelings"
fi

# Check that Sad is a child
if echo "$children" | grep -q "Sad"; then
  assert_true "true" "Sad is a child of Feelings"
else
  assert_true "false" "Sad is a child of Feelings"
fi

# Test 12: Verify long_name was updated when Sad was reparented
begin_test "Verify Sad's long_name reflects new parent (Feelings|Sad)"
result=$(get_tag_data "Sad")
parse_tag_data "$result"
assert_equals "Feelings|Sad" "$long_name" "Sad's long_name correctly updated to Feelings|Sad"

# Test 13: Verify Happy's long_name still reflects original parent
begin_test "Verify Happy's long_name reflects parent (Feelings|Happy)"
result=$(get_tag_data "Happy")
parse_tag_data "$result"
assert_equals "Feelings|Happy" "$long_name" "Happy's long_name is Feelings|Happy"

finish_test_suite
exit $?