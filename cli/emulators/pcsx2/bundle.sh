#!/bin/zsh

#
# Builds a MacOS bundle to launch a game with PCSX2.
#

#
# Make sure they have installed PCSX2.
# search for /Applications/PCSX2*.app.  Assign the lexicographically highest one to EMU_EMULATOR_PATH
#
EMU_EMULATOR_PATH=$(find /Applications -maxdepth 1 -name 'PCSX2*.app' -type d 2>/dev/null | sort | tail -1)
if ! [ -n "$EMU_EMULATOR_PATH" ]; then
    echo '
FAILED

Could not find PCSX2 (in /Applications/PCSX2*.app).
Please download it from https://pcsx2.net/downloads and install it.
Be sure to install BIOS files as well.' >&2
  exit 1
fi

#
# Copy ROM into the bundle
#
mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Roms"
cp "$BUILD_ROM_PATH" "$BUILD_BUNDLE_DIR/Contents/Resources/Roms/"

#
# Optionally embed the emulator config (recommended)
#
if [ "${BUILD_SANDBOXED_CONFIG_ENABLED:-true}" = true ]; then
  EMU_CONFIG_SRC="$HOME/Library/Application Support/PCSX2"
  if [ -d "$EMU_CONFIG_SRC" ]; then
    echo "Bundling emulator config from $EMU_CONFIG_SRC" >&2
    mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Config"
    rsync -a --exclude='cache/' "$EMU_CONFIG_SRC/" "$BUILD_BUNDLE_DIR/Contents/Resources/Config/"
  fi
fi

#
# Optionally embed the emulator application
#
if [ "${BUILD_BUNDLED_EMULATOR_ENABLED:-true}" = true ]; then
    echo "Bundling emulator application from $EMU_EMULATOR_PATH" >&2   
    mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Emulator"
    cp -r "$EMU_EMULATOR_PATH" "$BUILD_BUNDLE_DIR/Contents/Resources/Emulator/"
fi

