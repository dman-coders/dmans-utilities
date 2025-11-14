#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
source "$SCRIPT_DIR/../process_media.lib"
source "$SCRIPT_DIR/test_framework.sh"

init_test_suite "ensure_tag_exists and set_synonym Functions"

setup_test_db

# Test 1: Create simple tag with default type
begin_test "Create simple tag with default type"
ensure_tag_exists "new_test_tag"
result=$(get_tag_data "new_test_tag")
assert_not_empty "$result" "Tag 'new_test_tag' was created"
parse_tag_data "$result"
assert_equals "leaf" "$type" "Default type is 'leaf'"

# Test 2: Create tag with custom type
begin_test "Create tag with custom type"
SQL="INSERT INTO tag_types (type) VALUES ('custom_type');"
sql_safe "$SQL"
ensure_tag_exists "custom_type_tag" "custom_type"
result=$(get_tag_data "custom_type_tag")
parse_tag_data "$result"
assert_equals "custom_type" "$type" "Custom type set correctly"

# Test 3: set_synonym works with existing tag
begin_test "set_synonym works when canonical tag exists"
ensure_tag_exists "another_new_tag"
set_synonym "another_new_tag" "synonym_for_new_tag"
result=$(get_tag_data "another_new_tag")
assert_not_empty "$result" "Canonical tag 'another_new_tag' exists"

# Test 4: Synonym resolves to canonical tag
begin_test "Synonym resolves to canonical tag"
result=$(get_tag_data "synonym_for_new_tag")
parse_tag_data "$result"
assert_equals "another_new_tag" "$tag_name" "Synonym resolves to canonical tag"

# Test 5: ensure_tag_exists on synonym uses canonical tag
begin_test "ensure_tag_exists on synonym uses canonical tag"
initial_count=$(sql_fast "SELECT COUNT(*) FROM tags;")
ensure_tag_exists "synonym_for_new_tag"
final_count=$(sql_fast "SELECT COUNT(*) FROM tags;")
assert_equals "$initial_count" "$final_count" "No new tag created, synonym resolved to canonical"

# Verify synonym still points to canonical tag
result=$(get_tag_data "synonym_for_new_tag")
parse_tag_data "$result"
assert_equals "another_new_tag" "$tag_name" "Synonym still resolves to canonical tag"

# Test 6: Hierarchical tag adds structure to existing tag
begin_test "Hierarchical notation adds structure to existing tag"
ensure_tag_exists "TagTypes|another_new_tag"
tag_data=$(get_tag_data "another_new_tag")
parse_tag_data "$tag_data"
assert_equals "TagTypes|another_new_tag" "$long_name" "long_name updated with hierarchy"
assert_equals "TagTypes" "$parent" "Parent set correctly"

# Test 7: Create multi-level hierarchy
begin_test "Create multi-level hierarchy with parent relationships"
ensure_tag_exists "Animals" "container"
ensure_tag_exists "mammal" "container" "Animals"
ensure_tag_exists "feline" "container" "mammal"
ensure_tag_exists "cat" "leaf" "feline"
ensure_tag_exists "lion" "leaf" "feline"
ensure_tag_exists "canine" "container" "mammal"
ensure_tag_exists "wolf" "leaf" "canine"

result=$(get_tag_data "wolf")
parse_tag_data "$result"
assert_equals "canine" "$parent" "wolf parent is canine"
assert_contains "$long_name" "Animals" "wolf long_name contains root"

finish_test_suite
exit $?