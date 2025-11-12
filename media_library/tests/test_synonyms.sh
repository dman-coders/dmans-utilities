#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
# Source the library to initialize the database
source "$SCRIPT_DIR/../process_media.lib"
source "$SCRIPT_DIR/fixtures/setup_standard_data.sh"

echo "Testing synonym lookup functionality..."

# Drop the database to start fresh
drop_database

# Create a new database
create_database

# Use standard test fixtures
setup_animal_taxonomy

echo ""
echo "Displaying tags and synonyms:"
dump_tags

echo ""
echo "=== Testing get_tag_data functionality ==="
echo ""

# Test 1: Direct tag name lookup
echo "Test 1: Looking up 'Dog' by direct name..."
result=$(get_tag_data "Dog")
if [[ -n "$result" && "$result" == *"Dog"* ]]; then
  echo "✓ PASS: Found tag 'Dog'"
  echo "  Result: $result"
else
  echo "✗ FAIL: Could not find tag 'Dog'"
  echo "  Result: $result"
fi
echo ""

# Test 2: Lookup via synonym "Doggy" -> should return "Dog"
echo "Test 2: Looking up 'Doggy' (synonym for Dog)..."
result=$(get_tag_data "Doggy")
if [[ -n "$result" && "$result" == *"Dog"* ]]; then
  echo "✓ PASS: Found canonical tag 'Dog' via synonym 'Doggy'"
  echo "  Result: $result"
else
  echo "✗ FAIL: Could not find tag via synonym 'Doggy'"
  echo "  Result: $result"
fi
echo ""

# Test 3: Lookup via synonym "Pussy" -> should return "Cat"
echo "Test 3: Looking up 'Pussy' (synonym for Cat)..."
result=$(get_tag_data "Pussy")
if [[ -n "$result" && "$result" == *"Cat"* ]]; then
  echo "✓ PASS: Found canonical tag 'Cat' via synonym 'Pussy'"
  echo "  Result: $result"
else
  echo "✗ FAIL: Could not find tag via synonym 'Pussy'"
  echo "  Result: $result"
fi
echo ""

# Test 4: Lookup via synonym "Aves" -> should return "Birds"
echo "Test 4: Looking up 'Aves' (synonym for Birds)..."
result=$(get_tag_data "Aves")
if [[ -n "$result" && "$result" == *"Birds"* ]]; then
  echo "✓ PASS: Found canonical tag 'Birds' via synonym 'Aves'"
  echo "  Result: $result"
else
  echo "✗ FAIL: Could not find tag via synonym 'Aves'"
  echo "  Result: $result"
fi
echo ""


# Test 6: Lookup non-existent tag
echo "Test 6: Looking up non-existent tag 'NonExistent'..."
result=$(get_tag_data "NonExistent")
if [[ -z "$result" ]]; then
  echo "✓ PASS: Correctly returned empty result for non-existent tag"
else
  echo "✗ FAIL: Should have returned empty result"
  echo "  Result: $result"
fi
echo ""

# Test 7: Verify parent is returned correctly
echo "Test 7: Verify parent relationship in results..."
result=$(get_tag_data "Dog")
if [[ "$result" == *"Canine"* ]]; then
  echo "✓ PASS: Parent 'Canine' is included in result"
  echo "  Result: $result"
else
  echo "✗ FAIL: Parent 'Canine' not found in result"
  echo "  Result: $result"
fi
echo ""

echo "=== Testing complete ==="
