#!/bin/zsh

# Good source for images
# https://gamesdb.launchbox-app.com/
#
usage() {
	echo "Usage: retroapp build [-h] [options...]"
	# ...rest of usage text from retroapp-bundle.sh...
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
		s) BUILD_SANDBOXED_CONFIG_ENABLED=true ;;
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

BUILD_BUNDLE_TEMPLATE_DIR="$RA_SCRIPT_DIR/bundle"
if [ ! -d "$BUILD_BUNDLE_TEMPLATE_DIR" ]; then
	echo "Error: bundle template directory not found: $BUILD_BUNDLE_TEMPLATE_DIR" >&2
	exit 1
fi

BUILD_LAUNCH_TEMPLATE="$RA_SCRIPT_DIR/emulators/$BUILD_EMULATOR_ID/launch.template"
if [ ! -f "$BUILD_LAUNCH_TEMPLATE" ]; then
	echo "Error: no launch.template found for emulator '$BUILD_EMULATOR_ID' (looked in $BUILD_LAUNCH_TEMPLATE)" >&2
	exit 1
fi

BUILD_EMU_INFO="$RA_SCRIPT_DIR/emulators/$BUILD_EMULATOR_ID/info.sh"
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
cp "$BUILD_LAUNCH_TEMPLATE" "$BUILD_BUNDLE_DIR/Contents/MacOS/launch.template"

# Source the emulator's bundle.sh to copy the ROM and embed config
BUILD_EMU_BUNDLE_SH="$RA_SCRIPT_DIR/emulators/$BUILD_EMULATOR_ID/bundle.sh"
if [ ! -f "$BUILD_EMU_BUNDLE_SH" ]; then
	echo "Error: no bundle.sh found for emulator '$BUILD_EMULATOR_ID' (looked in $BUILD_EMU_BUNDLE_SH)" >&2
	exit 1
fi
# Set up build-time variables for bundle.sh
BUILD_BUNDLE_DIR="$BUILD_BUNDLE_DIR"
BUILD_ROM_PATH="$BUILD_ROM_PATH"
BUILD_SANDBOXED_CONFIG_ENABLED="${BUILD_SANDBOXED_CONFIG_ENABLED:-true}"
BUILD_BUNDLED_EMULATOR_ENABLED="${BUILD_BUNDLED_EMULATOR_ENABLED:-false}"
# shellcheck disable=SC1090
. "$BUILD_EMU_BUNDLE_SH"

# Copy icns if provided
if [ -n "${BUILD_ICNS_PATH:-}" ]; then
	cp "$BUILD_ICNS_PATH" "$BUILD_BUNDLE_DIR/Contents/Resources/AppIcon.icns"
fi

BUILD_PROCESSOR=$(mktemp /tmp/retroapp-processor-XXXXXX)
cat > "$BUILD_PROCESSOR" << 'PYEOF'
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

find "$BUILD_BUNDLE_DIR" -name "*.template" | while IFS= read -r template_file; do
	output_file="${template_file%.template}"
	python3 "$BUILD_PROCESSOR" "$template_file" "$output_file"
	rm "$template_file"
done

rm -f "$BUILD_PROCESSOR"



# Ensure the launch script is executable
chmod +x "$BUILD_BUNDLE_DIR/Contents/MacOS/launch"

# Move finished bundle to output location
mv "$BUILD_BUNDLE_DIR" "$BUILD_OUTPUT_PATH"
rm -rf "$BUILD_STAGING_DIR"

echo "Created $BUILD_OUTPUT_PATH"
#!/bin/zsh

# ...existing code...
