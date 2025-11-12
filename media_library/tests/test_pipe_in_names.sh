#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
source "$SCRIPT_DIR/../process_media.lib"

echo "Testing tags with pipe characters in names..."

# Drop the database to start fresh
drop_database

# Create a new database
create_database

# Create tags with pipes in the names (using standard Locations model)
echo "Creating tags with | in their names..."
ensure_tag_exists "Locations|Indoors|House" "leaf"
ensure_tag_exists "Locations|Outdoor|Park" "leaf"

echo ""
echo "Looking up 'Locations|Indoors|House'..."
result=$(get_tag_data "Locations|Indoors|House")
echo "Result: $result"

# Parse the result using CSV delimiter
IFS="$DB_DELIMITER" read -r name long_name type parent <<< "$result"
echo "Parsed values:"
echo "  name: $name"
echo "  long_name: $long_name"
echo "  type: $type"
echo "  parent: $parent"

if [[ "$long_name" == "Locations|Indoors|House" ]]; then
  echo "✓ PASS: Pipe character in long_name preserved correctly"
else
  echo "✗ FAIL: Expected 'Locations|Indoors|House', got '$long_name'"
fi

echo ""
echo "Testing complete."
