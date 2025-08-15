#!/bin/sh

#
# Good source for images
# https://gamesdb.launchbox-app.com/games/images/5167-ssx
#

usage() {
  echo "Usage: retroapp build [-h] [arguments...]

    -h                   Print this message.

    -n appName           The name of the launcher app to build.
                         Usually just the name of the game.
                         Required.

    -b blueprintName     The type of the app, e.g., nestopia or pcsx2.
                         Run 'retroapp list-blueprints' for a full list.
                         Required.

    -r romsPath          Path to rom file or directory of roms to embed.
                         Required.

    -R launchRomName     Name of rom file to pass to emulator.
                         Optional.  If omitted, RetroApp will attempt to
                         to make an educated guess.

    -e emulatorPath      Path to the emulator application to embed.
                         Optional.  If omitted, RetroApp will attempt
                         to locate an appropriate emulator on your machine.

    -i appIconPath       Path to an image file to use as an app icon.
                         Optional.  If omitted, a default icon will be used.

    -c [configDir]       Enables bundling emulator configuration (e.g.,
                         including BIOS files) into the launcher app.

                         If -c is set without a path, an educated guess will
                         be made about where the emulator stores its settings.
                         (usually under ~/Library/Application Support/).

                         Optional.  Somewhat pointless unless -C is also set.

    -C [configDir]       Enables unbundling of default emulator config
                         settings (e.g., BIOS files) when the app is run on a
                         new machine.  This step will be skipped if the targetPath
                         already exists on the machine (i.e., if the emulator
                         has been run before).

                         If -c is set without a path, an educated guess will
                         be made about where the emulator stores its settings.
                         (usually under ~/Library/Application Support/).

                         If a path *is* set, the value \$HOME should be used
                         to specify the user's home directory at runtime, e.g.,

                           -C \$HOME/Library/Application\ Support/Castlevania

                         As shown in the example above, it is possible to use
                         this flag to enable per-game config settings.  However,
                         this is not supported by all emulators, in which case,
                         settings unbundles into a settings directory other than
                         the emulator's default will be ignored.

                         Optional.  Somewhat pointless unless -c is also set.
  " >&2
  exit 1
}

exit_emulatorNotFound() {
    echo "Error: could not find ${1:-} on your machine.  Please install it or specify its location manually." >&2
    exit 80
}

while getopts "n:t:e:b:r:R:i:o:c:C:h" opt; do
  case $opt in
    n) CLI_APP_NAME="$OPTARG" ;;
    b) CLI_BLUEPRINT="$OPTARG" ;;
    e) CLI_EMULATOR_PATH="$OPTARG" ;;
    r) CLI_ROMS="$OPTARG"; ;;
    R) CLI_LAUNCH_ROM="$OPTARG"; ;;
    i) CLI_ICON_IMAGE="$OPTARG" ;;
    o) CLI_OUTPUT_DIR="$OPTARG" ;;
    C) CLI_CONFIG_TARGET_DIR="$OPTARG" ;;
    c) if [ -n "$OPTARG" ] && [ "$(echo "$OPTARG" | cut -c1)" != "-" ]; then
           CLI_CONFIG_SOURCE_DIR="$OPTARG"
         else
           CLI_CONFIG_SOURCE_DIR=""
           OPTIND=$((OPTIND - 1))
         fi ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))



if [ -z "${CLI_BLUEPRINT:-}" ]; then
  echo "An blueprint must be specified.  Must be one of $($RA_RETROAPP list-blueprints)" >&2
  usage
else
  if ! [ -d "$RA_BLUEPRINTS_DIR/$CLI_BLUEPRINT" ]; then
    echo "Invalid blueprint: $CLI_BLUEPRINT.  Valid values are $($RA_RETROAPP list-blueprints)" >&2
    usage
  fi
fi



if [ -z "${CLI_APP_NAME:-}" ]; then
  echo "An app name must be specified." >&2
  usage
fi

if [ -z "${CLI_ROMS:-}" ]; then
  echo "At least one ROM file or folder must be specified" >&2
  usage
fi

# If they specified and icon file, make sure the file exists.
if [ -n "${CLI_ICON_IMAGE:-}" ] && [ ! -f "$CLI_ICON_IMAGE" ]; then
  echo "No image file found at $CLI_ICON_IMAGE" >&2
  exit 1
fi

if [ -n "${CLI_OUTPUT_DIR:-}" ]; then
  if [ ! -d "$CLI_OUTPUT_DIR" ]; then
    echo "Error: $CLI_OUTPUT_DIR is not an existing directory." >&2
    exit 1
  fi
