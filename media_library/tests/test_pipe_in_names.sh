#!/usr/bin/env bash

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$TEST_SCRIPT_DIR/test.sqlite"
source "$TEST_SCRIPT_DIR/../process_media.lib"
source "$TEST_SCRIPT_DIR/test_framework.sh"

init_test_suite "Pipe Characters in Tag Names"

setup_test_db

# Test 1: Create hierarchical tags with pipe notation
begin_test "Create tags with pipe-delimited hierarchical names"
ensure_tag_exists "Locations|Indoors|House" "leaf"
ensure_tag_exists "Locations|Outdoor|Park" "leaf"
result=$(get_tag_data "Locations|Indoors|House")
assert_not_empty "$result" "Tag created successfully"

# Test 2: Verify pipe character preserved in long_name
begin_test "Pipe characters preserved in long_name field"
IFS="$DB_DELIMITER" read -r name long_name type parent <<< "$result"
assert_equals "Locations|Indoors|House" "$long_name" "long_name preserves pipe delimiters"
assert_equals "House" "$name" "name is short form"
assert_equals "Indoors" "$parent" "parent correctly set"

# Test 3: Simple tag expanded with hierarchical long_name
# I first create "Jungle" tag, then later process a tag that specifies its full hierarchy.
# The heritage should be applied to the simple tag.
begin_test "Simple tag can be expanded with hierarchical long_name"
ensure_tag_exists "Jungle"
tag_data=$(get_tag_data "Jungle")
parse_tag_data "$tag_data"
initial_long_name="$long_name"
log_info "  Initial long_name: $initial_long_name"

# Add synonym to test merging behavior
# To confuse things, the new structure uses a different word in the middle,
# but if the parent "Outdoor" is a synonym for "Outdoors", this will be managed.
set_synonym "Outdoor" "Outdoors"

# Expand with hierarchical info - should merge via synonym resolution
ensure_tag_exists "Locations|Outdoors|Jungle"
tag_data=$(get_tag_data "Jungle")
parse_tag_data "$tag_data"
log_info "  Expanded long_name: $long_name"

assert_contains "$long_name" "Locations" "long_name contains Locations"
assert_contains "$long_name" "Jungle" "long_name contains Jungle"
assert_equals "Outdoor" "$parent" "parent resolved via synonym to canonical form"

finish_test_suite
exit $?
