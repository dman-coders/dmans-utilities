#!/usr/bin/env bash

# Standardized test framework for media library tests
# Provides consistent test execution, reporting, and formatting

# Test state tracking
declare -g TEST_COUNT=0
declare -g TEST_PASS=0
declare -g TEST_FAIL=0
declare -g CURRENT_TEST_NAME=""

# Initialize test suite
init_test_suite() {
  local suite_name="$1"
  TEST_COUNT=0
  TEST_PASS=0
  TEST_FAIL=0
  log_notice "========================================="
  log_notice "Test Suite: $suite_name"
  log_notice "========================================="
}

# Begin a test case
begin_test() {
  CURRENT_TEST_NAME="$1"
  TEST_COUNT=$((TEST_COUNT + 1))
  log_info "Test $TEST_COUNT: $CURRENT_TEST_NAME"
}

# Assert that a condition is true
assert_true() {
  local condition="$1"
  local message="${2:-Assertion failed}"

  if eval "$condition"; then
    TEST_PASS=$((TEST_PASS + 1))
    log_notice "  ✓ PASS: $message"
    return 0
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    log_error "  ✗ FAIL: $message"
    return 1
  fi
}

# Assert that two values are equal
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Expected '$expected', got '$actual'}"

  if [[ "$expected" == "$actual" ]]; then
    TEST_PASS=$((TEST_PASS + 1))
    log_notice "  ✓ PASS: $message"
    return 0
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    log_error "  ✗ FAIL: $message"
    log_error "    Expected: '$expected'"
    log_error "    Actual:   '$actual'"
    return 1
  fi
}

# Assert that a value is non-empty
assert_not_empty() {
  local value="$1"
  local message="${2:-Value should not be empty}"

  if [[ -n "$value" ]]; then
    TEST_PASS=$((TEST_PASS + 1))
    log_notice "  ✓ PASS: $message"
    return 0
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    log_error "  ✗ FAIL: $message"
    return 1
  fi
}

# Assert that a value is empty
assert_empty() {
  local value="$1"
  local message="${2:-Value should be empty}"

  if [[ -z "$value" ]]; then
    TEST_PASS=$((TEST_PASS + 1))
    log_notice "  ✓ PASS: $message"
    return 0
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    log_error "  ✗ FAIL: $message"
    log_error "    Got: '$value'"
    return 1
  fi
}

# Assert that a string contains a substring
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-String should contain '$needle'}"

  if [[ "$haystack" == *"$needle"* ]]; then
    TEST_PASS=$((TEST_PASS + 1))
    log_notice "  ✓ PASS: $message"
    return 0
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    log_error "  ✗ FAIL: $message"
    log_error "    Haystack: '$haystack'"
    log_error "    Needle:   '$needle'"
    return 1
  fi
}

# Finish test suite and report results
finish_test_suite() {
  log_notice "========================================="
  log_notice "Test Results:"
  log_notice "  Tests run: $TEST_COUNT"
  log_notice "  Passed:    $TEST_PASS"
  if [[ $TEST_FAIL -gt 0 ]]; then
    log_error "  Failed:    $TEST_FAIL"
  else
    log_notice "  Failed:    $TEST_FAIL"
  fi
  log_notice "========================================="

  if [[ $TEST_FAIL -gt 0 ]]; then
    return 1
  else
    return 0
  fi
}

# Setup standard test database
setup_test_db() {
  log_info "Setting up test database..."
  drop_database
  create_database
}
