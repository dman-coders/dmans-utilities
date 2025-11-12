#!/bin/bash

# Source the library to initialize the database
source process_media.lib

echo "Testing ensure_tag_exists and set_synonym_for functions..."

# Test 1: Use ensure_tag_exists directly
echo "Test 1: Using ensure_tag_exists for a new tag..."
ensure_tag_exists "new_test_tag"

# Verify the tag was created
SQL="SELECT name, type FROM tags WHERE name='new_test_tag';"
result=$(echo "$SQL" | sqlite3 "$MEDIA_DB")
if [ -n "$result" ]; then
  echo "PASS: Tag 'new_test_tag' was created successfully"
  echo "Result: $result"
else
  echo "FAIL: Tag 'new_test_tag' was not created"
fi

# Test 2: Use ensure_tag_exists with a custom type
echo "Test 2: Using ensure_tag_exists with a custom type..."
# First, create the custom type
SQL="INSERT INTO tag_types (type) VALUES ('custom_type');"
echo "$SQL" | sqlite3 "$MEDIA_DB"

ensure_tag_exists "custom_type_tag" "custom_type"

# Verify the tag was created with the custom type
SQL="SELECT name, type FROM tags WHERE name='custom_type_tag';"
result=$(echo "$SQL" | sqlite3 "$MEDIA_DB")
if [ -n "$result" ]; then
  echo "PASS: Tag 'custom_type_tag' was created successfully with custom type"
  echo "Result: $result"
else
  echo "FAIL: Tag 'custom_type_tag' was not created"
fi

# Test 3: Use set_synonym_for with a new tag
echo "Test 3: Using set_synonym_for with a new tag..."
set_synonym_for "another_new_tag" "synonym_for_new_tag"

# Verify the tag was created
SQL="SELECT name FROM tags WHERE name='another_new_tag';"
result=$(echo "$SQL" | sqlite3 "$MEDIA_DB")
if [ -n "$result" ]; then
  echo "PASS: Tag 'another_new_tag' was created automatically by set_synonym_for"
else
  echo "FAIL: Tag 'another_new_tag' was not created"
fi

# Verify the synonym was created
SQL="SELECT synonym, canonic FROM synonyms WHERE synonym='synonym_for_new_tag';"
result=$(echo "$SQL" | sqlite3 "$MEDIA_DB")
if [ -n "$result" ]; then
  echo "PASS: Synonym 'synonym_for_new_tag' was created successfully"
  echo "Result: $result"
else
  echo "FAIL: Synonym 'synonym_for_new_tag' was not created"
fi


ensure_tag_exists mammal container
ensure_tag_exists feline container mammal
ensure_tag_exists cat leaf feline
ensure_tag_exists lion leaf feline
ensure_tag_exists canine container mammal
ensure_tag_exists wolf leaf canine

echo "Testing complete."