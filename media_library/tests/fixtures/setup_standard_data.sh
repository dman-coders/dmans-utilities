#!/usr/bin/env bash
# Standard test data fixture
# Creates the consistent world model for all tests

setup_locations_hierarchy() {
  echo "Setting up Locations hierarchy..."

  # Root
  ensure_tag_exists "Locations" "container"
  set_synonym "Locations" "Place"

  # Indoor branch
  ensure_tag_exists "Indoors" "container" "Locations"
  set_synonym "Indoors" "Indoor"
  set_synonym "Indoors" "Inside"

  ensure_tag_exists "Bedroom" "leaf" "Indoors"
  ensure_tag_exists "Kitchen" "leaf" "Indoors"
  ensure_tag_exists "Lounge" "leaf" "Indoors"
  set_synonym "Lounge" "Living Room"
  ensure_tag_exists "House" "leaf" "Indoors"

  # Outdoor branch
  ensure_tag_exists "Outdoor" "container" "Locations"
  set_synonym "Outdoor" "Outside"

  ensure_tag_exists "Park" "leaf" "Outdoor"
}

setup_animal_taxonomy() {
  echo "Setting up Animal taxonomy..."

  # Root
  ensure_tag_exists "Animals" "container"

  # Birds branch
  ensure_tag_exists "Birds" "container" "Animals"
  set_synonym "Birds" "Aves"

  ensure_tag_exists "Eagle" "leaf" "Birds"
  ensure_tag_exists "Penguin" "leaf" "Birds"

  # Mammals branch
  ensure_tag_exists "Mammals" "container" "Animals"

  # Canine
  ensure_tag_exists "Canine" "container" "Mammals"
  ensure_tag_exists "Dog" "leaf" "Canine"
  set_synonym "Dog" "Doggy"

  # Equine
  ensure_tag_exists "Equine" "container" "Mammals"
  ensure_tag_exists "Horse" "leaf" "Equine"

  # Feline
  ensure_tag_exists "Feline" "container" "Mammals"
  ensure_tag_exists "Cat" "leaf" "Feline"
  set_synonym "Cat" "Pussy"
  ensure_tag_exists "Lion" "leaf" "Feline"
  ensure_tag_exists "Tiger" "leaf" "Feline"
}

setup_standard_world() {
  setup_locations_hierarchy
  setup_animal_taxonomy
}