else
  CLI_OUTPUT_DIR="$PWD"
fi

# If they didn't specify a path to an emulator, try to find it for them.
# This might fail.
if [ -z "${CLI_EMULATOR_PATH:-}" ]; then
  CLI_EMULATOR_PATH=$("$RA_RETROAPP" find-emulator "$CLI_BLUEPRINT")
fi

# Now validate the emulator they gave us
if [ -d "${CLI_EMULATOR_PATH}" ]; then
  # Directory case - must be an .app bundle with Info.plist
  if ! case "${CLI_EMULATOR_PATH}" in *.app) true;; *) false;; esac; then
    echo "Error: The emulator directory ${CLI_EMULATOR_PATH} is not an .app bundle." >&2
    exit "$EXIT_BAD_EMULATOR"
  fi
  if [ ! -f "${CLI_EMULATOR_PATH}/Contents/Info.plist" ]; then
    echo "Error: The emulator at ${CLI_EMULATOR_PATH} is not a valid .app bundle (missing Info.plist)." >&2
    exit "$EXIT_BAD_EMULATOR"
  fi
elif [ -f "${CLI_EMULATOR_PATH}" ]; then
  # File case - verify it's executable
  if [ ! -x "${CLI_EMULATOR_PATH}" ]; then
    echo "Error: The emulator at ${CLI_EMULATOR_PATH} is not executable." >&2
    exit "$EXIT_BAD_EMULATOR"
  fi
else
  echo "Error: The emulator path ${CLI_EMULATOR_PATH} doesn't exist." >&2
  exit "$EXIT_EMULATOR_NOT_FOUND"
fi

# shellcheck disable=SC1090
# load the BP_xxx metadata for the chosen blueprint
. "$RA_BLUEPRINTS_DIR/$CLI_BLUEPRINT/blueprint-info.sh"


if [ -n "${CLI_CONFIG_SOURCE_DIR+x}" ] && [ -z "$CLI_CONFIG_SOURCE_DIR" ]; then
  # if they specified -c without a path, use the blueprint default
  CLI_CONFIG_SOURCE_DIR=$(eval echo "$BP_EMULATOR_CONFIG_DIR")
fi

if [ -n "${CLI_CONFIG_SOURCE_DIR:-}" ]; then
  if [ ! -d "$CLI_CONFIG_SOURCE_DIR" ]; then
    echo "Error: The config source directory ${CLI_CONFIG_SOURCE_DIR} doesn't exist." >&2
    echo "Specify an existing directory or remove the -c option." >&2
    exit "$EXIT_MISSING_DIRECTORY"
  fi

  # If the specified source dir (-c) but not target, go ahead and implicitly enable
  # target to the blueprint default
  if [ -z "${CLI_CONFIG_TARGET_DIR+x}" ]; then
    CLI_CONFIG_TARGET_DIR=$(eval echo "$BP_EMULATOR_CONFIG_DIR")
  fi
fi



BUNDLE_DIR="$(mktemp -d -t retroapp-build)/${CLI_APP_NAME}.app"

