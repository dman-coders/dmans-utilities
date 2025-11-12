# Media Library Tests

Test suite for media_library utilities.

## Structure

```
tests/
├── README.md                      # This file
├── fixtures/                      # Test data files
│   └── test-image.jpg            # Sample image with tags (auto-generated)
├── create-sample-tagged-file.sh  # Create test images with tags
└── test-process-tags-to-db.sh    # Test tag extraction and DB population
```

## Running Tests

### Test process-tags-to-db
```bash
cd media_library/tests
./test-process-tags-to-db.sh

```

This test:
1. Creates a test image with various tag types (if not exists)
2. Runs process-tags-to-db on the test file
3. Verifies tags are extracted and stored in database
4. Shows the resulting tag hierarchy

### Create Custom Test Fixtures

Use `create-sample-tagged-file.sh` to generate test files:
```bash
./create-sample-tagged-file.sh
```

This creates a temporary test file with:
- Simple flat tags (Subject, Keywords)
- Hierarchical tags (Location/Inside/Bedroom, Location/Outside/Garden)
- Categories

## Fixtures

Test fixtures are stored in `fixtures/` directory and committed to git for consistent testing.

### Current Fixtures

- **test-image.jpg** - 1x1 pixel JPEG with sample tags:
  - Subject: TestTag
  - Keywords: Simple, Flat, Tags
  - HierarchicalSubject: Location|Inside|Bedroom, Location|Outside|Garden
  - Categories: Category1

## Adding New Tests

1. Create test script: `test-<utility-name>.sh`
2. Follow the pattern in existing tests
3. Use fixtures from `fixtures/` directory or create new ones
4. Add test description to this README

## Test Conventions

- Test scripts should be idempotent (can be run multiple times)
- Use fixtures/ for reusable test data
- Clean up temp files after tests
- Exit with 0 on success, non-zero on failure
- Use colored output for readability
