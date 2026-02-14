#!/usr/bin/env bash
set -e

export UTIL_DIR=~/.media_processing_test
TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$TEST_SCRIPT_DIR"
export MEDIA_DB="$TEST_SCRIPT_DIR/test.sqlite"
# Use tmpfs for faster test execution
export SQLITE_USE_TMPFS=1

source "$TEST_SCRIPT_DIR/../process_media.lib"

# Track overall test results
TOTAL_SUITES=0
FAILED_SUITES=0
declare -a FAILED_SUITE_NAMES

log_notice "========================================="
log_notice "Running All Media Library Tests"
log_notice "Database: $MEDIA_DB"
log_notice "tmpfs: ${SQLITE_USE_TMPFS:-disabled}"
log_notice "========================================="

# Function to run a test suite and track results
run_test_suite() {
  local test_script="$1"
  local test_name=$(basename "$test_script" .sh)

  TOTAL_SUITES=$((TOTAL_SUITES + 1))

  log_info ""
  log_info "Running $test_name..."

  if bash "$test_script"; then
    log_notice "✓ $test_name completed successfully"
  else
    log_error "✗ $test_name FAILED"
    FAILED_SUITES=$((FAILED_SUITES + 1))
    FAILED_SUITE_NAMES+=("$test_name")
  fi
}

# Core unit tests
run_test_suite "${TEST_DIR}/test_db_constraints.sh"
run_test_suite "${TEST_SCRIPT_DIR}/test_ensure_tag_exists.sh"
run_test_suite "${TEST_SCRIPT_DIR}/test_synonyms.sh"
run_test_suite "${TEST_SCRIPT_DIR}/test_parent_child.sh"
run_test_suite "${TEST_SCRIPT_DIR}/test_longnames.sh"
run_test_suite "${TEST_SCRIPT_DIR}/test_pipe_in_names.sh"
run_test_suite "${TEST_SCRIPT_DIR}/test_accessor_patterns.sh"

# Integration tests
log_info ""
log_info "Creating test fixtures for integration tests..."
bash "${TEST_SCRIPT_DIR}/test_create_fixtures.sh"

run_test_suite "${TEST_SCRIPT_DIR}/test_process_tags_to_db.sh"

# Summary
log_notice ""
log_notice "========================================="
log_notice "All Tests Complete"
log_notice "========================================="
log_notice "Test suites run: $TOTAL_SUITES"
log_notice "Passed: $((TOTAL_SUITES - FAILED_SUITES))"

if [[ $FAILED_SUITES -gt 0 ]]; then
  log_error "Failed: $FAILED_SUITES"
  log_error "Failed suites:"
  for suite in "${FAILED_SUITE_NAMES[@]}"; do
    log_error "  - $suite"
  done
else
  log_notice "Failed: 0"
  log_notice ""
  log_notice "✓ All tests passed!"
fi
log_notice "========================================="

# Exit with failure if any suite failed
if [[ $FAILED_SUITES -gt 0 ]]; then
  exit 1
else
  exit 0
fi