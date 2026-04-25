#!/bin/sh

usage() {
  cat >&2 <<'EOF'
Usage: retroapp drag [-h] FILE1 [FILE2] [FILE3] [...]

This is the main entry point to the bundling app - it receives an arbitrary list
of files from the user, probably via Finder drag-and-drop, tries to figure out
what they are and assembles a launcher app from them.

The script should work as follows:

Iterate through all of the arguments, each of which must be a path to file.  For each path:
If the file doesn't exist, output a warning message.
Otherwise, run 'retroarch-identify' on it.  
If the file identifies as unknown, output a warning message.
If the file identifies as a png, note it as the icon path
If the file identifies as a rom, note it as the rom file path.  In this case we must
also preseve the second and third lines of output (the system name and the game name).

In the case where more than one file of a type is passed, the first one should win.  Output
a warning message that the extra arguments are being ignored.

Once we have all of the arguments, we need to begin to build the bundle.  If we were not
able to identify a rom file, output an error message and exit 1.

We first need to determine which emulator to use.  We can get an emulator id by
checking the files in cli/emulators - this contains a file for each 'system name' 
that we support.  The contents of each file is the emulator id.  Check for the
file that corresponds to the 'system name' line we got from identifying the rom.
If the file exists, cat it and make note of the emulator id.  If it does not exist, 
output an error message saying 'emulator not supported' and exit 1.

If the icon path was not specified, get one by running retroapp-icon-png.sh.  This
will attempt to download one or use a default if that fails.  Take the path
that is output and use it as the icon png.

Once we have an icon png, we need to create a .icns file using retroapp-icns.sh.
Output it (second argument) to a tempoary file and save that path as the icns path.

Now we should have all of the following information:
- game name
- path to rom file
- emulator id
- icns file

which is exactly what we need to run retroapp-bundle.  Go ahead and run it.



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
  usage
fi

DRAG_ROM_PATH=""
DRAG_ROM_SYSTEM=""
DRAG_GAME_NAME=""
DRAG_ICON_PNG=""

# Iterate through all arguments, identify each file
echo "Checking files:" >&2
for DRAG_FILE in "$@"; do
  echo "$DRAG_FILE" >&2
  if [ ! -f "$DRAG_FILE" ]; then
    echo "Warning: file not found, skipping: $DRAG_FILE" >&2
    continue
  fi

  DRAG_IDENTIFY=$("$RA_RETROAPP" identify "$DRAG_FILE" 2>/dev/null) || true
  DRAG_TYPE=$(printf '%s' "$DRAG_IDENTIFY" | sed -n '1p')

  case "$DRAG_TYPE" in
    png)
      if [ -n "$DRAG_ICON_PNG" ]; then
        echo "Warning: multiple PNG files provided; ignoring $DRAG_FILE" >&2
      else
        echo "...png file.  Will use this as an icon."
        DRAG_ICON_PNG="$DRAG_FILE"
      fi
      ;;
    rom)
      if [ -n "$DRAG_ROM_PATH" ]; then
        echo "Warning: multiple ROM files provided; ignoring $DRAG_FILE" >&2
      else
        DRAG_ROM_PATH="$DRAG_FILE"
        DRAG_ROM_SYSTEM=$(printf '%s' "$DRAG_IDENTIFY" | sed -n '2p')
        DRAG_GAME_NAME=$(printf '%s' "$DRAG_IDENTIFY" | sed -n '3p')
        echo "...rom file.  System is $DRAG_ROM_SYSTEM. Game is $DRAG_GAME_NAME"
      fi
      ;;
    *)
      echo "Warning: could not identify file, skipping: $DRAG_FILE" >&2
      ;;
  esac
done

# Require a ROM
if [ -z "$DRAG_ROM_PATH" ]; then
  echo "Error: no ROM file could be identified among the provided files." >&2
  exit 1
fi

# Look up emulator id from cli/emulators/<system name>
DRAG_EMU_FILE="$RA_SCRIPT_DIR/emulators/${DRAG_ROM_SYSTEM}"
if [ ! -f "$DRAG_EMU_FILE" ]; then
  echo "Error: emulator not supported for system '$DRAG_ROM_SYSTEM'" >&2
  exit 1
fi
# The file may contain just an id ("nestopia") or a path ("stella/Stella-6.0.app");
# extract just the first path component as the emulator id.
DRAG_EMULATOR_ID=$(tr -d '[:space:]' < "$DRAG_EMU_FILE" | cut -d'/' -f1)

# Get an icon PNG if none was provided
if [ -z "$DRAG_ICON_PNG" ]; then
  echo "Getting icon..." >&2
  DRAG_ICON_PNG=$("$RA_RETROAPP" thumbnail "$DRAG_ROM_SYSTEM" "$DRAG_GAME_NAME") || true
fi

# Convert PNG to .icns
echo "Building icns" >&2

DRAG_ICNS=$(mktemp /tmp/retroapp-icon-XXXXXX)
mv "$DRAG_ICNS" "${DRAG_ICNS}.icns"
DRAG_ICNS="${DRAG_ICNS}.icns"
"$RA_RETROAPP" icns "$DRAG_ICON_PNG" "$DRAG_ICNS"

# Build the bundle
"$RA_RETROAPP" bundle \
  -n "$DRAG_GAME_NAME" \
  -e "$DRAG_EMULATOR_ID" \
  -r "$DRAG_ROM_PATH" \
  -i "$DRAG_ICNS"

rm -f "$DRAG_ICNS"