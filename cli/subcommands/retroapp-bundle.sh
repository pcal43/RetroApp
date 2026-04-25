#!/bin/sh

#
# Good source for images
# https://gamesdb.launchbox-app.com/
#

usage() {
  echo "Usage: retroapp bundle [-h] [options...]

Creates a standlone launcher bundle for a retro game that can be double-clicked 
in MacOS.

    -h                   Print this message.

    -n appName           The name of the launcher app to build.
                         Usually just the name of the game.
                         Required.

    -e emulatorId        The emulator to use, e.g., 'stella' or 'nestopia'.
                         Run 'retroapp list-emulators' for a full list.
                         Required.

    -r romPath           Path to rom file for the launcher to run.
                         Required.

    -i icnsPath          Path to a .icns file toto use as an app icon.  These
                         can be generated with 'retroapp icns'.
                         Optional.  If omitted, a default icon will be used.

    -o outputDir         Directory that the new bundle will be created in.
                         Optional.  If omitted, the directory containing the 
                         rom file (romPath) will be used.
    

This tool works as follows:
- It locates the bundle template in cli/templates/[emulatorId].  It's an error if it doesn't exist.
- Copy the contents of the template's 'bundle' subdirectory into a staging directory.
- Copy the rom provided by -r into the staging directory at [stagingdir]/Contents/Resources/Roms.  Create the Roms directory if needed.  
- If -i is specified, copy that file into the stageing directory at [stagingdir]/Contents/Resources/AppIcon.icns.  Overwrite the existing file.
- Scan the staging dir for any files with names ending in .template.  These need to 
be rewritten as new files without the .template extension and performing the following
substitutions: RETROAPP_APP_NAME (the -n appName) and RETROAPP_ROM_NAME the name of the file that provided by -r (basename only)
- Delete the .template files from the staging directory
- Ensure the file [stagingdir]/Contents/MacOS/launch is executable (chmod +x)

Note that this is a rework of retroapp-build.sh.  You can refer to that at a template
but note that the process here is significantly different.  Also refer to templates/stella
for an example of the kind of template we will be processing.



" >&2
  exit 1
}

while getopts "n:e:r:i:o:h" opt; do
  case $opt in
    n) CLI_APP_NAME="$OPTARG" ;;
    e) CLI_EMULATOR_ID="$OPTARG" ;;
    r) CLI_ROM_PATH="$OPTARG" ;;
    i) CLI_ICNS_PATH="$OPTARG" ;;
    o) CLI_OUTPUT_DIR="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${CLI_APP_NAME:-}" ]; then
  echo "Error: -n appName is required." >&2
  usage
fi
if [ -z "${CLI_EMULATOR_ID:-}" ]; then
  echo "Error: -e emulatorId is required." >&2
  usage
fi
if [ -z "${CLI_ROM_PATH:-}" ]; then
  echo "Error: -r romPath is required." >&2
  usage
fi
if [ ! -f "$CLI_ROM_PATH" ]; then
  echo "Error: ROM file not found: $CLI_ROM_PATH" >&2
  exit 1
fi
if [ -n "${CLI_ICNS_PATH:-}" ] && [ ! -f "$CLI_ICNS_PATH" ]; then
  echo "Error: icon file not found: $CLI_ICNS_PATH" >&2
  exit 1
fi

CLI_TEMPLATE_DIR="$RA_SCRIPT_DIR/templates/$CLI_EMULATOR_ID"
if [ ! -d "$CLI_TEMPLATE_DIR/bundle" ]; then
  echo "Error: no bundle template found for emulator '$CLI_EMULATOR_ID' (looked in $CLI_TEMPLATE_DIR/bundle)" >&2
  exit 1
fi

CLI_ROM_BASENAME=$(basename "$CLI_ROM_PATH")
if [ -n "${CLI_OUTPUT_DIR:-}" ]; then
  CLI_OUTPUT_PATH="${CLI_OUTPUT_DIR}/${CLI_APP_NAME}.app"
else
  CLI_OUTPUT_PATH="$(dirname "$CLI_ROM_PATH")/${CLI_APP_NAME}.app"
fi

# Create staging area and copy template bundle into it
CLI_STAGING_DIR=$(mktemp -d -t retroapp-bundle)
CLI_BUNDLE_DIR="$CLI_STAGING_DIR/${CLI_APP_NAME}.app"
rsync -a --exclude='.DS_Store' "$CLI_TEMPLATE_DIR/bundle/" "$CLI_BUNDLE_DIR/"

# Copy ROM into bundle
mkdir -p "$CLI_BUNDLE_DIR/Contents/Resources/Roms"
cp "$CLI_ROM_PATH" "$CLI_BUNDLE_DIR/Contents/Resources/Roms/"

# Copy icns if provided
if [ -n "${CLI_ICNS_PATH:-}" ]; then
  cp "$CLI_ICNS_PATH" "$CLI_BUNDLE_DIR/Contents/Resources/AppIcon.icns"
fi

# Write a Python processor to a temp file to safely handle $ substitution
CLI_PROCESSOR=$(mktemp /tmp/retroapp-processor-XXXXXX)
cat > "$CLI_PROCESSOR" << 'PYEOF'
import sys
app_name = sys.argv[1]
rom_name = sys.argv[2]
src      = sys.argv[3]
dst      = sys.argv[4]
content = open(src).read()
for token in ('${RETROAPP_APP_NAME}', '$RETROAPP_APP_NAME',
              '${RETROAPP_GAME_NAME}', '$RETROAPP_GAME_NAME'):
    content = content.replace(token, app_name)
for token in ('${RETROAPP_ROM_NAME}', '$RETROAPP_ROM_NAME'):
    content = content.replace(token, rom_name)
content = content.replace('\\$', '$')
open(dst, 'w').write(content)
PYEOF

# Process all .template files
find "$CLI_BUNDLE_DIR" -name "*.template" | while IFS= read -r template_file; do
  output_file="${template_file%.template}"
  python3 "$CLI_PROCESSOR" "$CLI_APP_NAME" "$CLI_ROM_BASENAME" "$template_file" "$output_file"
  rm "$template_file"
done

rm -f "$CLI_PROCESSOR"

# Ensure the launch script is executable
chmod +x "$CLI_BUNDLE_DIR/Contents/MacOS/launch"

# Move finished bundle to output location
mv "$CLI_BUNDLE_DIR" "$CLI_OUTPUT_PATH"
rm -rf "$CLI_STAGING_DIR"

echo "Created $CLI_OUTPUT_PATH"