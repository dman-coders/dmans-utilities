#!/usr/bin/env bash

# Test suite for process-tags-to-db

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$(realpath $(dirname "${BASH_SOURCE[0]}")/test.sqlite)"
source "$SCRIPT_DIR/../process_media.lib"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

log_notice  "Testing process-tags-to-db"

# Ensure fixtures directory exists
mkdir -p "$FIXTURES_DIR"
# Drop the database to start fresh
drop_database
# Create a new database
create_database


# Create test fixture if it doesn't exist
FIXTURES_LIST=$("$SCRIPT_DIR/test_create_fixtures.sh")

# Count initial tags
initial_count=$(echo "SELECT COUNT(*) FROM tags;" | sqlite3 "$MEDIA_DB")
log_notice "Initial tag count in db: $initial_count"

for TESTFILE in $FIXTURES_LIST; do
  log_info "Using fixture: $TESTFILE"

  log_info "Fixture tags:"
  exiftool -Subject -Keywords -HierarchicalSubject -Categories "$TESTFILE" | log_notice

  # Run the test
  log_notice "Running process-tags-to-db..."
  cd "$PARENT_DIR"
  ./process-tags-to-db "$TESTFILE"
  RESULT=$?

  if [[ $RESULT -eq 0 ]]; then
      log_notice "✓ Test completed successfully"
  else
      log_error "✗ Test failed with exit code $RESULT"
  fi

done

# Count final tags
final_count=$(echo "SELECT COUNT(*) FROM tags;" | sqlite3 "$MEDIA_DB")
new_tags=$((final_count - initial_count))

log_notice "========================================="
log_notice "Processing complete!"
log_notice "Initial tags: $initial_count"
log_notice "Final tags: $final_count"
log_notice "New tags added: $new_tags"
log_notice "========================================="

# Show the tag hierarchy
if [[ $new_tags -gt 0 ]]; then
    log_notice ""
    log_notice "Tag hierarchy:"
    dump_tags
fi

exit $RESULT
