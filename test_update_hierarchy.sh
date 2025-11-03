#!/bin/bash

# Source the library to initialize the database
source process_media.lib

echo "Testing update_tag_hierarchy function..."

# Drop the database to start fresh
drop_database

# Create a new database
create_database

# Create tags with slashes in their names
echo "Creating tags with slashes in their names..."

# Create some tags with slashes
ensure_tag_exists "Location" "container"
ensure_tag_exists "Location/Inside"
ensure_tag_exists "Location/Outside"
ensure_tag_exists "Location/Inside/Bedroom" "leaf"
ensure_tag_exists "Location/Inside/Kitchen" "leaf"
ensure_tag_exists "Location/Outside/Garden" "leaf"
ensure_tag_exists "Animals/Mammals/Dog" "leaf"
ensure_tag_exists "Animals/Mammals/Cat" "leaf"
set_synonym_for "Animals/Mammals/Cat" "pussy"
ensure_tag_exists "Animals/Mammals/squirrel"
ensure_tag_exists "Animals/Mammals/Bear"

ensure_tag_exists "Animals/Birds/Eagle" "leaf"
set_synonym_for "Animals/Birds/Eagle" "falcon"

# Create some tags without slashes
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
SQL="SELECT name FROM tags WHERE name IN ('Location', 'Animals', 'Animals/Mammals', 'Animals/Birds', 'Location/Inside', 'Location/Outside');"
echo "$SQL" | sqlite3 "$MEDIA_DB"

echo "Testing complete."