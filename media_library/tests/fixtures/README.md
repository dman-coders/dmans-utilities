# Test Fixtures

This directory contains the standard test data model used across all tests.

## Standard Data Model

All tests use consistent data defined in `data_model.md`:

### Locations Hierarchy
- Locations (AKA: Place)
  - Indoors (AKA: Indoor, Inside)
    - Bedroom
    - Kitchen
    - Lounge (AKA: Living Room)
    - House
  - Outdoor (AKA: Outside)
    - Park

### Animal Taxonomy
- Animals
  - Birds (AKA: Aves)
    - Eagle
    - Penguin
  - Mammals
    - Canine
      - Dog (AKA: Doggy)
    - Equine
      - Horse
    - Feline
      - Cat (AKA: Pussy)
      - Lion
      - Tiger

## Using the Fixtures

Include the standard fixtures in your test:

```bash
source "$TEST_SCRIPT_DIR/../process_media.lib"
source "$TEST_SCRIPT_DIR/fixtures/setup_standard_data.sh"

# Set up complete world model
setup_standard_world

# Or set up individual hierarchies
setup_locations_hierarchy
setup_animal_taxonomy
```

## Test Files Updated

All test files have been standardized:

1. **test_parent_child.sh** - Tests parent-child relationships using both hierarchies
2. **test_synonyms.sh** - Tests synonym lookup using Animal Taxonomy
3. **test_longnames.sh** - Tests pipe-delimited long names with Locations
4. **test_pipe_in_names.sh** - Tests pipe character handling with Locations
5. **test_update_hierarchy.sh** - Tests hierarchy updates with both models
