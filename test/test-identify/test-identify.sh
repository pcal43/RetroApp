#!/bin/sh

# Runs 'retroapp identify' on various files
# in the test/resources directory and confirms
# that the output is correct

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RETROAPP="$SCRIPT_DIR/../../cli/retroapp"
RESOURCES="$SCRIPT_DIR/../resources"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
FAILURES=0

assert_eq() {
  if [ "$1" = "$2" ]; then
    pass "$3"
  else
    fail "$3 (expected '$1', got '$2')"
  fi
}

# --- PNG detection ---
OUTPUT=$("$RETROAPP" identify "$RESOURCES/default-icon.png")
assert_eq "png" "$(echo "$OUTPUT" | sed -n '1p')" "default-icon.png type is png"
assert_eq "1"   "$(echo "$OUTPUT" | wc -l | tr -d ' ')" "png output is exactly 1 line"

# --- ROM: Atari 2600 ---
OUTPUT=$("$RETROAPP" identify "$RESOURCES/Halo2600.a26")
assert_eq "rom"                                    "$(echo "$OUTPUT" | sed -n '1p')" "Halo2600.a26 type is rom"
assert_eq "Atari - 2600"                           "$(echo "$OUTPUT" | sed -n '2p')" "Halo2600.a26 dat name"
assert_eq "Halo 2600 (World) (Aftermarket) (Unl)"  "$(echo "$OUTPUT" | sed -n '3p')" "Halo2600.a26 game name"

# --- ROM: NES (with iNES header) ---
OUTPUT=$("$RETROAPP" identify "$RESOURCES/dpadhero2.nes")
assert_eq "rom"                                        "$(echo "$OUTPUT" | sed -n '1p')" "dpadhero2.nes type is rom"
assert_eq "Nintendo - Nintendo Entertainment System"   "$(echo "$OUTPUT" | sed -n '2p')" "dpadhero2.nes dat name"
assert_eq "D+Pad Hero II (USA)"                        "$(echo "$OUTPUT" | sed -n '3p')" "dpadhero2.nes game name"

# --- Unknown file ---
OUTPUT=$("$RETROAPP" identify "$RETROAPP" 2>/dev/null) || true
assert_eq "unknown" "$(echo "$OUTPUT" | sed -n '1p')" "shell script identified as unknown"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All tests passed."
  exit 0
else
  echo "$FAILURES test(s) failed."
  exit 1
fi