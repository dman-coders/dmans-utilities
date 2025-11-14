#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
source "$SCRIPT_DIR/../process_media.lib"
source "$SCRIPT_DIR/test_framework.sh"
source "$SCRIPT_DIR/fixtures/setup_standard_data.sh"

init_test_suite "Synonym Lookup Functionality"

setup_test_db
setup_animal_taxonomy

log_info "Displaying tags and synonyms for reference:"
dump_tags

# Test 1: Direct tag name lookup
begin_test "Direct tag name lookup for 'Dog'"
result=$(get_tag_data "Dog")
assert_not_empty "$result" "Found tag 'Dog'"
assert_contains "$result" "Dog" "Result contains 'Dog'"

# Test 2: Lookup via synonym "Doggy" -> should return "Dog"
begin_test "Lookup via synonym 'Doggy' returns canonical 'Dog'"
result=$(get_tag_data "Doggy")
assert_not_empty "$result" "Found tag via synonym 'Doggy'"
assert_contains "$result" "Dog" "Result contains canonical tag 'Dog'"

# Test 3: Lookup via synonym "Pussy" -> should return "Cat"
begin_test "Lookup via synonym 'Pussy' returns canonical 'Cat'"
result=$(get_tag_data "Pussy")
assert_not_empty "$result" "Found tag via synonym 'Pussy'"
assert_contains "$result" "Cat" "Result contains canonical tag 'Cat'"

# Test 4: Lookup via synonym "Aves" -> should return "Birds"
begin_test "Lookup via synonym 'Aves' returns canonical 'Birds'"
result=$(get_tag_data "Aves")
assert_not_empty "$result" "Found tag via synonym 'Aves'"
assert_contains "$result" "Birds" "Result contains canonical tag 'Birds'"

# Test 5: Lookup via synonym "Mare" -> should return "Horse"
begin_test "Lookup via synonym 'Mare' returns canonical 'Horse'"
result=$(get_tag_data "Mare")
assert_not_empty "$result" "Found tag via synonym 'Mare'"
assert_contains "$result" "Horse" "Result contains canonical tag 'Horse'"

# Test 6: Lookup non-existent tag
begin_test "Lookup non-existent tag returns empty"
result=$(get_tag_data "NonExistent")
assert_empty "$result" "Non-existent tag returns empty result"

# Test 7: Verify parent is returned correctly
begin_test "Parent relationship included in tag data"
result=$(get_tag_data "Dog")
assert_contains "$result" "Canine" "Parent 'Canine' is included in result"

finish_test_suite
exit $?
