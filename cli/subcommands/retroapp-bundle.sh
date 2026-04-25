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
    n) RA_APP_NAME="$OPTARG" ;;
    e) RA_EMULATOR_ID="$OPTARG" ;;
    r) RA_ROM_PATH="$OPTARG" ;;
    i) RA_ICNS_PATH="$OPTARG" ;;
    o) RA_OUTPUT_DIR="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${RA_APP_NAME:-}" ]; then
  echo "Error: -n appName is required." >&2
  usage
fi
if [ -z "${RA_EMULATOR_ID:-}" ]; then
  echo "Error: -e emulatorId is required." >&2
  usage
fi
if [ -z "${RA_ROM_PATH:-}" ]; then
  echo "Error: -r romPath is required." >&2
  usage
fi
if [ ! -f "$RA_ROM_PATH" ]; then
  echo "Error: ROM file not found: $RA_ROM_PATH" >&2
  exit 1
fi
if [ -n "${RA_ICNS_PATH:-}" ] && [ ! -f "$RA_ICNS_PATH" ]; then
  echo "Error: icon file not found: $RA_ICNS_PATH" >&2
  exit 1
fi

RA_TEMPLATE_DIR="$RA_SCRIPT_DIR/templates/$RA_EMULATOR_ID"
if [ ! -d "$RA_TEMPLATE_DIR/bundle" ]; then
  echo "Error: no bundle template found for emulator '$RA_EMULATOR_ID' (looked in $RA_TEMPLATE_DIR/bundle)" >&2
  exit 1
fi

RA_ROM_BASENAME=$(basename "$RA_ROM_PATH")
if [ -n "${RA_OUTPUT_DIR:-}" ]; then
  RA_OUTPUT_PATH="${RA_OUTPUT_DIR}/${RA_APP_NAME}.app"
else
  RA_OUTPUT_PATH="$(dirname "$RA_ROM_PATH")/${RA_APP_NAME}.app"
fi

# Create staging area and copy template bundle into it
RA_STAGING_DIR=$(mktemp -d -t retroapp-bundle)
RA_BUNDLE_DIR="$RA_STAGING_DIR/${RA_APP_NAME}.app"
rsync -a --exclude='.DS_Store' "$RA_TEMPLATE_DIR/bundle/" "$RA_BUNDLE_DIR/"

# Copy ROM into bundle
mkdir -p "$RA_BUNDLE_DIR/Contents/Resources/Roms"
cp "$RA_ROM_PATH" "$RA_BUNDLE_DIR/Contents/Resources/Roms/"

# Copy icns if provided
if [ -n "${RA_ICNS_PATH:-}" ]; then
  cp "$RA_ICNS_PATH" "$RA_BUNDLE_DIR/Contents/Resources/AppIcon.icns"
fi

# Write a Python processor to a temp file to safely handle $ substitution
RA_PROCESSOR=$(mktemp /tmp/retroapp-processor-XXXXXX)
cat > "$RA_PROCESSOR" << 'PYEOF'
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
find "$RA_BUNDLE_DIR" -name "*.template" | while IFS= read -r template_file; do
  output_file="${template_file%.template}"
  python3 "$RA_PROCESSOR" "$RA_APP_NAME" "$RA_ROM_BASENAME" "$template_file" "$output_file"
  rm "$template_file"
done

rm -f "$RA_PROCESSOR"

# Ensure the launch script is executable
chmod +x "$RA_BUNDLE_DIR/Contents/MacOS/launch"

# Move finished bundle to output location
mv "$RA_BUNDLE_DIR" "$RA_OUTPUT_PATH"
rm -rf "$RA_STAGING_DIR"

echo "Created $RA_OUTPUT_PATH"