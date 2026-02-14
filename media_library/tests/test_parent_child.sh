#!/usr/bin/env bash

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$TEST_SCRIPT_DIR/test.sqlite"
source "$TEST_SCRIPT_DIR/../process_media.lib"
source "$TEST_SCRIPT_DIR/test_framework.sh"
source "$TEST_SCRIPT_DIR/fixtures/setup_standard_data.sh"

init_test_suite "Parent-Child Relationships"

# Note that container/leaf labels have little meaning structurally.
# It's supposed to disallow media items being tagged with container tags like 'Location' or 'Style'
# but the enforcement is not strict.

setup_test_db
setup_standard_world

# Test 1: Verify root tags have no parent
begin_test "Root tags have no parent"
result=$(get_tag_data "Animals")
parse_tag_data "$result"
assert_empty "$parent" "Animals has no parent"

result=$(get_tag_data "Locations")
parse_tag_data "$result"
assert_empty "$parent" "Locations has no parent"

# Test 2: Verify container tags have correct parents
begin_test "Container tags have correct parents"
result=$(get_tag_data "Mammals")
parse_tag_data "$result"
assert_equals "Animals" "$parent" "Mammals parent is Animals"
assert_equals "container" "$type" "Mammals is container type"

result=$(get_tag_data "Indoors")
parse_tag_data "$result"
assert_equals "Locations" "$parent" "Indoors parent is Locations"

# Test 3: Verify leaf tags have correct parents
begin_test "Leaf tags have correct parents"
result=$(get_tag_data "Dog")
parse_tag_data "$result"
assert_equals "Canine" "$parent" "Dog parent is Canine"
assert_equals "leaf" "$type" "Dog is leaf type"

result=$(get_tag_data "Kitchen")
parse_tag_data "$result"
assert_equals "Indoors" "$parent" "Kitchen parent is Indoors"

# Test 4: Verify full hierarchy via long_name
begin_test "Full hierarchy reflected in long_name"
result=$(get_tag_data "Dog")
parse_tag_data "$result"
assert_equals "Animals|Mammals|Canine|Dog" "$long_name" "Dog has full hierarchical long_name"

result=$(get_tag_data "Park")
parse_tag_data "$result"
assert_equals "Locations|Outdoor|Park" "$long_name" "Park has full hierarchical long_name"

log_info "Displaying complete tag hierarchy:"
dump_tags

finish_test_suite
exit $?