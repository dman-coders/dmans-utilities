#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
# Source the library to initialize the database
source "$SCRIPT_DIR/../process_media.lib"
source "$SCRIPT_DIR/fixtures/setup_standard_data.sh"

echo "Testing parent-child relationships..."

# Drop the database to start fresh
drop_database
# Create a new database
create_database

# Use standard test fixtures
setup_standard_world

# Display the hierarchy
echo "Displaying the tag hierarchy:"
dump_tags

echo ""
echo "Testing complete."