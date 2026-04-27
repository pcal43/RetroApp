#!/bin/zsh
set -x

RUN_BUNDLE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/../.."
RUN_BUNDLED_CONFIG_DIR="$RUN_BUNDLE_DIR/Contents/Resources/Config/"


ifdef(`BUILD_BUNDLED_EMULATOR_ENABLED', 
  `RUN_EMU_PATH="$RUN_BUNDLE_DIR/Contents/Resources/Emulator/ares.app"',
  `RUN_EMU_PATH="/Applications/ares.app"'
)

if ! [ -e "$RUN_EMU_PATH" ]; then
  echo "ERROR ares not found at $RUN_EMU_PATH." >&2
  echo "Download from https://ares-emu.net/download" >&2
  exit 1
fi


# NOTE launching ares in --fullscreen doesn't work very well right now

ifdef(`BUILD_SANDBOXED_CONFIG_ENABLED',
`
# If the sandboxed config dir does not exist, we must
# be running for the first time.  Deploy the embedded config.
# NOTE that ares seems to resistant to the HOME manipulation that we do with
# other emulators, so the sandboxing might not be airtight.
RUN_HOME_SANDBOX_DIR="BUILD_RETROAPPS_SUPPORT_PATH/ares/BUILD_GAME_NAME"
RUN_ROM_PATH="$RUN_BUNDLE_DIR/Contents/Resources/Roms/BUILD_ROM_NAME"
if ! [ -d "$RUN_SANDBOXED_CONFIG_DIR" ]; then
  set +e
  mkdir -p "$RUN_SANDBOXED_CONFIG_DIR"
  cp -r "$RUN_BUNDLED_CONFIG_DIR/*" "$RUN_SANDBOXED_CONFIG_DIR/"
  set -e
fi
open "$RUN_EMU_PATH" --args --system "BUILD_ARES_SYSTEM" --settings "$RUN_SANDBOXED_CONFIG_DIR/settings.bml" "$RUN_ROM_PATH"
',

`
# Run the emulator with the default config
open "$RUN_EMU_PATH" --args --system "BUILD_ARES_SYSTEM" "$RUN_ROM_PATH"
'
)

