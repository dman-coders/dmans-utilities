#!/usr/bin/env bash

# Test suite for process-tags-to-db

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Ensure fixtures directory exists
mkdir -p "$FIXTURES_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Initializing fixtures"
echo "========================================="
echo ""
JPEG_DATA='\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01\x01\x01\x00\x48\x00\x48\x00\x00\xFF\xDB\x00\x43\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xC0\x00\x0B\x08\x00\x01\x00\x01\x01\x01\x11\x00\xFF\xC4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x08\x01\x01\x00\x00\x3F\x00\x7F\xFF\xD9'

# Create test fixture if it doesn't exist
TESTFILE="$FIXTURES_DIR/test-image.jpg"
if [[ ! -f "$TESTFILE" ]]; then
    echo "Creating test fixture..."
    # Create a minimal JPEG (1x1 pixel)
    echo -n -e "$JPEG_DATA" > "$TESTFILE"

    # Add various tags using exiftool
    exiftool -overwrite_original \
      -Subject="TestTag" \
      -Keywords="Simple, Flat, Tags" \
      -HierarchicalSubject="Location|Inside|Bedroom" \
      -HierarchicalSubject="Location|Outside|Garden" \
      -Categories="Category1" \
      "$TESTFILE" >/dev/null 2>&1

    echo -e "${GREEN}✓${NC} Test fixture created: $TESTFILE"
else
    echo -e "${GREEN}✓${NC} Using existing fixture: $TESTFILE"
fi

TESTFILE="$FIXTURES_DIR/dog.jpg"
if [[ ! -f "$TESTFILE" ]]; then
    echo "Creating test fixture $TESTFILE..."
    echo -n -e "$JPEG_DATA" > "$TESTFILE"
    # Add various tags using exiftool
    exiftool -overwrite_original \
      -Subject="A Dog" \
      -Keywords="Dog" \
      -HierarchicalSubject="Animals|Mammals|Canine|Dog" \
      "$TESTFILE" >/dev/null 2>&1
else
    echo -e "${GREEN}✓${NC} Using existing fixture: $TESTFILE"
fi

TESTFILE="$FIXTURES_DIR/cat.jpg"
if [[ ! -f "$TESTFILE" ]]; then
    echo "Creating test fixture $TESTFILE..."
    echo -n -e "$JPEG_DATA" > "$TESTFILE"
    # Add various tags using exiftool
    exiftool -overwrite_original \
      -Subject="A Cat" \
      -Keywords="Cat, Pussy" \
      -HierarchicalSubject="Animals|Mammals|Feline|Cat" \
      "$TESTFILE" >/dev/null 2>&1
else
    echo -e "${GREEN}✓${NC} Using existing fixture: $TESTFILE"
fi
