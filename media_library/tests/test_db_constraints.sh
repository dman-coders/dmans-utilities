#!/usr/bin/env bash


# Source the library to initialize the database
source process_media.lib

echo "Testing database constraints..."

# Test 1: Try to insert a tag with a non-existent type (should fail)
echo "Test 1: Inserting a tag with non-existent type..."
SQL="PRAGMA foreign_keys = ON; INSERT INTO tags (name, type) VALUES ('test_tag', 'non_existent_type');"
if echo "$SQL" | sqlite3 "$MEDIA_DB" 2>/dev/null; then
  echo "FAIL: Inserted a tag with non-existent type, but should have failed"
else
  echo "PASS: Correctly failed to insert a tag with non-existent type"
fi

# Test 2: Insert a valid tag type, then a tag with that type (should succeed)
echo "Test 2: Inserting a valid tag type and tag..."
SQL="PRAGMA foreign_keys = ON; 
INSERT INTO tag_types (type) VALUES ('test_type');
INSERT INTO tags (name, type) VALUES ('test_tag', 'test_type');"
if echo "$SQL" | sqlite3 "$MEDIA_DB" 2>/dev/null; then
  echo "PASS: Successfully inserted a tag with a valid type"
else
  echo "FAIL: Failed to insert a tag with a valid type"
fi

# Test 3: Try to insert a synonym with a non-existent canonic tag (should fail)
echo "Test 3: Inserting a synonym with non-existent canonic tag..."
SQL="PRAGMA foreign_keys = ON; INSERT INTO synonyms (synonym, canonic) VALUES ('test_synonym', 'non_existent_tag');"
if echo "$SQL" | sqlite3 "$MEDIA_DB" 2>/dev/null; then
  echo "FAIL: Inserted a synonym with non-existent canonic tag, but should have failed"
else
  echo "PASS: Correctly failed to insert a synonym with non-existent canonic tag"
fi

# Test 4: Insert a synonym with a valid canonic tag (should succeed)
echo "Test 4: Inserting a synonym with a valid canonic tag..."
SQL="PRAGMA foreign_keys = ON; INSERT INTO synonyms (synonym, canonic) VALUES ('test_synonym', 'test_tag');"
if echo "$SQL" | sqlite3 "$MEDIA_DB" 2>/dev/null; then
  echo "PASS: Successfully inserted a synonym with a valid canonic tag"
else
  echo "FAIL: Failed to insert a synonym with a valid canonic tag"
fi

# Test 5: Use the set_synonym_for function (should fail with non-existent tag)
echo "Test 5: Using set_synonym_for with non-existent tag..."
if set_synonym_for "non_existent_tag" "another_synonym" 2>/dev/null; then
  echo "FAIL: set_synonym_for succeeded with non-existent tag, but should have failed"
else
  echo "PASS: set_synonym_for correctly failed with non-existent tag"
fi

# Test 6: Use the set_synonym_for function with a valid tag (should succeed)
echo "Test 6: Using set_synonym_for with a valid tag..."
if set_synonym_for "test_tag" "another_synonym" 2>/dev/null; then
  echo "PASS: set_synonym_for succeeded with a valid tag"
else
  echo "FAIL: set_synonym_for failed with a valid tag"
fi

echo "Testing complete."