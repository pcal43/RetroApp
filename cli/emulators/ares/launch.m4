#!/bin/zsh
set -x

RUN_BUNDLE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/../.."
RUN_BUNDLED_CONFIG_DIR="$RUN_BUNDLE_DIR/Contents/Resources/Config/"

# Find ares: prefer a bundled copy, then fall back to /Applications.
RUN_EMU_BUNDLED="$RUN_BUNDLE_DIR/Contents/Resources/Emulator/"*.app
if [ -e "$RUN_EMU_BUNDLED" ]; then
  RUN_EMU_PATH="$RUN_EMU_BUNDLED"
elif [ -e "/Applications/ares.app" ]; then
  RUN_EMU_PATH="/Applications/ares.app"
else
  echo "Error: ares not found. Download from https://ares-emu.net/download" >&2
  exit 1
fi


# NOTE launching ares in --fullscreen doesn't work very well right now

ifdef(`BUILD_SANDBOXED_CONFIG_ENABLED', `
# If the sandboxed config dir does not exist, we must
# be running for the first time.  Deploy the embedded config.
# NOTE that ares seems to resistant to the HOME manipulation that we do with
# other emulators, so the sandboxing might not be airtight.
RUN_HOME_SANDBOX_DIR="$HOME/Library/Application Support/RetroApp/ares/BUILD_GAME_NAME"
RUN_ROM_PATH="$RUN_BUNDLE_DIR/Contents/Resources/Roms/BUILD_ROM_NAME"
if ! [ -d "$RUN_SANDBOXED_CONFIG_DIR" ]; then
  set +e
  mkdir -p "$RUN_SANDBOXED_CONFIG_DIR"
  cp -r "$RUN_BUNDLED_CONFIG_DIR/*" "$RUN_SANDBOXED_CONFIG_DIR/"
  set -e
fi
open "$RUN_EMU_PATH" --args --settings "$RUN_SANDBOXED_CONFIG_DIR/settings.bml" "$RUN_ROM_PATH"
',

'
# Run the emulator with the default config
open "$RUN_EMU_PATH" --args "$RUN_ROM_PATH"
'
)

