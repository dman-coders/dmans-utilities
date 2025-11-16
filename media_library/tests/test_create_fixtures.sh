#!/usr/bin/env bash

# Test suite for process-tags-to-db

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../process_media.lib"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Ensure fixtures directory exists
mkdir -p "$FIXTURES_DIR"

log_notice "Initializing fixtures"
JPEG_DATA='\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01\x01\x01\x00\x48\x00\x48\x00\x00\xFF\xDB\x00\x43\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xC0\x00\x0B\x08\x00\x01\x00\x01\x01\x01\x11\x00\xFF\xC4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x08\x01\x01\x00\x00\x3F\x00\x7F\xFF\xD9'

# Create test fixture if it doesn't exist
TESTFILE="$FIXTURES_DIR/test-image.jpg"
if [[ ! -f "$TESTFILE" ]]; then
    log_info "Creating test fixture..."
    # Create a minimal JPEG (1x1 pixel)
    echo -n -e "$JPEG_DATA" > "$TESTFILE"

    # Add various tags using exiftool
    exiftool -overwrite_original \
      -Subject="TestSubject" \
      -Keywords="Test Keyword 2, Test Keyword 1" \
      -HierarchicalSubject="Topic|testing|Fixture" \
      -Categories="Test Category, Fixture" \
      "$TESTFILE" >/dev/null 2>&1

    log_info "Test fixture created: $TESTFILE"
else
    log_info "Using existing fixture: $TESTFILE"
fi
echo $TESTFILE;


TESTFILE="$FIXTURES_DIR/dog.jpg"
if [[ ! -f "$TESTFILE" ]]; then
    log_info  "Creating test fixture $TESTFILE..."
    echo -n -e "$JPEG_DATA" > "$TESTFILE"
    # Add various tags using exiftool
    exiftool -overwrite_original \
      -Subject="Dog" \
      -Keywords="Dog" \
      -HierarchicalSubject="Animals|Mammals|Canine|Dog" \
      "$TESTFILE" >/dev/null 2>&1
else
    log_info "Using existing fixture: $TESTFILE"
fi
echo $TESTFILE;

TESTFILE="$FIXTURES_DIR/cat.jpg"
if [[ ! -f "$TESTFILE" ]]; then
    log_info "Creating test fixture $TESTFILE..."
    echo -n -e "$JPEG_DATA" > "$TESTFILE"
    # Add various tags using exiftool
    exiftool -overwrite_original \
      -Subject="Cat" \
      -Keywords="Cat, Pussy, moggy" \
      -HierarchicalSubject="Animals|Mammals|Feline|Cat" \
      -HierarchicalSubject="Location|Inside|Lounge" \
      "$TESTFILE" >/dev/null 2>&1
else
    log_info "Using existing fixture: $TESTFILE"
fi
echo $TESTFILE;

TESTFILE="$FIXTURES_DIR/lion.jpg"
if [[ ! -f "$TESTFILE" ]]; then
    log_info  "Creating test fixture $TESTFILE..."
    echo -n -e "$JPEG_DATA" > "$TESTFILE"
    # Add various tags using exiftool
    exiftool -overwrite_original \
      -Description'"A lion in the jungle' \
      -HierarchicalSubject="Animals|Mammals|Feline|Lion" \
      -HierarchicalSubject="Location|Outside|Jungle" \
      "$TESTFILE" >/dev/null 2>&1
else
    log_info "Using existing fixture: $TESTFILE"
fi
echo $TESTFILE;
