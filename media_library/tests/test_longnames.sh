#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
# Source the library to initialize the database
source "$SCRIPT_DIR/../process_media.lib"

echo "Testing hierarchical long names with pipe delimiter..."

# Drop the database to start fresh
drop_database

# Create a new database
create_database

# Create a hierarchy of tags using pipe-delimited long names
echo "Creating hierarchy using long names (Locations|Parent|Child format)..."

# Create tags using longnames - the hierarchy will be auto-created
ensure_tag_exists "Locations|Indoors|Bedroom"
ensure_tag_exists "Locations|Indoors|Kitchen"
ensure_tag_exists "Locations|Indoors|Lounge"
ensure_tag_exists "Locations|Indoors|House"
ensure_tag_exists "Locations|Outdoor|Park"

# Add synonyms to match standard model
set_synonym "Locations" "Place"
set_synonym "Indoors" "Indoor"
set_synonym "Indoors" "Inside"
set_synonym "Outdoor" "Outside"
set_synonym "Lounge" "Living Room"

echo ""
echo "Testing synonym resolution in long names..."
echo "This should resolve the synonym from Inside->Indoors before saving as canonical longname."
# This should resolve the synonym from Inside->Indoors before saving it as a canonical longname.
ensure_tag_exists "Locations|Inside|TestRoom"

# Display the hierarchy
echo ""
echo "Displaying the tag hierarchy:"
dump_tags

echo ""
echo "Testing complete."