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