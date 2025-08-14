#!/bin/sh

#
# Good source for images
# https://gamesdb.launchbox-app.com/games/images/5167-ssx
#

usage() {
  echo "Usage: retroapp build [-n appName] [-b blueprint] [-e emulator] [-i icon] [-r roms] [-R launchRom]" >&2
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
    r) CLI_ROMS="$OPTARG"; ;;
    R) CLI_LAUNCH_ROM="$OPTARG"; ;;
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
  echo "At least one ROM file or folder must be specified" >&2
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

CLI_EMULATOR_BASENAME=$(basename "$CLI_EMULATOR_PATH")
CLI_PACKAGED_EMULATOR_PATH="Contents/MacOS/$CLI_EMULATOR_BASENAME"
CLI_PACKAGED_ROMS_PATH="Contents/Resources/Roms"
CLI_PACKAGED_CONFIG_PATH="Contents/Resources/Config"


buildStandardBundle() {

  # Set up the basic bundle directory structure
  mkdir -p "$APP_DIR/Contents/MacOS"
  mkdir -p "$APP_DIR/$CLI_PACKAGED_ROMS_PATH"
  mkdir -p "$APP_DIR/$CLI_PACKAGED_CONFIG_PATH"

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

  # Copy the emulator
  cp -c -r "$CLI_EMULATOR_PATH" "$APP_DIR/$CLI_PACKAGED_EMULATOR_PATH"

  # Copy the roms
  if [ -f "$CLI_ROMS" ]; then
      cp -c "$CLI_ROMS" "$APP_DIR/$CLI_PACKAGED_ROMS_PATH"
  elif [ -d "$CLI_ROMS" ]; then
      cp -c -r "$CLI_ROMS"/* "$APP_DIR/$CLI_PACKAGED_ROMS_PATH"
  fi

  ls -laR "$APP_DIR"
}

findLaunchRom() {
    if [ -n "${LAUNCH_ROM:-}" ]; then
        printf "%s" "${LAUNCH_ROM}"
        return 0
    fi

    # Use the ROM directory path directly
    rom_dir="$APP_DIR/$CLI_PACKAGED_ROMS_PATH"

    # Process all arguments
    for cmd do
        if [ "$cmd" != "${cmd%/*}" ]; then
            # If the expression contains any slashes, assume it's a direct file path
            if [ "$cmd" != "${cmd%\**}" ]; then
                # cmd contains an asterisk, treat as a glob pattern
                # Change to the ROM directory to use shell globbing
                old_pwd=$(pwd)
                cd "$rom_dir" || return 1

                # Use shell globbing directly instead of find
                # Count matches first
                match_count=0
                last_match=""
                for match in $cmd; do
                    if [ -e "$match" ]; then
                        match_count=$((match_count + 1))
                        last_match="$match"
                    fi
                done

                if [ "$match_count" -eq 0 ]; then
                    # No matches
                    cd "$old_pwd" || true
                elif [ "$match_count" -eq 1 ]; then
                    # Exactly one match
                    cd "$old_pwd" || true
                    printf "%s" "$last_match"
                    return 0
                else
                    # Multiple matches - error
                    cd "$old_pwd" || true
                    echo "Error: Multiple ROM files match pattern '$cmd'. Please specify a launch rom with -R." >&2
                    exit "$EXIT_AMBIGUOUS_LAUNCH_ROM"
                fi

                cd "$old_pwd" || true
            else
                # No glob pattern, just check if file exists directly
                if [ -e "$rom_dir/$cmd" ]; then
                    printf "%s" "$cmd"
                    return 0
                fi
            fi
        else
            # For simple filenames without paths, check if the file exists
            if [ -e "$rom_dir/$cmd" ]; then
                printf "%s" "$cmd"
                return 0
            fi

            # Also check for patterns like *.nes (no directory part)
            if [ "$cmd" != "${cmd%\**}" ]; then
                old_pwd=$(pwd)
                cd "$rom_dir" || return 1

                # Count matches first
                match_count=0
                last_match=""
                for match in $cmd; do
                    if [ -e "$match" ]; then
                        match_count=$((match_count + 1))
                        last_match="$match"
                    fi
                done

                if [ "$match_count" -eq 0 ]; then
                    # No matches
                    cd "$old_pwd" || true
                elif [ "$match_count" -eq 1 ]; then
                    # Exactly one match
                    cd "$old_pwd" || true
                    printf "%s" "$last_match"
                    return 0
                else
                    # Multiple matches - error
                    cd "$old_pwd" || true
                    echo "Error: Multiple ROM files match pattern '$cmd'. Please be more specific." >&2
                    exit "$EXIT_NEED_LAUNCH_ROM"
                fi

                cd "$old_pwd" || true
            fi
        fi
    done

    echo "Could not determine which ROM to launch with. Please specify one with -R." >&2
    exit "$EXIT_NEED_LAUNCH_ROM"
}

# Now run the blueprint build code to do emulator-specific stuff
source "$RA_BLUEPRINTS_DIR/$CLI_BLUEPRINT/build.sh"

# Make sure it's executable
chmod +x "$APP_DIR/Contents/MacOS/run"

# And give it to them.  We're done.
mv "$APP_DIR" "$CLI_OUTPUT_DIR"




