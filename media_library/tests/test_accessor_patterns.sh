#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
source "$SCRIPT_DIR/../process_media.lib"
source "$SCRIPT_DIR/fixtures/setup_standard_data.sh"

echo "Testing different accessor patterns for tag data..."

# Setup
drop_database
create_database
setup_animal_taxonomy

echo ""
echo "=== Pattern 1: Traditional two-line approach (current) ==="
echo ""

tag_data=$(get_tag_data "Dog")
IFS="${DB_DELIMITER}" read -r tag_name long_name type parent <<< "$tag_data"

echo "Using Dog tag:"
echo "  name: $tag_name"
echo "  long_name: $long_name"
echo "  type: $type"
echo "  parent: $parent"

echo ""
echo "=== Pattern 2: Associative array (recommended for multiple fields) ==="
echo ""

get_tag_info "Cat"
echo "Using Cat tag:"
echo "  name: ${tag_info[name]}"
echo "  long_name: ${tag_info[long_name]}"
echo "  type: ${tag_info[type]}"
echo "  parent: ${tag_info[parent]}"

echo ""
echo "=== Pattern 3: Individual accessor functions (best for single values) ==="
echo ""

echo "Using Horse tag:"
echo "  name: $(get_tag_name 'Horse')"
echo "  long_name: $(get_long_name 'Horse')"
echo "  type: $(get_tag_type 'Horse')"
echo "  parent: $(get_parent 'Horse')"

# Verify the helper functions work as intended
echo "  From longname: name: $(get_tag_name 'Animals|Mammals|Equine|Horse')"
echo "  From synonym: name: $(get_tag_name 'Horsey')"


echo ""
echo "=== Pattern 4: Helper function with global variables ==="
echo ""

parse_tag_data "$(get_tag_data 'Lion')"
echo "Using Lion tag:"
echo "  name: $tag_name"
echo "  long_name: $long_name"
echo "  type: $type"
echo "  parent: $parent"

echo ""
echo "=== Demonstrating Scope Issue ==="
echo ""


echo ""
echo "=== Pattern Comparison ==="
echo ""

echo "Pattern 1 (parsing explicitly after fetching data):"
echo "  Pros: Clear, explicit, works everywhere"
echo "  Cons: Verbose, repetitive"
echo "  Use when: You need all 4 fields"
echo ""

echo "Pattern 2 (Associative Array):"
echo "  Pros: Clean syntax, single lookup, feels like data structure"
echo "  Cons: Requires bash 4+, global variable"
echo "  Use when: You need multiple fields, modern bash environment"
echo ""

echo "Pattern 3 (Individual Functions):"
echo "  Pros: Clear intent, shell-agnostic, simple"
echo "  Cons: Multiple DB queries if you need all fields"
echo "  Use when: You only need 1-2 specific fields"
echo ""


echo "Pattern 4 (Helper with Global Variables):"
echo "  Pros: Still explicit, slightly cleaner than Pattern 1"
echo "  Cons: Global variable pollution, requires two function calls"
echo "  Use when: You want Pattern 1 but slightly cleaner"

echo ""
echo "=== Scope Rules Summary ==="
echo "1. Variables in functions are local BY DEFAULT when using 'local'"
echo "2. Variables in functions WITHOUT 'local' are GLOBAL (available to caller)"
echo "3. Variables set in YOUR SCRIPT (not in a function) are always available"
echo "4. Command substitution \$(func) creates a subshell - can only return via stdout"

echo ""
echo "Testing complete."
