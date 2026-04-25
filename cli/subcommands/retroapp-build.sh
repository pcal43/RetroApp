#!/bin/sh

#
# Good source for images
# https://gamesdb.launchbox-app.com/
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
    n) RA_APP_NAME="$OPTARG" ;;
    b) RA_BLUEPRINT="$OPTARG" ;;
    e) RA_EMULATOR_PATH="$OPTARG" ;;
    r) RA_ROMS="$OPTARG"; ;;
    R) RA_LAUNCH_ROM="$OPTARG"; ;;
    i) RA_ICON_IMAGE="$OPTARG" ;;
    o) RA_OUTPUT_DIR="$OPTARG" ;;
    C) RA_CONFIG_TARGET_DIR="$OPTARG" ;;
    c) if [ -n "$OPTARG" ] && [ "$(echo "$OPTARG" | cut -c1)" != "-" ]; then
           RA_CONFIG_SOURCE_DIR="$OPTARG"
         else
           RA_CONFIG_SOURCE_DIR=""
           OPTIND=$((OPTIND - 1))
         fi ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))



if [ -z "${RA_BLUEPRINT:-}" ]; then
  echo "An blueprint must be specified.  Must be one of $($RA_RETROAPP list-blueprints)" >&2
  usage
else
  if ! [ -d "$RA_BLUEPRINTS_DIR/$RA_BLUEPRINT" ]; then
    echo "Invalid blueprint: $RA_BLUEPRINT.  Valid values are $($RA_RETROAPP list-blueprints)" >&2
    usage
  fi
fi



if [ -z "${RA_APP_NAME:-}" ]; then
  echo "An app name must be specified." >&2
  usage
fi

if [ -z "${RA_ROMS:-}" ]; then
  echo "At least one ROM file or folder must be specified" >&2
  usage
fi

# If they specified and icon file, make sure the file exists.
if [ -n "${RA_ICON_IMAGE:-}" ] && [ ! -f "$RA_ICON_IMAGE" ]; then
  echo "No image file found at $RA_ICON_IMAGE" >&2
  exit 1
fi

if [ -n "${RA_OUTPUT_DIR:-}" ]; then
  if [ ! -d "$RA_OUTPUT_DIR" ]; then
    echo "Error: $RA_OUTPUT_DIR is not an existing directory." >&2
    exit 1
  fi
else
  RA_OUTPUT_DIR="$PWD"
fi

# If they didn't specify a path to an emulator, try to find it for them.
# This might fail.
if [ -z "${RA_EMULATOR_PATH:-}" ]; then
  RA_EMULATOR_PATH=$("$RA_RETROAPP" find-emulator "$RA_BLUEPRINT")
fi

# Now validate the emulator they gave us
if [ -d "${RA_EMULATOR_PATH}" ]; then
  # Directory case - must be an .app bundle with Info.plist
  if ! case "${RA_EMULATOR_PATH}" in *.app) true;; *) false;; esac; then
    echo "Error: The emulator directory ${RA_EMULATOR_PATH} is not an .app bundle." >&2
    exit "$EXIT_BAD_EMULATOR"
  fi
  if [ ! -f "${RA_EMULATOR_PATH}/Contents/Info.plist" ]; then
    echo "Error: The emulator at ${RA_EMULATOR_PATH} is not a valid .app bundle (missing Info.plist)." >&2
    exit "$EXIT_BAD_EMULATOR"
  fi
elif [ -f "${RA_EMULATOR_PATH}" ]; then
  # File case - verify it's executable
  if [ ! -x "${RA_EMULATOR_PATH}" ]; then
    echo "Error: The emulator at ${RA_EMULATOR_PATH} is not executable." >&2
    exit "$EXIT_BAD_EMULATOR"
  fi
else
  echo "Error: The emulator path ${RA_EMULATOR_PATH} doesn't exist." >&2
  exit "$EXIT_EMULATOR_NOT_FOUND"
fi

# shellcheck disable=SC1090
# load the BP_xxx metadata for the chosen blueprint
. "$RA_BLUEPRINTS_DIR/$RA_BLUEPRINT/blueprint-info.sh"


