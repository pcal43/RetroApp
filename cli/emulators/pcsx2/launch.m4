#!/bin/zsh
set -x

RUN_BUNDLE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/../.."
RUN_ROM_PATH="$RUN_BUNDLE_DIR/Contents/Resources/Roms/BUILD_ROM_NAME"



ifdef(`BUILD_BUNDLED_EMULATOR_ENABLED', `
RUN_EMU_PATH="$RUN_BUNDLE_DIR/Contents/Resources/Emulator/PCSX2.app"
',
'
RUN_EMU_PATH=$(find /Applications -maxdepth 1 -name 'PCSX2*.app' -type d 2>/dev/null | sort | tail -1)
')
if [ -z "$RUN_EMU_PATH" ] || ! [ -e "$RUN_EMU_PATH" ]; then
  echo "Error: PCSX2 not found at $RUN_EMU_PATH." >&2
  echo 'Download from https://pcsx2.net/downloads' >&2
  exit 1
fi


ifdef(`BUILD_SANDBOXED_CONFIG_ENABLED', `
# If we have an embedded config and the sandboxed config dir does not exist, we must
# be running for the first time.  Deploy the embedded config.
RUN_HOME_SANDBOX_DIR="BUILD_RETROAPPS_SUPPORT_PATH/PCSX2/BUILD_GAME_NAME"
RUN_SANDBOXED_CONFIG_DIR="$RUN_HOME_SANDBOX_DIR/Library/Application Support/PCSX2"
if ! [ -d "$RUN_SANDBOXED_CONFIG_DIR" ]; then
  set +e
  mkdir -p "$RUN_SANDBOXED_CONFIG_DIR"
  cp -r "$RUN_BUNDLE_DIR/Contents/Resources/Config/." "$RUN_SANDBOXED_CONFIG_DIR"
  set -e
fi

# Run the emulator with the sandboxed config
HOME="$RUN_HOME_SANDBOX_DIR" open "$RUN_EMU_PATH" --args -nogui -fastboot -fullscreen -batch "$RUN_ROM_PATH"

',
'
# Run the emulator with the standard config
open "$RUN_EMU_PATH" --args -nogui -fastboot -fullscreen -batch "$RUN_ROM_PATH"
'
)
