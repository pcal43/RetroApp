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

    -c [settingsDir]     Enables bundling emulator config settings (e.g.,
                         including BIOS files) into the launcher app.

                         If -c is set without a path, an educated guess will
                         be made about where the emulator stores its settings.
                         (usually under ~/Library/Application Support/).

                         Optional.  Somewhat pointless unless -C is also set.

    -C [settingsDir]     Enables unbundling of default emulator config
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
    echo "Error: could not find ${1:-} on your machine.  Please install it or specify its location manually."
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
    echo "Invalid blueprint: $CLI_BLUEPRINT.  Valid values are $($RA_RETROAPP list-blueprints)"
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
  echo "No image file found at $CLI_ICON_IMAGE"
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

# shellcheck disable=SC1090
# load the BP_xxx metadata for the chosen blueprint
. "$RA_BLUEPRINTS_DIR/$CLI_BLUEPRINT/blueprint-info.sh"

if [ -n "${CLI_CONFIG_SOURCE_DIR+x}" ] && [ -z "$CLI_CONFIG_SOURCE_DIR" ]; then
  # if they specified -c without a path, use the blueprint default
  CLI_CONFIG_SOURCE_DIR=$(eval echo "$BP_EMULATOR_SETTINGS_DIR")
fi



TMP_DIR=$(mktemp -d -t retroapp-build)
APP_DIR="$TMP_DIR/${CLI_APP_NAME}.app"

buildStandardBundle() {

  # Set up the basic bundle directory structure
  CLI_RUN_SCRIPT_PATH="$APP_DIR/Contents/MacOS/run"
  CLI_PACKAGED_ROMS_PATH="Contents/Resources/Roms"
  CLI_PACKAGED_CONFIG_PATH="Contents/Resources/Config"
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


  # FIXME so this bit is better, but you've hosed the case for the UI drag-and-dropping
  # the .app onto a text field.  Need to account for that here.

  # Copy the emulator. But first check if the emulator binary is part of an app bundle
  case "$CLI_EMULATOR_PATH" in
    *".app/"*)
      # If it is, copy the whole bundle - everything inside the .app.
      CLI_EMULATOR_BUNDLE_PATH=$(echo "$CLI_EMULATOR_PATH" | sed 's/\(.*\.app\).*/\1/')
      cp -c -r "$CLI_EMULATOR_BUNDLE_PATH" "$APP_DIR/Contents/MacOS/"
      # Now we need the packaged emulator path to point to the binary inside
      # the copied bundle - basically the .app and everything after it.
      CLI_PACKAGED_EMULATOR_PATH="Contents/MacOS/$(echo "$CLI_EMULATOR_PATH" | sed -E 's|.*/([^/]*\.app/.*)|\1|')"
      ;;
    *)
      # But if it's not part of an app bundle, just copy it from the path as-is
      # and we'll execute that file directly.
      CLI_PACKAGED_EMULATOR_PATH="Contents/MacOS/$(basename "$CLI_EMULATOR_PATH")"
      cp -c -r "$CLI_EMULATOR_PATH" "$APP_DIR/$CLI_PACKAGED_EMULATOR_PATH"
      ;;
  esac

  # Copy the roms
  if [ -f "$CLI_ROMS" ]; then
    cp -c "$CLI_ROMS" "$APP_DIR/$CLI_PACKAGED_ROMS_PATH"
  elif [ -d "$CLI_ROMS" ]; then
    cp -c -r "$CLI_ROMS"/* "$APP_DIR/$CLI_PACKAGED_ROMS_PATH"
  fi

  # find the launch rom
  # shellcheck disable=SC2086 # because we want word splitting here
  CLI_LAUNCH_ROM_PACKAGE_PATH="${CLI_PACKAGED_ROMS_PATH}/$(findLaunchRom $BP_MAIN_ROM_SEARCH_PATH)"


  # Copy the emulator config settings
  if [ -n "${CLI_CONFIG_SOURCE_DIR:-}" ]; then
    cp -c -r "$CLI_CONFIG_SOURCE_DIR" "$APP_DIR/$CLI_PACKAGED_CONFIG_PATH"
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




