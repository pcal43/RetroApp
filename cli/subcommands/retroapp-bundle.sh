#!/bin/zsh

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

    -b                   Bundle the selected emulator into the launcher.  This can 
                         signiicantly increase the size of the launcher app, but the 
                         upside is that you have a fully self-contained app that 
                         always runs the same way.
                         Optional.  If ommitted, the launcher app will look for the
                         emulator in /Applications.

    -s                   Sandbox the emulator configuration for this game.  If enabled,
                         the launcher app will force the emulator to run with an
                         isolated configuration in ~/Library/Application Support/RetroApp.
                         Also, the current emulator settings will be bundled into the
                         launcher app and copied into the sandbox config directory on
                         first launch.
                         Optional.  If ommitted, the launcher app will start the emulator 
                         using its default global config (usually in 
                         ~/Library/Application Support/EmulatorName/).

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
substitutions: RETROAPP_APP_NAME (the -n appName) and BUILD_ROM_NAME the name of the file that provided by -r (basename only)
- Delete the .template files from the staging directory
- Ensure the file [stagingdir]/Contents/MacOS/launch is executable (chmod +x)

Note that this is a rework of retroapp-build.sh.  You can refer to that at a template
but note that the process here is significantly different.  Also refer to templates/stella
for an example of the kind of template we will be processing.



" >&2
  exit 1
}

bundleError() {
  osascript -e "display alert \"RetroApp Bundle Error\" message \"$1\" as critical buttons {\"OK\"} default button \"OK\""
  echo "Error: $1" >&2
}

while getopts "n:e:r:i:o:sbh" opt; do
  case $opt in
    n) RA_APP_NAME="$OPTARG" ;;
    e) RA_EMULATOR_ID="$OPTARG" ;;
    r) RA_ROM_PATH="$OPTARG" ;;
    i) RA_ICNS_PATH="$OPTARG" ;;
    o) RA_OUTPUT_DIR="$OPTARG" ;;
    b) BUILD_BUNDLED_EMULATOR_ENABLED=true ;;
    s) BUILD_BUNDLED_CONFIG_ENABLED=true ;;
    h) usage ;;
    *) usage ;;
  esac
done
# Set defaults if not set by flags
: "${BUILD_BUNDLED_EMULATOR_ENABLED:=false}"
: "${BUILD_BUNDLED_CONFIG_ENABLED:=false}"
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

RA_BUNDLE_TEMPLATE_DIR="$RA_SCRIPT_DIR/bundle"
if [ ! -d "$RA_BUNDLE_TEMPLATE_DIR" ]; then
  echo "Error: bundle template directory not found: $RA_BUNDLE_TEMPLATE_DIR" >&2
  exit 1
fi

RA_LAUNCH_TEMPLATE="$RA_SCRIPT_DIR/emulators/$RA_EMULATOR_ID/launch.template"
if [ ! -f "$RA_LAUNCH_TEMPLATE" ]; then
  echo "Error: no launch.template found for emulator '$RA_EMULATOR_ID' (looked in $RA_LAUNCH_TEMPLATE)" >&2
  exit 1
fi

RA_EMU_INFO="$RA_SCRIPT_DIR/emulators/$RA_EMULATOR_ID/info.sh"
if [ ! -f "$RA_EMU_INFO" ]; then
  echo "Error: no info.sh found for emulator '$RA_EMULATOR_ID' (looked in $RA_EMU_INFO)" >&2
  exit 1
fi
# shellcheck disable=SC1090
. "$RA_EMU_INFO"

RA_ROM_BASENAME=$(basename "$RA_ROM_PATH")
if [ -n "${RA_OUTPUT_DIR:-}" ]; then
  RA_OUTPUT_PATH="${RA_OUTPUT_DIR}/${RA_APP_NAME}.app"
else
  RA_OUTPUT_PATH="$(dirname "$RA_ROM_PATH")/${RA_APP_NAME}.app"
fi

# Export build-time substitution variables for the template processor
export RETROAPP_APP_NAME="$RA_APP_NAME"
export BUILD_GAME_NAME="$RA_APP_NAME"
export BUILD_ROM_NAME="$RA_ROM_BASENAME"
export RETROAPP_EMULATOR_ID="$RA_EMULATOR_ID"

# Create staging area and copy the shared bundle template into it
RA_STAGING_DIR=$(mktemp -d -t retroapp-bundle)
RA_BUNDLE_DIR="$RA_STAGING_DIR/${RA_APP_NAME}.app"
rsync -a --exclude='.DS_Store' "$RA_BUNDLE_TEMPLATE_DIR/" "$RA_BUNDLE_DIR/"

# Install the per-emulator launch template
cp "$RA_LAUNCH_TEMPLATE" "$RA_BUNDLE_DIR/Contents/MacOS/launch.template"

# Source the emulator's bundle.sh to copy the ROM and embed config
RA_EMU_BUNDLE_SH="$RA_SCRIPT_DIR/emulators/$RA_EMULATOR_ID/bundle.sh"
if [ ! -f "$RA_EMU_BUNDLE_SH" ]; then
  echo "Error: no bundle.sh found for emulator '$RA_EMULATOR_ID' (looked in $RA_EMU_BUNDLE_SH)" >&2
  exit 1
fi
BUILD_BUNDLE_DIR="$RA_BUNDLE_DIR"
BUILD_ROM_PATH="$RA_ROM_PATH"
BUILD_BUNDLED_CONFIG_ENABLED="${BUILD_BUNDLED_CONFIG_ENABLED:-true}"
BUILD_BUNDLED_EMULATOR_ENABLED="${BUILD_BUNDLED_EMULATOR_ENABLED:-false}"
# shellcheck disable=SC1090
. "$RA_EMU_BUNDLE_SH"

# Copy icns if provided
if [ -n "${RA_ICNS_PATH:-}" ]; then
  cp "$RA_ICNS_PATH" "$RA_BUNDLE_DIR/Contents/Resources/AppIcon.icns"
fi

# Write the template processor to a temp file.
# It reads RETROAPP_* and EMU_* from the environment, substituting longest keys
# first to avoid partial matches (e.g. RETROAPP_APP_NAME before RETROAPP_APP).
# After substitution, \$ sequences are unescaped to $ (runtime shell variables).
RA_PROCESSOR=$(mktemp /tmp/retroapp-processor-XXXXXX)
cat > "$RA_PROCESSOR" << 'PYEOF'
import sys, os
src, dst = sys.argv[1], sys.argv[2]
content = open(src).read()
for key, val in sorted(os.environ.items(), key=lambda x: -len(x[0])):
    if key.startswith(('RETROAPP_', 'BUILD_')):
        content = content.replace('${' + key + '}', val)
        content = content.replace('$' + key, val)
content = content.replace('\\$', '$')
open(dst, 'w').write(content)
PYEOF

# Process all .template files
find "$RA_BUNDLE_DIR" -name "*.template" | while IFS= read -r template_file; do
  output_file="${template_file%.template}"
  python3 "$RA_PROCESSOR" "$template_file" "$output_file"
  rm "$template_file"
done


rm -f "$RA_PROCESSOR"



# Ensure the launch script is executable
chmod +x "$RA_BUNDLE_DIR/Contents/MacOS/launch"

# Move finished bundle to output location
mv "$RA_BUNDLE_DIR" "$RA_OUTPUT_PATH"
rm -rf "$RA_STAGING_DIR"

echo "Created $RA_OUTPUT_PATH"