#!/bin/zsh

# Good source for images
# https://gamesdb.launchbox-app.com/
#
usage() {
	echo "Usage: retroapp build [-h] [options...]"
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

    -s systemId          The id of the sytem that the ROM runs on, e.g. 'nes' or 'atari2600'.
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

    -c                   Sandbox the emulator configuration for this game.  If enabled,
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
"
}

bundleError() {
	osascript -e "display alert \"RetroApp Build Error\" message \"$1\" as critical buttons {\"OK\"} default button \"OK\""
	echo "Error: $1" >&2
}

# Parse options and assign to BUILD_ variables
while getopts "n:e:r:i:o:sbh" opt; do
	case $opt in
		n) BUILD_APP_NAME="$OPTARG" ;;
		e) BUILD_EMULATOR_ID="$OPTARG" ;;
		r) BUILD_ROM_PATH="$OPTARG" ;;
		i) BUILD_ICNS_PATH="$OPTARG" ;;
		o) BUILD_OUTPUT_DIR="$OPTARG" ;;
		b) BUILD_BUNDLED_EMULATOR_ENABLED=true ;;
		c) BUILD_SANDBOXED_CONFIG_ENABLED=true ;;
		h) usage ;;
		*) usage ;;
	esac
done
# Set defaults if not set by flags
 : "${BUILD_BUNDLED_EMULATOR_ENABLED:=false}"
 : "${BUILD_SANDBOXED_CONFIG_ENABLED:=false}"
shift $((OPTIND - 1))
if [ -z "${BUILD_APP_NAME:-}" ]; then
	echo "Error: -n appName is required." >&2
	usage
fi
if [ -z "${BUILD_EMULATOR_ID:-}" ]; then
	echo "Error: -e emulatorId is required." >&2
	usage
fi

if [ -z "${BUILD_ROM_PATH:-}" ]; then
	echo "Error: -r romPath is required." >&2
	usage
fi
if [ ! -f "$BUILD_ROM_PATH" ]; then
	echo "Error: ROM file not found: $BUILD_ROM_PATH" >&2
	exit 1
fi
if [ -n "${BUILD_ICNS_PATH:-}" ] && [ ! -f "$BUILD_ICNS_PATH" ]; then
	echo "Error: icon file not found: $BUILD_ICNS_PATH" >&2
	exit 1
fi

if [ -z "${BUILD_SYSTEM_ID:-}" ]; then
    echo "Error: -s systemId is required." >&2
    usage
fi
BUILD_BUNDLE_TEMPLATE_DIR="$RA_SCRIPT_DIR/bundle"
if [ ! -d "$BUILD_BUNDLE_TEMPLATE_DIR" ]; then
	echo "Error: bundle template directory not found: $BUILD_BUNDLE_TEMPLATE_DIR" >&2
	exit 1
fi

BUILD_LAUNCH_TEMPLATE="$RA_SCRIPT_DIR/emulators/$BUILD_EMULATOR_ID/launch.m4"
if [ ! -f "$BUILD_LAUNCH_TEMPLATE" ]; then
	echo "Error: no launch.m4 found for emulator '$BUILD_EMULATOR_ID' (looked in $BUILD_LAUNCH_TEMPLATE)" >&2
	exit 1
fi

BUILD_EMU_INFO="$RA_SCRIPT_DIR/emulators/$BUILD_EMULATOR_ID/info.sh"
# Source system metadata
BUILD_SYSTEM_INFO="$RA_SCRIPT_DIR/systems/$BUILD_SYSTEM_ID/info.sh"
if [ ! -f "$BUILD_SYSTEM_INFO" ]; then
    echo "Error: no info.sh found for system '$BUILD_SYSTEM_ID' (looked in $BUILD_SYSTEM_INFO)" >&2
    exit 1
fi
# shellcheck disable=SC1090
. "$BUILD_SYSTEM_INFO"
if [ ! -f "$BUILD_EMU_INFO" ]; then
	echo "Error: no info.sh found for emulator '$BUILD_EMULATOR_ID' (looked in $BUILD_EMU_INFO)" >&2
	exit 1
fi
# shellcheck disable=SC1090
. "$BUILD_EMU_INFO"

