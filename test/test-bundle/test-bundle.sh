#!/bin/sh

# Runs retroapp bundle on Halo2600.a26 to validate the 
# generated content

set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RETROAPP="$SCRIPT_DIR/../../cli/retroapp"
ROM="$SCRIPT_DIR/Halo2600.a26"
APP_NAME="Halo 2600 Test"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
FAILURES=0

# Build into the expect directory so the output is inspectable
WORK_DIR="$SCRIPT_DIR/expect"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

"$RETROAPP" bundle -n "$APP_NAME" -e stella -r "$ROM"

BUNDLE="$WORK_DIR/${APP_NAME}.app"

# 1. Bundle directory exists
if [ -d "$BUNDLE" ]; then
  pass "bundle directory created"
else
  fail "bundle directory not found at $BUNDLE"
fi

# 2. No leftover .template files
if find "$BUNDLE" -name "*.template" | grep -q .; then
  fail ".template files remain in bundle"
else
  pass "no leftover .template files"
fi

# 3. ROM is present
if [ -f "$BUNDLE/Contents/Resources/Roms/Halo2600.a26" ]; then
  pass "ROM copied into bundle"
else
  fail "ROM not found in bundle"
fi

# 4. Info.plist exists and contains the app name
if grep -q "Halo 2600 Test" "$BUNDLE/Contents/Info.plist" 2>/dev/null; then
  pass "Info.plist contains app name"
else
  fail "Info.plist missing or does not contain app name"
fi

# 5. launch script exists and is executable
if [ -x "$BUNDLE/Contents/MacOS/launch" ]; then
  pass "launch script is executable"
else
  fail "launch script missing or not executable"
fi

# 6. launch script contains the ROM name (RETROAPP_ROM_NAME substituted)
if grep -q "Halo2600.a26" "$BUNDLE/Contents/MacOS/launch" 2>/dev/null; then
  pass "launch script contains ROM name"
else
  fail "launch script does not contain ROM name"
fi

# 7. launch script contains the app/game name (RETROAPP_GAME_NAME substituted)
if grep -q "Halo 2600 Test" "$BUNDLE/Contents/MacOS/launch" 2>/dev/null; then
  pass "launch script contains game name"
else
  fail "launch script does not contain game name"
fi

# 8. launch script has no unsubstituted RETROAPP_ tokens
if grep -q "RETROAPP_" "$BUNDLE/Contents/MacOS/launch" 2>/dev/null; then
  fail "launch script contains unsubstituted RETROAPP_ tokens"
else
  pass "launch script has no unsubstituted tokens"
fi

# 9. AppIcon.icns is present (from template default)
if [ -f "$BUNDLE/Contents/Resources/AppIcon.icns" ]; then
  pass "AppIcon.icns present"
else
  fail "AppIcon.icns missing"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All tests passed."
  exit 0
else
  echo "$FAILURES test(s) failed."
  exit 1
fi