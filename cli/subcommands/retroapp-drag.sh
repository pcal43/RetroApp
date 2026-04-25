#!/bin/sh

usage() {
  cat >&2 <<'EOF'
Usage: retroapp drag [-h] FILE1 [FILE2] [FILE3] [...]

This is the main entry point to the bundling app - it receives an arbitrary list
of files from the user, probably via Finder drag-and-drop, tries to figure out
what they are and assembles a launcher app from them.

EOF
  exit 1
}

