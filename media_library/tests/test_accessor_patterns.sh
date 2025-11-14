#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
source "$SCRIPT_DIR/../process_media.lib"
source "$SCRIPT_DIR/test_framework.sh"
source "$SCRIPT_DIR/fixtures/setup_standard_data.sh"

init_test_suite "Data Accessor Patterns (Demo)"

setup_test_db
setup_animal_taxonomy

# Pattern 1: Traditional two-line approach
begin_test "Pattern 1: Traditional two-line approach"
tag_data=$(get_tag_data "Dog")
IFS="${DB_DELIMITER}" read -r tag_name long_name type parent <<< "$tag_data"
log_info "  name: $tag_name, long_name: $long_name, type: $type, parent: $parent"
assert_equals "Dog" "$tag_name" "Pattern 1 correctly retrieves tag name"
assert_equals "Canine" "$parent" "Pattern 1 correctly retrieves parent"

# Pattern 2: Associative array
begin_test "Pattern 2: Associative array (bash 4+)"
get_tag_info "Cat"
log_info "  name: ${tag_info[name]}, parent: ${tag_info[parent]}"
assert_equals "Cat" "${tag_info[name]}" "Pattern 2 correctly retrieves tag name"
assert_equals "Feline" "${tag_info[parent]}" "Pattern 2 correctly retrieves parent"

# Pattern 3: Individual accessor functions
begin_test "Pattern 3: Individual accessor functions"
horse_name=$(get_tag_name 'Horse')
horse_parent=$(get_parent 'Horse')
log_info "  name: $horse_name, parent: $horse_parent"
assert_equals "Horse" "$horse_name" "Pattern 3 retrieves tag name"
assert_equals "Equine" "$horse_parent" "Pattern 3 retrieves parent"

# Test accessor functions with different input types
begin_test "Pattern 3: Accessor functions work with long names"
name_from_long=$(get_tag_name 'Animals|Mammals|Equine|Horse')
assert_equals "Horse" "$name_from_long" "get_tag_name works with long name"

begin_test "Pattern 3: Accessor functions work with synonyms"
name_from_synonym=$(get_tag_name 'Mare')
assert_equals "Horse" "$name_from_synonym" "get_tag_name works with synonym"

# Pattern 4: Helper with global variables
begin_test "Pattern 4: Helper with global variables"
parse_tag_data "$(get_tag_data 'Lion')"
log_info "  name: $tag_name, long_name: $long_name, type: $type, parent: $parent"
assert_equals "Lion" "$tag_name" "Pattern 4 correctly parses tag name"
assert_equals "Feline" "$parent" "Pattern 4 correctly parses parent"

log_info ""
log_info "Pattern Recommendations:"
log_info "  Pattern 1: Clear, explicit - use when you need all 4 fields"
log_info "  Pattern 2: Clean syntax - use for multiple fields in bash 4+"
log_info "  Pattern 3: Simple - use when you only need 1-2 fields"
log_info "  Pattern 4: Slightly cleaner than 1 - use for readability"

finish_test_suite
exit $?
