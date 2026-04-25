
# Display name for the emulator
EMU_NAME='Stella'

# URL presented to the user if they need to download the emulator
EMU_DOWNLOAD_URL='https://stella-emu.github.io'

# Direct path to the emulator application.
EMU_APP_PATH="/Applications/Stella.app"

# Copies the user's current Stella config into the bundle at build time.
EMU_EMBED_CONFIG_COMMAND='
EMU_CONFIG_SRC="$HOME/Library/Application Support/Stella"
if [ -d "$EMU_CONFIG_SRC" ]; then
  mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Config/Library/Application Support/Stella"
  cp -r "$EMU_CONFIG_SRC/." "$BUILD_BUNDLE_DIR/Contents/Resources/Config/"
fi'

# If necessary, deploys bundled config into the per-game sandbox on first launch.
EMU_DEPLOY_CONFIG_COMMAND='
'

# Command to launch the emulator. Uses runtime variables set by the launch script.
EMU_RUN_COMMAND='
# HOME is sandboxed so the emulator stores its config per-game under RetroApp/
# This is the only way we can get it to do per-game settings.
EMU_HOME_SANDBOX_DIR="\$HOME/Library/Application Support/RetroApp/Stella/'"$BUILD_GAME_NAME"'
EMU_SANDBOXED_CONFIG_DIR="$EMU_HOME_SANDBOX_DIR/Library/Application Support/Stella"
if ! [ -d "$EMU_SANDBOXED_CONFIG_DIR" ]; then
  # First launch: deploy bundled config into the per-game sandbox.
  set +e
  mkdir -p "\${RUN_SANDBOXED_CONFIG_DIR}"
  cp -r "$RUN_BUNDLE_DIR/Contents/Resources/Config/." "$EMU_SANDBOXED_CONFIG_DIR/"
  set -e
fi
HOME="${RUN_HOME_SANDBOX_DIR}" open "${RUN_EMU_PATH}" --args -fullscreen 1 "${RUN_ROM_PATH}"
'