BUILD_ROM_BASENAME=$(basename "$BUILD_ROM_PATH")
if [ -n "${BUILD_OUTPUT_DIR:-}" ]; then
	BUILD_OUTPUT_PATH="${BUILD_OUTPUT_DIR}/${BUILD_APP_NAME}.app"
else
	BUILD_OUTPUT_PATH="$(dirname "$BUILD_ROM_PATH")/${BUILD_APP_NAME}.app"
fi

# Export build-time substitution variables for the template processor
export RETROAPP_APP_NAME="$BUILD_APP_NAME"
export BUILD_GAME_NAME="$BUILD_APP_NAME"
export BUILD_ROM_NAME="$BUILD_ROM_BASENAME"
export RETROAPP_EMULATOR_ID="$BUILD_EMULATOR_ID"

# Create staging area and copy the shared bundle template into it
BUILD_STAGING_DIR=$(mktemp -d -t retroapp-bundle)
BUILD_BUNDLE_DIR="$BUILD_STAGING_DIR/${BUILD_APP_NAME}.app"
rsync -a --exclude='.DS_Store' "$BUILD_BUNDLE_TEMPLATE_DIR/" "$BUILD_BUNDLE_DIR/"

# Install the per-emulator launch template
mkdir -p "$BUILD_BUNDLE_DIR/Contents/MacOS/"
cp "$BUILD_LAUNCH_TEMPLATE" "$BUILD_BUNDLE_DIR/Contents/MacOS/launch.m4"

# Source the emulator's bundle.sh to copy the ROM and embed config
BUILD_EMU_BUNDLE_SH="$RA_SCRIPT_DIR/emulators/$BUILD_EMULATOR_ID/bundle.sh"
if [ ! -f "$BUILD_EMU_BUNDLE_SH" ]; then
	echo "Error: no bundle.sh found for emulator '$BUILD_EMULATOR_ID' (looked in $BUILD_EMU_BUNDLE_SH)" >&2
	exit 1
fi
# Set up build-time variables for bundle.sh
BUILD_BUNDLE_DIR="$BUILD_BUNDLE_DIR"
BUILD_ROM_PATH="$BUILD_ROM_PATH"
BUILD_RETROAPPS_SUPPORT_PATH="\$HOME/Application Support/RetroApp"
BUILD_SANDBOXED_CONFIG_ENABLED="${BUILD_SANDBOXED_CONFIG_ENABLED:-true}"
BUILD_BUNDLED_EMULATOR_ENABLED="${BUILD_BUNDLED_EMULATOR_ENABLED:-false}"
# shellcheck disable=SC1090
. "$BUILD_EMU_BUNDLE_SH"

# Copy icns if provided
if [ -n "${BUILD_ICNS_PATH:-}" ]; then
	cp "$BUILD_ICNS_PATH" "$BUILD_BUNDLE_DIR/Contents/Resources/AppIcon.icns"
fi


# Process all .m4 files using m4
find "$BUILD_BUNDLE_DIR" -name "*.m4" | while IFS= read -r template_file; do
	output_file="${template_file%.m4}"
	m4 \
		-DM4_GAME_NAME="$BUILD_GAME_NAME" \
		-DM4_ROM_NAME="$BUILD_ROM_NAME" \
		-DM4_RETROAPPS_SUPPORT_PATH="$BUILD_RETROAPPS_SUPPORT_PATH" \
		-DM4_ARES_SYSTEM="${SYS_ARES_NAME:-}""" \
		$( [ "$BUILD_SANDBOXED_CONFIG_ENABLED" = true ] && echo "-DM4_SANDBOXED_CONFIG_ENABLED=1" ) \
		$( [ "$BUILD_BUNDLED_EMULATOR_ENABLED" = true ] && echo "-DM4_BUNDLED_EMULATOR_ENABLED=1" ) \
		"$template_file" > "$output_file"
	rm "$template_file"
done



# Ensure the launch script is executable
chmod +x "$BUILD_BUNDLE_DIR/Contents/MacOS/launch"

# Move finished bundle to output location
mv "$BUILD_BUNDLE_DIR" "$BUILD_OUTPUT_PATH"
rm -rf "$BUILD_STAGING_DIR"

echo "Created $BUILD_OUTPUT_PATH"
#!/bin/zsh

# ...existing code...
