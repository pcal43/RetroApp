#!/bin/zsh
set -x


RUN_BUNDLE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/../.."
RUN_ROM_PATH="$RUN_BUNDLE_DIR/Contents/Resources/Roms/"BUILD_ROM_NAME

# Find Dolphin: prefer a bundled copy, then fall back to /Applications.
RUN_EMU_BUNDLED="${RUN_BUNDLE_DIR}/Contents/Resources/Emulator/"*.app
if [ -e "$RUN_EMU_BUNDLED" ]; then
  RUN_EMU_PATH="$RUN_EMU_BUNDLED"
elif [ -e "/Applications/Dolphin.app" ]; then
  RUN_EMU_PATH="/Applications/Dolphin.app"
else
  echo "Error: $RUN_EMU_PATH not found. Download from https://ares-emu.net/download" >&2
  exit 1
fi


ifdef(`BUILD_SANDBOXED_CONFIG_ENABLED', `
# If we have an embedded config and the sandboxed config dir does not exist, we must
# be running for the first time.  Deploy the embedded config.
RUN_SANDBOXED_CONFIG_DIR="$HOME/Library/Application Support/RetroApp/Dolphin/"BUILD_GAME_NAME
RUN_BUNDLED_CONFIG_DIR="$RUN_BUNDLE_DIR/Contents/Resources/Config/"
if ! [ -d "$RUN_SANDBOXED_CONFIG_DIR" ]; then
  set +e
  mkdir -p "$RUN_SANDBOXED_CONFIG_DIR"
  cp -r "$RUN_BUNDLED_CONFIG_DIR/*" "$RUN_SANDBOXED_CONFIG_DIR/"
  set -e
fi

# Run the emulator with the sandboxed config
open "$RUN_EMU_PATH" --args --user="$RUN_SANDBOXED_CONFIG_DIR" "$RUN_ROM_PATH"

',
'
# Run the emulator with the standard config
open "$RUN_EMU_PATH" --args "$RUN_ROM_PATH"
'

)

