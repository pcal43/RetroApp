#!/bin/zsh
set -x


RUN_BUNDLE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/../.."
RUN_ROM_PATH="${RUN_BUNDLE_DIR}/Contents/Resources/Roms/BUILD_ROM_NAME"


ifdef(`BUILD_BUNDLED_EMULATOR_ENABLED', `
RUN_EMU_PATH="$RUN_BUNDLE_DIR/Contents/Resources/Emulator/Stella.app"
',
'
RUN_EMU_PATH="/Applications/Stella.app"
')
if ! [ -e "$RUN_EMU_PATH" ]; then
  echo "Error: Stella not found at $RUN_EMU_PATH." >&2
  echo 'Download from https://stella-emu.github.io' >&2
  exit 1
fi


ifdef(`BUILD_SANDBOXED_CONFIG_ENABLED', `
# If the sandboxed config dir does not exist, we must be running for the first time.  
# Deploy the embedded config if so.
RUN_HOME_SANDBOX_DIR="$HOME/Library/Application Support/RetroApp/stella/BUILD_GAME_NAME"
RUN_SANDBOXED_CONFIG_DIR="$RUN_HOME_SANDBOX_DIR/Library/Application Support/Stella"
if ! [ -d "$RUN_SANDBOXED_CONFIG_DIR" ]; then
  set +e
  mkdir -p "${RUN_SANDBOXED_CONFIG_DIR}"
  cp -r "${RUN_BUNDLE_DIR}/Contents/Resources/Config/." "${RUN_SANDBOXED_CONFIG_DIR}/"
  set -e
fi
HOME="${RUN_HOME_SANDBOX_DIR}" open "${RUN_EMU_PATH}" --args -fullscreen 1 "${RUN_ROM_PATH}"
',

'
# Run the emulator with the default config
open "${RUN_EMU_PATH}" --args -fullscreen 1 "${RUN_ROM_PATH}"
'
)
