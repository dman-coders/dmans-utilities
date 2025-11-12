#!/usr/bin/env bash

# Test suite for process-tags-to-db

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
export MEDIA_DB="$(dirname "${BASH_SOURCE[0]}")/test.sqlite"

# Ensure fixtures directory exists
mkdir -p "$FIXTURES_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Testing process-tags-to-db"
echo "========================================="
echo ""

# Create test fixture if it doesn't exist
"$SCRIPT_DIR/test-create-fixtures"

echo ""
echo "Fixture tags:"
exiftool -Subject -Keywords -HierarchicalSubject -Categories "$TESTFILE"
echo ""

# Run the test
echo "Running process-tags-to-db..."
echo "========================================="
cd "$PARENT_DIR"
./process-tags-to-db "$TESTFILE"
RESULT=$?

echo ""
echo "========================================="
if [[ $RESULT -eq 0 ]]; then
    echo -e "${GREEN}✓ Test completed successfully${NC}"
else
    echo -e "${RED}✗ Test failed with exit code $RESULT${NC}"
fi

exit $RESULT