buildStandardBundle() {

  # Set up the basic bundle directory structure
  CLI_LAUNCH_SCRIPT_PATH="$BUNDLE_DIR/Contents/MacOS/launch"
  CLI_BUNDLED_ROMS_PATH="Contents/Resources/Roms"
  CLI_BUNDLED_CONFIG_PATH="Contents/Resources/Config"
  mkdir -p "$BUNDLE_DIR/Contents/MacOS"
  mkdir -p "$BUNDLE_DIR/$CLI_BUNDLED_ROMS_PATH"
  mkdir -p "$BUNDLE_DIR/$CLI_BUNDLED_CONFIG_PATH"

  # Write the plist file
  cat <<EOF > "$BUNDLE_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>CFBundleExecutable</key>
		<string>launch</string>
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
      cp "${CLI_ICON_IMAGE}" "$BUNDLE_DIR/Contents/Resources/icon.icns"
    else
      "$RA_RETROAPP" make-icon "${CLI_ICON_IMAGE}" "$BUNDLE_DIR/Contents/Resources/icon.icns"
    fi
  fi


  # FIXME so this bit is better, but you've hosed the case for the UI drag-and-dropping
  # the .app onto a text field.  Need to account for that here.

  # Copy the emulator and make note of the bundled_path
  CLI_BUNDLED_EMULATOR_PATH="Contents/MacOS/$(basename "$CLI_EMULATOR_PATH")"
  cp -c -r "$CLI_EMULATOR_PATH" "$BUNDLE_DIR/$CLI_BUNDLED_EMULATOR_PATH"

  # Copy the roms
  if [ -f "$CLI_ROMS" ]; then
    cp -c "$CLI_ROMS" "$BUNDLE_DIR/$CLI_BUNDLED_ROMS_PATH"
  elif [ -d "$CLI_ROMS" ]; then
    cp -c -r "$CLI_ROMS"/* "$BUNDLE_DIR/$CLI_BUNDLED_ROMS_PATH"
  fi

  # find the launch rom
  # shellcheck disable=SC2086 # because we want word splitting here
  CLI_BUNDLED_LAUNCH_ROM_PATH="${CLI_BUNDLED_ROMS_PATH}/$(findLaunchRom $BP_MAIN_ROM_SEARCH_PATH)"


  #
  # Copy the emulator config
  #
  if [ -n "${CLI_CONFIG_SOURCE_DIR:-}" ]; then
    cp -c -r "$CLI_CONFIG_SOURCE_DIR" "$BUNDLE_DIR/$CLI_BUNDLED_CONFIG_PATH"
  fi

  #
  # Generate the launch script
  #
  if [ -d "$BUNDLE_DIR/$CLI_BUNDLED_EMULATOR_PATH" ]; then
    CLI_LAUNCH_COMMAND="open \"\$BUNDLE_DIR/${CLI_BUNDLED_EMULATOR_PATH}\" --args ${BP_LAUNCH_OPTS:-} \"\$BUNDLE_DIR/${CLI_BUNDLED_LAUNCH_ROM_PATH}\""
  elif [ -f "$BUNDLE_DIR/$CLI_BUNDLED_EMULATOR_PATH" ]; then
    CLI_LAUNCH_COMMAND="\"\$BUNDLE_DIR/${CLI_BUNDLED_EMULATOR_PATH}\" ${BP_LAUNCH_OPTS:-} \"\$BUNDLE_DIR/${CLI_BUNDLED_LAUNCH_ROM_PATH}\""
  else
    echo "Unexpected error: $CLI_BUNDLED_EMULATOR_PATH does not exist" >&2
    exit "$EXIT_UNKNOWN"
  fi

  cat <<EOF > "$CLI_LAUNCH_SCRIPT_PATH"
#!/bin/sh
set -x
BUNDLE_DIR="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)/../.."
EOF

  #
  # If they asked for config set up, generate a block that copies it.
  #
  if [ -n "${CLI_CONFIG_TARGET_DIR:-}" ]; then
    # Get the current home directory with any trailing slash removed
    CURRENT_HOME=$(echo "$HOME" | sed 's:/$::')
    # Then replace the actual home directory path with $HOME
    CLI_CONFIG_TARGET_DIR=$(echo "$CLI_CONFIG_TARGET_DIR" | sed "s:^$CURRENT_HOME:\$HOME:g")
    cat <<EOF >> "$CLI_LAUNCH_SCRIPT_PATH"
if ! [ -d "${CLI_CONFIG_TARGET_DIR}" ]; then
    set +e
    mkdir -p "${CLI_CONFIG_TARGET_DIR}"
    cp -r "\${BUNDLE_DIR}/${CLI_BUNDLED_CONFIG_PATH}/"* "${CLI_CONFIG_TARGET_DIR}/"
    set -e
fi
EOF
  fi

  #
  # Finally, generate a line to launch the emulator
  #
  cat <<EOF >> "$CLI_LAUNCH_SCRIPT_PATH"
$CLI_LAUNCH_COMMAND
EOF



  chmod +x "$CLI_LAUNCH_SCRIPT_PATH"

  cat "$CLI_LAUNCH_SCRIPT_PATH"
}

findLaunchRom() {
    if [ -n "${CLI_LAUNCH_ROM:-}" ]; then
        printf "%s" "${CLI_LAUNCH_ROM}"
        return 0
    fi

    # Use the ROM directory path directly
    rom_dir="$BUNDLE_DIR/$CLI_BUNDLED_ROMS_PATH"

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


buildStandardBundle

# Now run the blueprint build code to do emulator-specific stuff
#source "$RA_BLUEPRINTS_DIR/$CLI_BLUEPRINT/build.sh"

# And give it to them.  We're done.
mv "$BUNDLE_DIR" "$CLI_OUTPUT_DIR"

#ls -laR "$CLI_OUTPUT_DIR"


