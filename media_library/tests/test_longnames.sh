#!/usr/bin/env bash

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$TEST_SCRIPT_DIR/test.sqlite"
source "$TEST_SCRIPT_DIR/../process_media.lib"
source "$TEST_SCRIPT_DIR/test_framework.sh"

init_test_suite "Hierarchical Long Names with Pipe Delimiter"

setup_test_db

# Test 1: Create hierarchy using pipe-delimited notation
begin_test "Create hierarchy from pipe-delimited long names"
ensure_tag_exists "Locations|Indoors|Bedroom"
ensure_tag_exists "Locations|Indoors|Kitchen"
ensure_tag_exists "Locations|Indoors|Lounge"
ensure_tag_exists "Locations|Indoors|House"
ensure_tag_exists "Locations|Outdoor|Park"

result=$(get_tag_data "Bedroom")
parse_tag_data "$result"
assert_equals "Indoors" "$parent" "Bedroom parent auto-created and set"
assert_equals "Locations|Indoors|Bedroom" "$long_name" "Bedroom long_name is hierarchical"

# Test 2: Parent tags auto-created
begin_test "Parent tags automatically created from hierarchy"
result=$(get_tag_data "Locations")
assert_not_empty "$result" "Locations tag auto-created"

result=$(get_tag_data "Indoors")
parse_tag_data "$result"
assert_equals "Locations" "$parent" "Indoors parent is Locations"

# Test 3: Synonyms work with hierarchical tags
begin_test "Synonyms can be added to hierarchical tags"
set_synonym "Locations" "Place"
set_synonym "Indoors" "Indoor"
set_synonym "Indoors" "Inside"
set_synonym "Outdoor" "Outside"
set_synonym "Lounge" "Living Room"

result=$(get_tag_data "Place")
parse_tag_data "$result"
assert_equals "Locations" "$tag_name" "Synonym 'Place' resolves to 'Locations'"

# Test 4: Synonym resolution in hierarchical path
begin_test "Synonyms in hierarchical paths resolve to canonical form"
ensure_tag_exists "Locations|Inside|TestRoom"

result=$(get_tag_data "TestRoom")
parse_tag_data "$result"
assert_equals "Indoors" "$parent" "Parent 'Inside' resolved to canonical 'Indoors'"
assert_contains "$long_name" "Indoors" "long_name uses canonical form 'Indoors'"

log_info "Displaying complete tag hierarchy:"
dump_tags

finish_test_suite
exit $?