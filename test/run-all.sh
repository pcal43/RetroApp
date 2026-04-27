#!/bin/sh

# Runs all of the test-xxx.sh scripts found
# in this directory tree.  Prints SUCCESS or FAILURES
# at the end,dependning on whether all tests were successful.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FAILURES=0
PASSED=0

while IFS= read -r test_script; do
  echo "=== $(basename "$test_script") ==="
  if sh "$test_script"; then
    PASSED=$((PASSED + 1))
  else
    FAILURES=$((FAILURES + 1))
  fi
  echo ""
done << FINDEOF
$(find "$SCRIPT_DIR" -name 'test-*.sh' | sort)
FINDEOF

TOTAL=$((PASSED + FAILURES))
if [ "$FAILURES" -gt 0 ]; then
  echo "FAILURE: $FAILURES/$TOTAL test suite(s) failed."
  exit 1
else
  echo "SUCCESS: all $TOTAL test suite(s) passed."
fi