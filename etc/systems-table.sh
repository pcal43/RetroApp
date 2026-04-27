#!/bin/bash
# This script scans all files in cli/systems and emits a GitHub markdown table
# with two columns: system (filename) and emulator id (file contents).

SYSTEMS_DIR="$(dirname "$0")/../cli/systems"

# Print table header
echo "| System | Emulator |"
echo "|--------|-------------|"

# Iterate over each file in the systems directory
for file in "$SYSTEMS_DIR"/*; do
  if [[ -f "$file" ]]; then
    system_name="$(basename "$file")"
    # Read the entire file content, trim leading/trailing whitespace
    emulator_id="$(<"$file" tr -d '\r' | xargs)"
    # Escape pipe characters in content for markdown
    emulator_id="${emulator_id//|/\|}"
    echo "| $system_name | $emulator_id |"
  fi
done
