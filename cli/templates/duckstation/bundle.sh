#!/bin/sh
set -e

SUPPORT_DIR="$HOME/Library/Application Support/DuckStation"
RA_BUNDLE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/bundle/Contents/Resources"

# If this directory exists, copy all of it into $RA_BUNDLE_DIR/EmulatorConfig
if [ -d "$SUPPORT_DIR" ]; then
  echo "Copying DuckStation config from $SUPPORT_DIR..."
  mkdir -p "$RA_BUNDLE_DIR/EmulatorConfig"
  rsync -a --exclude='.DS_Store' "$SUPPORT_DIR/" "$RA_BUNDLE_DIR/EmulatorConfig/"
  echo "Done."
else
  echo "Warning: DuckStation support directory not found: $SUPPORT_DIR" >&2
  echo "Nothing copied." >&2
  exit 1
fi
