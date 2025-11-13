#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
# Source the library to initialize the database
source "$SCRIPT_DIR/../process_media.lib"

# Should make tags, avoid making duplicates, and deal with synonyms and hierarchical names
log_notice "Testing ensure_tag_exists and set_synonym functions..."

# Test 1: Use ensure_tag_exists directly
log_notice "Test 1: Using ensure_tag_exists for a new tag..."
ensure_tag_exists "new_test_tag"

# Verify the tag was created
SQL="SELECT name, type FROM tags WHERE name='new_test_tag';"
result=$(echo "$SQL" | sqlite3 "$MEDIA_DB")
if [ -n "$result" ]; then
  log_notice "PASS: Tag 'new_test_tag' was created successfully"
  log_notice "Result: $result"
else
  log_error "FAIL: Tag 'new_test_tag' was not created"
fi

# Test 2: Use ensure_tag_exists with a custom type
log_notice "Test 2: Using ensure_tag_exists with a custom type..."
# First, create the custom type
SQL="INSERT INTO tag_types (type) VALUES ('custom_type');"
echo "$SQL" | sqlite3 "$MEDIA_DB" || log_error $SQL

ensure_tag_exists "custom_type_tag" "custom_type"

# Verify the tag was created with the custom type
SQL="SELECT name, type FROM tags WHERE name='custom_type_tag';"
result=$(echo "$SQL" | sqlite3 "$MEDIA_DB")
if [ -n "$result" ]; then
  log_notice "PASS: Tag 'custom_type_tag' was created successfully with custom type"
  log_notice "Result: $result"
else
  log_error "FAIL: Tag 'custom_type_tag' was not created"
fi

# Test 3: Use set_synonym with a new tag
log_notice "Test 3: Using set_synonym with a new tag..."
set_synonym "another_new_tag" "synonym_for_new_tag"

# Verify the tag was created
SQL="SELECT name FROM tags WHERE name='another_new_tag';"
result=$(echo "$SQL" | sqlite3 "$MEDIA_DB")
if [ -n "$result" ]; then
  log_notice "PASS: Tag 'another_new_tag' was created automatically by set_synonym"
else
  log_error "FAIL: Tag 'another_new_tag' was not created"
fi

# Verify the synonym was created
SQL="SELECT synonym, canonic FROM synonyms WHERE synonym='synonym_for_new_tag';"
result=$(echo "$SQL" | sqlite3 "$MEDIA_DB")
if [ -n "$result" ]; then
  log_notice "PASS: Synonym 'synonym_for_new_tag' was created successfully"
  log_notice "Result: $result"
else
  log_error "FAIL: Synonym 'synonym_for_new_tag' was not created"
fi

# Adding a tag that already exists as a synonym should not create duplicates
log_notice "Test 4: Using ensure_tag_exists on existing synonym doesn't create anything new"
ensure_tag_exists "synonym_for_new_tag"
SQL="SELECT COUNT(*) FROM tags WHERE name='synonym_for_new_tag';"
count=$(echo "$SQL" | sqlite3 "$MEDIA_DB")
if [ "$count" -eq 1 ]; then
  log_notice "PASS: No duplicate tag created for existing synonym"
else
  error "FAIL: Duplicate tag created for existing synonym"
fi

# Adding a heirarchical tag that matches existing tags should add the structure without duplicates
log_notice "Test 5: Using ensure_tag_exists for hierarchical tags... on a pre-existing short name"
ensure_tag_exists "TagTypes|another_new_tag"
tag_data=$(get_tag_data "another_new_tag")
IFS="${DB_DELIMITER}" read -r tag_name long_name type parent <<< "$tag_data"
if [[ "$long_name" == "TagTypes|another_new_tag" && "$parent" == "TagTypes" ]]; then
  echo "PASS: Hierarchical tag structure created successfully"
else
  echo "FAIL: Hierarchical tag structure not created as expected"
fi


ensure_tag_exists Animals container
ensure_tag_exists mammal container Animals
ensure_tag_exists feline container mammal
ensure_tag_exists cat leaf feline
ensure_tag_exists lion leaf feline
ensure_tag_exists canine container mammal
ensure_tag_exists wolf leaf canine

echo "Testing complete."