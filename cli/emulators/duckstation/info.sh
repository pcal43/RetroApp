
# Display name for the emulator
EMU_NAME='DuckStation'

# URL presented to the user if they need to download the emulator
EMU_DOWNLOAD_URL='https://www.duckstation.org'

# Path to the emulator's support directory, relative to $HOME/Library/
EMU_SUPPORT_PATH="Application Support/DuckStation"

# Direct path to the emulator application.
EMU_APP_PATH="/Applications/DuckStation.app"

# Copies the user's current DuckStation config into the bundle at build time.
EMU_EMBED_CONFIG_COMMAND='CONFIG_SRC="$HOME/Library/$EMU_SUPPORT_PATH"
if [ -d "$CONFIG_SRC" ]; then
  mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Config"
  cp -r "$CONFIG_SRC/." "$BUILD_BUNDLE_DIR/Contents/Resources/Config/"
fi'

# Deploys bundled config into the per-game sandbox on first launch.
EMU_DEPLOY_CONFIG_COMMAND='cp -r "$RUN_BUNDLE_DIR/Contents/Resources/Config/." "$RUN_SANDBOXED_CONFIG_DIR/"'

# Command to launch the emulator. Uses runtime variables set by the launch script.
# TODO: verify correct DuckStation CLI flags
EMU_RUN_COMMAND='HOME="${RUN_HOME_SANDBOX_DIR}" open "${RUN_EMU_PATH}" --args -batch -fastboot -fullscreen -nogui -- "${RUN_ROM_PATH}"'
