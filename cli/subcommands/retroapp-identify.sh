#!/bin/sh

usage() {
  cat >&2 <<'EOF'
Usage: retroapp identify [-h] BINARY_PATH

  Attempts to identify the binary file at the given path.  It peforms a number
  of checks on the file and then produces a multi-line output describing what it is.

  The first line is always a type indicator.  It will be one of the following:
  png, rom.

  For pngs, these will be identified by checking for the magic number
  (hex 89 50 4E 47 0D 0A 1A 0A).  No additional output will be provided - its just png.

  If its nota png, we run crc32 on the file and then searching for that crc in the
  .dat files in cli/hashes directory

  If it finds a match, it outputs the type id (rom), followed by the name of the .dat 
  file in which the hash was found (without the .dat extension), followed by a newline 
  and the name of the game from the dat file.

  If the file could not be determined, a single line 'unknown' for the type is output
  and we exit with -1.
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

RA_BINARY_PATH="$1"

if [ ! -f "$RA_BINARY_PATH" ]; then
  echo "Error: File not found: $RA_BINARY_PATH" >&2
  exit 1
fi

# Search all .dat files under the hashes directory for a given CRC.
# Prints "emulator game_name" and returns 0 on match; returns 1 otherwise.
search_crc() {
  _crc="$1"
  for _dat_file in "$RA_HASHES_DIR"/*/*.dat; do
    [ -f "$_dat_file" ] || continue
    if grep -q "crc $_crc" "$_dat_file"; then
      _found_dat=$(basename "$_dat_file" .dat)
      _found_game=$(awk -v crc="$_crc" '
        /^\tname "/ {
          match($0, /"[^"]*"/)
          game_name = substr($0, RSTART + 1, RLENGTH - 2)
        }
        index($0, "crc " crc) > 0 {
          print game_name
          exit
        }
      ' "$_dat_file")
      printf 'rom\n%s\n%s\n' "$_found_dat" "$_found_game"
      return 0
    fi
  done
  return 1
}

# Search all .dat files under the hashes directory
RA_HASHES_DIR="$RA_SCRIPT_DIR/hashes"

# Check for PNG magic number (89 50 4E 47 0D 0A 1A 0A)
PNG_MAGIC=$(python3 -c "
import sys
print(open(sys.argv[1], 'rb').read(8).hex().upper())
" "$RA_BINARY_PATH")

if [ "$PNG_MAGIC" = "89504E470D0A1A0A" ]; then
  echo "png"
  exit 0
fi

# Compute CRC32 as uppercase 8-character hex (matches .dat file format)
RA_CRC=$(python3 -c "
import sys, binascii
data = open(sys.argv[1], 'rb').read()
print(format(binascii.crc32(data) & 0xffffffff, '08X'))
" "$RA_BINARY_PATH")

# First pass: hash the full file
if search_crc "$RA_CRC"; then
  exit 0
fi

# Second pass: if the file has an iNES header (4e 45 53 1a), rehash without it
INES_MAGIC=$(python3 -c "
import sys
print(open(sys.argv[1], 'rb').read(4).hex().upper())
" "$RA_BINARY_PATH")

if [ "$INES_MAGIC" = "4E45531A" ]; then
  RA_CRC_HEADLESS=$(python3 -c "
import sys, binascii
data = open(sys.argv[1], 'rb').read()[16:]
print(format(binascii.crc32(data) & 0xffffffff, '08X'))
" "$RA_BINARY_PATH")
  if search_crc "$RA_CRC_HEADLESS"; then
    exit 0
  fi
fi

echo "unknown"
exit 1

