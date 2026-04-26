#!/bin/zsh
set -x


RUN_BUNDLE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/../.."
RUN_ROM_PATH="$RUN_BUNDLE_DIR/Contents/Resources/Roms/BUILD_ROM_NAME"

ifdef(`BUILD_BUNDLED_EMULATOR_ENABLED', 
  `RUN_EMU_PATH="$RUN_BUNDLE_DIR/Contents/Resources/Emulator/Dolphin.app"',
  `RUN_EMU_PATH="/Applications/Dolphin.app"'
)

if ! [ -e "$RUN_EMU_PATH" ]; then
  echo "Error: Dolphin not found at $RUN_EMU_PATH." >&2
  echo 'Download from https://dolphin-emu.org/' >&2
  exit 1
fi


ifdef(`BUILD_SANDBOXED_CONFIG_ENABLED', 
`
# If we have an embedded config and the sandboxed config dir does not exist, we must
# be running for the first time.  Deploy the embedded config.
RUN_SANDBOXED_CONFIG_DIR="BUILD_RETROAPPS_SUPPORT_PATH/Dolphin/BUILD_GAME_NAME"
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

`
# Run the emulator with the standard config
open "$RUN_EMU_PATH" --args "$RUN_ROM_PATH"
'

)