if [ -n "${RA_CONFIG_SOURCE_DIR+x}" ] && [ -z "$RA_CONFIG_SOURCE_DIR" ]; then
  # if they specified -c without a path, use the blueprint default
  RA_CONFIG_SOURCE_DIR=$(eval echo "$BP_EMULATOR_CONFIG_DIR")
fi

if [ -n "${RA_CONFIG_SOURCE_DIR:-}" ]; then
  if [ ! -d "$RA_CONFIG_SOURCE_DIR" ]; then
    echo "Error: The config source directory ${RA_CONFIG_SOURCE_DIR} doesn't exist." >&2
    echo "Specify an existing directory or remove the -c option." >&2
    exit "$EXIT_MISSING_DIRECTORY"
  fi

  # If the specified source dir (-c) but not target, go ahead and implicitly enable
  # target to the blueprint default
  if [ -z "${RA_CONFIG_TARGET_DIR+x}" ]; then
    RA_CONFIG_TARGET_DIR=$(eval echo "$BP_EMULATOR_CONFIG_DIR")
  fi
fi



BUNDLE_DIR="$(mktemp -d -t retroapp-build)/${RA_APP_NAME}.app"

buildStandardBundle() {

  # Set up the basic bundle directory structure
  RA_LAUNCH_SCRIPT_PATH="$BUNDLE_DIR/Contents/MacOS/launch"
  RA_BUNDLED_ROMS_PATH="Contents/Resources/Roms"
  RA_BUNDLED_CONFIG_PATH="Contents/Resources/Config"
  RA_BUNDLED_ICON_PATH="Contents/Resources/AppIcon.icns"
  mkdir -p "$BUNDLE_DIR/Contents/MacOS"
  mkdir -p "$BUNDLE_DIR/$RA_BUNDLED_ROMS_PATH"
  mkdir -p "$BUNDLE_DIR/$RA_BUNDLED_CONFIG_PATH"

  # Write the plist file
  cat <<EOF > "$BUNDLE_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>CFBundleExecutable</key>
		<string>launch</string>
		<key>CFBundleIconFile</key>
		<string>AppIcon.icns</string>
		<key>CFBundleInfoDictionaryVersion</key>
		<string>1.0</string>
		<key>CFBundlePackageType</key>
		<string>APPL</string>
		<key>CFBundleSignature</key>
		<string>????</string>
		<key>CFBundleVersion</key>
		<string>1.0</string>
		<key>CFBundleName</key>
		<string>$RA_APP_NAME</string>
		<key>CFBundleDisplayName</key>
		<string>$RA_APP_NAME</string>
	</dict>
</plist>
EOF

  # Use a default icon if none was specified
  if [ -z "${RA_ICON_IMAGE:-}" ]; then
    RA_ICON_IMAGE="$RA_BLUEPRINTS_DIR/$RA_BLUEPRINT/default-icon.png"
    if ! [ -f "${RA_ICON_IMAGE:-}" ]; then
      RA_ICON_IMAGE="$RA_BLUEPRINTS_DIR/default-icon.png"
    fi
  fi

  # Generate an .icns file if an image was specified
  if [ -n "${RA_ICON_IMAGE:-}" ]; then
    if [ "${RA_ICON_IMAGE##*.}" = "icns" ]; then
      cp "$RA_ICON_IMAGE" "$BUNDLE_DIR/$RA_BUNDLED_ICON_PATH"
    else
      "$RA_RETROAPP" icns "$RA_ICON_IMAGE" "$BUNDLE_DIR/$RA_BUNDLED_ICON_PATH"
    fi
  fi


  # FIXME so this bit is better, but you've hosed the case for the UI drag-and-dropping
  # the .app onto a text field.  Need to account for that here.

  # Copy the emulator and make note of the bundled_path
  RA_BUNDLED_EMULATOR_PATH="Contents/MacOS/$(basename "$RA_EMULATOR_PATH")"
  cp -c -r "$RA_EMULATOR_PATH" "$BUNDLE_DIR/$RA_BUNDLED_EMULATOR_PATH"

  # Copy the roms
  if [ -f "$RA_ROMS" ]; then
    cp -c "$RA_ROMS" "$BUNDLE_DIR/$RA_BUNDLED_ROMS_PATH"
  elif [ -d "$RA_ROMS" ]; then
    cp -c -r "$RA_ROMS"/* "$BUNDLE_DIR/$RA_BUNDLED_ROMS_PATH"
  fi

  # find the launch rom
  # shellcheck disable=SC2086 # because we want word splitting here
  RA_BUNDLED_LAUNCH_ROM_PATH="${RA_BUNDLED_ROMS_PATH}/$(findLaunchRom $BP_MAIN_ROM_SEARCH_PATH)"


  #
  # Copy the emulator config
  #
  if [ -n "${RA_CONFIG_SOURCE_DIR:-}" ]; then
    cp -c -r "$RA_CONFIG_SOURCE_DIR" "$BUNDLE_DIR/$RA_BUNDLED_CONFIG_PATH"
  fi

  #
  # Generate the launch script
  #
  if [ -d "$BUNDLE_DIR/$RA_BUNDLED_EMULATOR_PATH" ]; then
    RA_LAUNCH_COMMAND="open \"\$BUNDLE_DIR/${RA_BUNDLED_EMULATOR_PATH}\" --args ${BP_LAUNCH_OPTS:-} \"\$BUNDLE_DIR/${RA_BUNDLED_LAUNCH_ROM_PATH}\""
  elif [ -f "$BUNDLE_DIR/$RA_BUNDLED_EMULATOR_PATH" ]; then
    RA_LAUNCH_COMMAND="\"\$BUNDLE_DIR/${RA_BUNDLED_EMULATOR_PATH}\" ${BP_LAUNCH_OPTS:-} \"\$BUNDLE_DIR/${RA_BUNDLED_LAUNCH_ROM_PATH}\""
  else
    echo "Unexpected error: $RA_BUNDLED_EMULATOR_PATH does not exist" >&2
    exit "$EXIT_UNKNOWN"
  fi

  cat <<EOF > "$RA_LAUNCH_SCRIPT_PATH"
#!/bin/sh
set -x
BUNDLE_DIR="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)/../.."
EOF

  #
  # If they asked for config set up, generate a block that copies it.
  #
  if [ -n "${RA_CONFIG_TARGET_DIR:-}" ]; then
    # Get the current home directory with any trailing slash removed
    CURRENT_HOME=$(echo "$HOME" | sed 's:/$::')
    # Then replace the actual home directory path with $HOME
    RA_CONFIG_TARGET_DIR=$(echo "$RA_CONFIG_TARGET_DIR" | sed "s:^$CURRENT_HOME:\$HOME:g")
    cat <<EOF >> "$RA_LAUNCH_SCRIPT_PATH"
if ! [ -d "${RA_CONFIG_TARGET_DIR}" ]; then
    # If the emulator config directory doesn't exist - if we're running on a
    # new machine, for example - copy our bundled config settings
    # over so that the game is hopefully ready-to-play.
    set +e
    mkdir -p "${RA_CONFIG_TARGET_DIR}"
    cp -c -r "\${BUNDLE_DIR}/${RA_BUNDLED_CONFIG_PATH}/"* "${RA_CONFIG_TARGET_DIR}/"
    set -e
fi
EOF
  fi

  #
  # Finally, generate a line to launch the emulator
  #
  cat <<EOF >> "$RA_LAUNCH_SCRIPT_PATH"
$RA_LAUNCH_COMMAND
EOF

  #
  # Mark the launcher executable and we're done.
  #
  chmod +x "$RA_LAUNCH_SCRIPT_PATH"

  cat "$RA_LAUNCH_SCRIPT_PATH"
}

findLaunchRom() {
    if [ -n "${RA_LAUNCH_ROM:-}" ]; then
        printf "%s" "${RA_LAUNCH_ROM}"
        return 0
    fi

    # Use the ROM directory path directly
    rom_dir="$BUNDLE_DIR/$RA_BUNDLED_ROMS_PATH"

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
#source "$RA_BLUEPRINTS_DIR/$RA_BLUEPRINT/build.sh"

# And give it to them.  We're done.
mv "$BUNDLE_DIR" "$RA_OUTPUT_DIR"

#ls -laR "$RA_OUTPUT_DIR"


