#!/bin/zsh

#
# Builds a MacOS bundle to launch a game with ares.
#

#
# Make sure they have installed ares.
#
EMU_EMULATOR_PATH="/Applications/Dolphin.app"
if [ ! -d "$EMU_EMULATOR_PATH" ]; then
  echo "ERROR Could not find Dolphin at $EMU_EMULATOR_PATH." >&2
  echo "Please download it at https://dolphin-emu.org/download" >&2
  exit 1
fi

#
# Copy ROM into the bundle
#
mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Roms"
cp "$BUILD_ROM_PATH" "$BUILD_BUNDLE_DIR/Contents/Resources/Roms/"

#
# Optionally embed the emulator config
#
if [ "${BUILD_SANDBOXED_CONFIG_ENABLED:-true}" = true ]; then
  BUILD_CONFIG_SRC="$HOME/Library/Application Support/Dolphin"
  if [ -d "$BUILD_CONFIG_SRC" ]; then
    echo "Bundling emulator config from $BUILD_CONFIG_SRC" >&2
    mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Config"
    rsync -a --exclude='Cache' --exclude='SaveStates' --exclude='ScreenShots' "$BUILD_CONFIG_SRC/" "$BUILD_BUNDLE_DIR/Contents/Resources/Config/"
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
