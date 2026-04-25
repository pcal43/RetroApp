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

# Temp directory for archive extractions (cleaned up at end of script)
DRAG_EXTRACT_DIR=$(mktemp -d /tmp/retroapp-extract-XXXXXX)

# Helper: return 0 if the file is a supported archive format
_is_archive() {
  case "$1" in
    *.zip|*.ZIP|*.7z|*.7Z|*.rar|*.RAR) return 0 ;;
    *) return 1 ;;
  esac
}

# Helper: extract an archive into a destination directory
_extract_archive() {
  _arc_file="$1"
  _arc_dst="$2"
  case "$_arc_file" in
    *.zip|*.ZIP)
      unzip -q "$_arc_file" -d "$_arc_dst" ;;
    *.7z|*.7Z)
      if command -v 7z > /dev/null 2>&1; then
        7z x -o"$_arc_dst" "$_arc_file" > /dev/null
      else
        echo "WARNING: 7z not installed, cannot extract: $_arc_file" >&2
        return 1
      fi ;;
    *.rar|*.RAR)
      if command -v unrar > /dev/null 2>&1; then
        unrar x "$_arc_file" "$_arc_dst/" > /dev/null
      else
        echo "WARNING: unrar not installed, cannot extract: $_arc_file" >&2
        return 1
      fi ;;
  esac
}

# Step 1: expand directory arguments into a raw flat file list.
# Track a candidate output directory: a directly-dragged archive sets it provisionally;
# a directly-dragged (non-temp) ROM will override it later.
DRAG_OUTPUT_DIR=""
DRAG_RAW_LIST=$(mktemp /tmp/retroapp-rawlist-XXXXXX)
for DRAG_ARG in "$@"; do
  if [ -d "$DRAG_ARG" ]; then
    find "$DRAG_ARG" -type f >> "$DRAG_RAW_LIST"
  else
    printf '%s\n' "$DRAG_ARG" >> "$DRAG_RAW_LIST"
    if [ -z "$DRAG_OUTPUT_DIR" ] && _is_archive "$DRAG_ARG"; then
      DRAG_OUTPUT_DIR=$(dirname "$DRAG_ARG")
    fi
  fi
done

# Step 2: expand any archives in the raw list into the final file list
DRAG_FILE_LIST=$(mktemp /tmp/retroapp-filelist-XXXXXX)
while IFS= read -r _raw_file; do
  if _is_archive "$_raw_file"; then
    _subdir=$(mktemp -d "$DRAG_EXTRACT_DIR/XXXXXX")
    echo "Extracting archive: $_raw_file" >&2
    if _extract_archive "$_raw_file" "$_subdir"; then
      find "$_subdir" -type f >> "$DRAG_FILE_LIST"
    else
      echo "WARNING: could not extract archive, skipping: $_raw_file" >&2
    fi
  else
    printf '%s\n' "$_raw_file" >> "$DRAG_FILE_LIST"
  fi
done < "$DRAG_RAW_LIST"
rm -f "$DRAG_RAW_LIST"

echo 'Files to process:' >&2
cat "$DRAG_FILE_LIST" >&2
echo "\n\n" >&2

# Iterate through the expanded file list, identify each file
while IFS= read -r DRAG_FILE; do
  if [ ! -f "$DRAG_FILE" ]; then
    echo "WARNING file not found, skipping $DRAG_FILE" >&2
    continue
  fi

  DRAG_IDENTIFY=$("$RA_RETROAPP" identify "$DRAG_FILE" 2>/dev/null) || true
  DRAG_TYPE=$(printf '%s' "$DRAG_IDENTIFY" | sed -n '1p')

  case "$DRAG_TYPE" in
    png)
      if [ -n "$DRAG_ICON_PNG" ]; then
        echo "WARNING multiple PNG files provided, ignoring $DRAG_FILE" >&2
      else
        echo "Will use this for the icon: $DRAG_FILE"
        DRAG_ICON_PNG="$DRAG_FILE"
      fi
      ;;
    rom)
      if [ -n "$DRAG_ROM_PATH" ]; then
        echo "WARNING multiple ROM files provided; ignoring $DRAG_FILE" >&2
      else
        DRAG_ROM_PATH="$DRAG_FILE"
        DRAG_ROM_SYSTEM=$(printf '%s' "$DRAG_IDENTIFY" | sed -n '2p')
        DRAG_GAME_NAME=$(printf '%s' "$DRAG_IDENTIFY" | sed -n '3p')
        echo "Will use this for the ROM file: $DRAG_FILE" >&2
        echo "  System is $DRAG_ROM_SYSTEM" >&2
        echo "  Game is $DRAG_GAME_NAME" >&2
        # ROM from the user's filesystem overrides the provisional archive output dir
        case "$DRAG_ROM_PATH" in
          "$DRAG_EXTRACT_DIR"/*) ;;
          *) DRAG_OUTPUT_DIR=$(dirname "$DRAG_ROM_PATH") ;;
        esac
      fi
      ;;
    *)
      echo "WARNING could not identify file, ignoring: $DRAG_FILE" >&2
      ;;
  esac
done < "$DRAG_FILE_LIST"
rm -f "$DRAG_FILE_LIST"

# Require a ROM
if [ -z "$DRAG_ROM_PATH" ]; then
  echo "ERROR no ROM file could be identified among the provided files." >&2
  exit 1
fi

# Look up emulator id from cli/systems/<system name>
DRAG_EMU_FILE="$RA_SCRIPT_DIR/systems/${DRAG_ROM_SYSTEM}"
if [ ! -f "$DRAG_EMU_FILE" ]; then
  echo "ERROR emulator not supported for system '$DRAG_ROM_SYSTEM'" >&2
  exit 1
fi
# The file may contain just an id ("nestopia") or a path ("stella/Stella-6.0.app");
# extract just the first path component as the emulator id.
DRAG_EMULATOR_ID=$(tr -d '[:space:]' < "$DRAG_EMU_FILE" | cut -d'/' -f1)

# If no icon PNG was provided, try to download a thumbnail
if [ -z "$DRAG_ICON_PNG" ]; then
  echo "Downloading thumbnail..." >&2
  DRAG_ICON_PNG=$("$RA_RETROAPP" thumbnail "$DRAG_ROM_SYSTEM" "$DRAG_GAME_NAME") || DRAG_ICON_PNG=""
fi

# Convert PNG to .icns if we have one; otherwise the bundle template's default icon will be used
DRAG_ICNS=""
if [ -n "$DRAG_ICON_PNG" ]; then
  echo "Building icns..." >&2
  DRAG_ICNS=$(mktemp /tmp/retroapp-icon-XXXXXX)
  mv "$DRAG_ICNS" "${DRAG_ICNS}.icns"
  DRAG_ICNS="${DRAG_ICNS}.icns"
  "$RA_RETROAPP" icns "$DRAG_ICON_PNG" "$DRAG_ICNS"
else
  echo "No icon available; using default from template." >&2
fi

echo "Building application bundle."  >&2
set -- -n "$DRAG_GAME_NAME" -e "$DRAG_EMULATOR_ID" -r "$DRAG_ROM_PATH"
[ -n "$DRAG_OUTPUT_DIR" ] && set -- "$@" -o "$DRAG_OUTPUT_DIR"
[ -n "$DRAG_ICNS" ]       && set -- "$@" -i "$DRAG_ICNS"
"$RA_RETROAPP" bundle "$@"

rm -f "$DRAG_ICNS"
rm -rf "$DRAG_EXTRACT_DIR"