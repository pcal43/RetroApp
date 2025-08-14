#!/bin/sh

#
# Good source for images
# https://gamesdb.launchbox-app.com/games/images/5167-ssx
#

usage() {
  echo "Usage: retroapp build [-e emulator] [-i icon] [roms...]" >&2
  exit 1
}

exit_emulatorNotFound() {
    echo "Error: could not find ${1:-} on your machine.  Please install it or specify its location manually."
    exit 80
}

while getopts "n:t:e:b:r:i:o:h" opt; do
  case $opt in
    n) CLI_APP_NAME="$OPTARG" ;;
    b) CLI_BLUEPRINT="$OPTARG" ;;
    e) CLI_EMULATOR_PATH="$OPTARG" ;;
    r) if [ -z "${ROMS:-}" ]; then CLI_ROMS="$OPTARG"; else CLI_ROMS="$ROMS:$OPTARG"; fi ;;
    i) CLI_ICON_IMAGE="$OPTARG" ;;
    o) CLI_OUTPUT_DIR="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))


if [ -z "${CLI_APP_NAME:-}" ]; then
  echo "An app name must be specified." >&2
  usage
fi

if [ -n "${CLI_OUTPUT_DIR:-}" ]; then
  if [ ! -d "$CLI_OUTPUT_DIR" ]; then
    echo "Error: $CLI_OUTPUT_DIR is not an existing directory." >&2
    exit 1
  fi
else
  CLI_OUTPUT_DIR="$PWD"
fi

if [ -z "${CLI_ROMS:-}" ]; then
  echo "At least one ROM file must be specified" >&2
  usage
fi

if [ -z "${CLI_BLUEPRINT:-}" ]; then
  echo "An blueprint must be specified.  Must be one of $($RA_RETROAPP list-blueprints)" >&2
  usage
else
  if ! [ -d "$RA_BLUEPRINTS_DIR/$CLI_BLUEPRINT" ]; then
    echo "Invalid blueprint: $CLI_BLUEPRINT.  Valid values are $($RA_RETROAPP list-blueprints)"
    usage
  fi
fi

# If they specified and icon file, make sure the file exists.
if [ -n "${CLI_ICON_IMAGE:-}" ] && [ ! -f "$CLI_ICON_IMAGE" ]; then
  echo "No image file found at $CLI_ICON_IMAGE"
  exit 1
fi

# If they didn't specify a path to an emulator, try to find it for them.
# This might fail.
if [ -z "${CLI_EMULATOR_PATH:-}" ]; then
  CLI_EMULATOR_PATH=$("$RA_RETROAPP" find-emulator "$CLI_BLUEPRINT")
fi

TMP_DIR=$(mktemp -d -t retroapp-build)
APP_DIR="$TMP_DIR/${CLI_APP_NAME}.app"

buildStandardBundle() {

  # Set up the basic bundle directory structure
  mkdir -p "$APP_DIR/Contents/Resources"
  mkdir -p "$APP_DIR/Contents/MacOS"

  # Write the plist file
  cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>CFBundleExecutable</key>
		<string>run</string>
		<key>CFBundleIconFile</key>
		<string>icon.icns</string>
		<key>CFBundleInfoDictionaryVersion</key>
		<string>1.0</string>
		<key>CFBundlePackageType</key>
		<string>APPL</string>
		<key>CFBundleSignature</key>
		<string>????</string>
		<key>CFBundleVersion</key>
		<string>1.0</string>
		<key>CFBundleName</key>
		<string>$CLI_APP_NAME</string>
		<key>CFBundleDisplayName</key>
		<string>$CLI_APP_NAME</string>
	</dict>
</plist>
EOF

  # Use a default icon if none was specified
  if [ -z "${CLI_ICON_IMAGE:-}" ]; then
    CLI_ICON_IMAGE="$RA_BLUEPRINTS_DIR/$CLI_BLUEPRINT/default-icon.png"
    if ! [ -f "${CLI_ICON_IMAGE:-}" ]; then
      CLI_ICON_IMAGE="$RA_BLUEPRINTS_DIR/default-default-icon.png"
    fi
  fi

  # Generate an .icns file if an image was specified
  if [ -n "${CLI_ICON_IMAGE:-}" ]; then
    if [ "${CLI_ICON_IMAGE##*.}" = "icns" ]; then
      cp "${CLI_ICON_IMAGE}" "$APP_DIR/Contents/Resources/icon.icns"
    else
      "$RA_RETROAPP" make-icon "${CLI_ICON_IMAGE}" "$APP_DIR/Contents/Resources/icon.icns"
    fi
  fi

  # Copy the roms
  IFS=:
  set -- $CLI_ROMS
  for SRC_PATH; do
      BASE_NAME=$(basename "$SRC_PATH")
      if [ -z ${CLI_MAIN_ROM:-} ]; then
          CLI_MAIN_ROM=$BASE_NAME
      fi
      cp -r "$SRC_PATH" "$APP_DIR/Contents/Resources/$BASE_NAME"
  done
}

# Now run the blueprint build code to do emulator-specific stuff
source "$RA_BLUEPRINTS_DIR/$CLI_BLUEPRINT/build.sh"

# Make sure it's executable
chmod +x "$APP_DIR/Contents/MacOS/run"

# And give it to them.  We're done.
mv "$APP_DIR" "$CLI_OUTPUT_DIR"




