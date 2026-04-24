#!/bin/sh

usage() {
  cat >&2 <<'EOF'
Usage: retroapp identify-binary [-h] BINARY_PATH

  Attempts to identify the binary file at the given path.  It does this by
  running crc32 on the file and then searching for that crc in the .dat
  files in cli/hashes directory

  If it finds a match, it outputs the emulator code (which is the enclosing directory
  of the .dat file in which the hash was found) followed by the name of the game
  from the dat file.

  If it could not be found, exits with -1.
EOF
  exit 1
}

while getopts "h" opt; do
  case $opt in
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${1:-}" ]; then
  echo "Error: BINARY_PATH is required." >&2
  usage
fi

CLI_BINARY_PATH="$1"

if [ ! -f "$CLI_BINARY_PATH" ]; then
  echo "Error: File not found: $CLI_BINARY_PATH" >&2
  exit 1
fi

# Compute CRC32 as uppercase 8-character hex (matches .dat file format)
CLI_CRC=$(python3 -c "
import sys, binascii
data = open(sys.argv[1], 'rb').read()
print(format(binascii.crc32(data) & 0xffffffff, '08X'))
" "$CLI_BINARY_PATH")

# Search all .dat files under the hashes directory
RA_HASHES_DIR="$RA_SCRIPT_DIR/hashes"

for dat_file in "$RA_HASHES_DIR"/*/*.dat; do
  [ -f "$dat_file" ] || continue

  # Quick check before expensive awk pass
  if grep -q "crc $CLI_CRC" "$dat_file"; then
    # Extract emulator code from the containing directory name
    found_emulator=$(basename "$(dirname "$dat_file")")

    # Single-pass awk: track the most-recent game-level name line (^\tname "..."),
    # print it when we hit the rom line containing our CRC, then exit.
    found_game=$(awk -v crc="$CLI_CRC" '
      /^\tname "/ {
        match($0, /"[^"]*"/)
        game_name = substr($0, RSTART + 1, RLENGTH - 2)
      }
      index($0, "crc " crc) > 0 {
        print game_name
        exit
      }
    ' "$dat_file")

    printf '%s %s\n' "$found_emulator" "$found_game"
    exit 0
  fi
done

exit 1

