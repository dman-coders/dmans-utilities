#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
source "$SCRIPT_DIR/../process_media.lib"
source "$SCRIPT_DIR/test_framework.sh"

init_test_suite "Database Foreign Key Constraints"

setup_test_db

# Test 1: Reject tag with non-existent type
begin_test "Reject tag with non-existent type"
SQL="PRAGMA foreign_keys = ON; INSERT INTO tags (name, type) VALUES ('test_tag', 'non_existent_type');"
if echo "$SQL" | sqlite3 "$MEDIA_DB" 2>/dev/null; then
  assert_true "false" "Should have rejected non-existent type"
else
  assert_true "true" "Correctly rejected non-existent type"
fi

# Test 2: Accept tag with valid type
begin_test "Accept tag with valid type"
SQL="PRAGMA foreign_keys = ON;
INSERT INTO tag_types (type) VALUES ('test_type');
INSERT INTO tags (name, type) VALUES ('test_tag', 'test_type');"
if echo "$SQL" | sqlite3 "$MEDIA_DB" 2>/dev/null; then
  assert_true "true" "Successfully inserted tag with valid type"
else
  assert_true "false" "Should have accepted valid type"
fi

# Test 3: Reject synonym with non-existent canonical tag
begin_test "Reject synonym with non-existent canonical tag"
SQL="PRAGMA foreign_keys = ON; INSERT INTO synonyms (synonym, canonic) VALUES ('test_synonym', 'non_existent_tag');"
if echo "$SQL" | sqlite3 "$MEDIA_DB" 2>/dev/null; then
  assert_true "false" "Should have rejected non-existent canonical tag"
else
  assert_true "true" "Correctly rejected non-existent canonical tag"
fi

# Test 4: Accept synonym with valid canonical tag
begin_test "Accept synonym with valid canonical tag"
SQL="PRAGMA foreign_keys = ON; INSERT INTO synonyms (synonym, canonic) VALUES ('test_synonym', 'test_tag');"
if echo "$SQL" | sqlite3 "$MEDIA_DB" 2>/dev/null; then
  assert_true "true" "Successfully inserted synonym with valid canonical tag"
else
  assert_true "false" "Should have accepted valid canonical tag"
fi

# Test 5: set_synonym requires existing canonical tag
begin_test "set_synonym requires existing canonical tag"
if set_synonym "non_existent_canonical" "another_synonym" 2>/dev/null; then
  assert_true "false" "set_synonym should require existing canonical tag"
else
  assert_true "true" "set_synonym correctly requires existing canonical tag"
fi

# Test 6: set_synonym works with existing tag
begin_test "set_synonym works with existing tag"
if set_synonym "test_tag" "yet_another_synonym" 2>/dev/null; then
  assert_true "true" "set_synonym succeeded with existing tag"
else
  assert_true "false" "set_synonym should work with existing tag"
fi

finish_test_suite
exit $?