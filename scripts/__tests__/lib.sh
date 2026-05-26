#!/usr/bin/env bash
# Tiny test helper. Sourced by scripts/__tests__/*.test.sh.

set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_TEST=""

it() {
  CURRENT_TEST="$1"
}

assert_eq() {
  local expected="$1" actual="$2" label="${3:-}"
  if [ "$expected" = "$actual" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  PASS  %s%s\n' "$CURRENT_TEST" "${label:+ — $label}"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL  %s%s\n        expected: %q\n        actual:   %q\n' \
      "$CURRENT_TEST" "${label:+ — $label}" "$expected" "$actual"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" label="${3:-}"
  if [[ "$haystack" == *"$needle"* ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  PASS  %s%s\n' "$CURRENT_TEST" "${label:+ — $label}"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL  %s%s\n        wanted substring: %q\n        in:               %q\n' \
      "$CURRENT_TEST" "${label:+ — $label}" "$needle" "$haystack"
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" label="${3:-}"
  if [[ "$haystack" != *"$needle"* ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  PASS  %s%s\n' "$CURRENT_TEST" "${label:+ — $label}"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL  %s%s\n        unwanted substring: %q\n        in:                 %q\n' \
      "$CURRENT_TEST" "${label:+ — $label}" "$needle" "$haystack"
  fi
}

assert_file_exists() {
  local path="$1" label="${2:-}"
  if [ -f "$path" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  PASS  %s%s (file exists)\n' "$CURRENT_TEST" "${label:+ — $label}"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL  %s%s\n        expected file: %s\n' "$CURRENT_TEST" "${label:+ — $label}" "$path"
  fi
}

assert_file_not_exists() {
  local path="$1" label="${2:-}"
  if [ ! -e "$path" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  PASS  %s%s (file absent)\n' "$CURRENT_TEST" "${label:+ — $label}"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL  %s%s\n        expected absent: %s\n' "$CURRENT_TEST" "${label:+ — $label}" "$path"
  fi
}

summary() {
  echo ""
  if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "FAIL: $FAIL_COUNT failed, $PASS_COUNT passed"
    exit 1
  fi
  echo "OK: $PASS_COUNT passed"
}
