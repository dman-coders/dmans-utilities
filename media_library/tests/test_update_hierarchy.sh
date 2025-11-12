#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
# Source the library to initialize the database
source "$SCRIPT_DIR/../process_media.lib"

echo "Testing update_tag_hierarchy function..."

# Drop the database to start fresh
drop_database

# Create a new database
create_database

# Create tags with pipe delimiters in their names (using standard model)
echo "Creating tags with pipe delimiters in their names..."

# Locations hierarchy with pipe notation
ensure_tag_exists "Locations|Indoors|Bedroom" "leaf"
ensure_tag_exists "Locations|Indoors|Kitchen" "leaf"
ensure_tag_exists "Locations|Indoors|Lounge" "leaf"
ensure_tag_exists "Locations|Outdoor|Park" "leaf"

# Animal taxonomy with pipe notation
ensure_tag_exists "Animals|Mammals|Canine|Dog" "leaf"
set_synonym "Animals|Mammals|Canine|Dog" "Doggy"
ensure_tag_exists "Animals|Mammals|Feline|Cat" "leaf"
set_synonym "Animals|Mammals|Feline|Cat" "Pussy"
ensure_tag_exists "Animals|Mammals|Feline|Lion" "leaf"
ensure_tag_exists "Animals|Mammals|Equine|Horse" "leaf"
ensure_tag_exists "Animals|Birds|Eagle" "leaf"
ensure_tag_exists "Animals|Birds|Penguin" "leaf"
set_synonym "Animals|Birds" "Aves"

# Create some tags without delimiters
ensure_tag_exists "Person" "container"
ensure_tag_exists "Event" "container"

# Display the initial hierarchy
echo "Initial tag hierarchy (before update_tag_hierarchy):"
dump_tags

# Check the current parent values
echo "Checking current parent values..."
SQL="SELECT name, parent FROM tags WHERE name LIKE '%/%';"
echo "$SQL" | sqlite3 "$MEDIA_DB"

# Run the update_tag_hierarchy function
echo "Running update_tag_hierarchy..."
update_tag_hierarchy

# Check the updated parent values
echo "Checking updated parent values..."
SQL="SELECT name, parent FROM tags WHERE name LIKE '%/%';"
echo "$SQL" | sqlite3 "$MEDIA_DB"

# Verify that parent tags exist
echo "Verifying that parent tags exist..."
SQL="SELECT name FROM tags WHERE name IN ('Locations', 'Animals', 'Animals|Mammals', 'Animals|Birds', 'Locations|Indoors', 'Locations|Outdoor', 'Animals|Mammals|Canine', 'Animals|Mammals|Feline');"
echo "$SQL" | sqlite3 "$MEDIA_DB"

echo ""
echo "Testing complete."