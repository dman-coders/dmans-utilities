#!/bin/bash

# Source the library to initialize the database
source process_media.lib

echo "Testing parent-child relationships..."

# Drop the database to start fresh
drop_database

# Create a new database
create_database

# Create a hierarchy of tags
echo "Creating a hierarchy of tags..."

# Create root tags
ensure_tag_exists "Animals" "container"
ensure_tag_exists "Plants" "container"
ensure_tag_exists "Locations" "container"

# Create child tags for Animals
ensure_tag_exists "Mammals" "container" "Animals"
ensure_tag_exists "Birds" "container" "Animals"
ensure_tag_exists "Fish" "container" "Animals"

# Create child tags for Mammals
ensure_tag_exists "Dog" "leaf" "Mammals"
ensure_tag_exists "Cat" "leaf" "Mammals"
ensure_tag_exists "Horse" "leaf" "Mammals"

# Create child tags for Birds
ensure_tag_exists "Eagle" "leaf" "Birds"
ensure_tag_exists "Penguin" "leaf" "Birds"

# Create child tags for Plants
ensure_tag_exists "Trees" "container" "Plants"
ensure_tag_exists "Flowers" "container" "Plants"

# Create child tags for Trees
ensure_tag_exists "Oak" "leaf" "Trees"
ensure_tag_exists "Pine" "leaf" "Trees"

# Create child tags for Locations
ensure_tag_exists "Indoor" "container" "Locations"
ensure_tag_exists "Outdoor" "container" "Locations"

# Create synonyms for some tags
set_synonym_for "Dog" "Canine"
set_synonym_for "Cat" "Feline"
set_synonym_for "Horse" "Equine"
set_synonym_for "Oak" "Oak Tree"
set_synonym_for "Indoor" "Inside"
set_synonym_for "Outdoor" "Outside"

# Display the hierarchy
echo "Displaying the tag hierarchy:"
dump_tags

echo "Testing complete."