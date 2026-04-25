
# Display name for the emulator
EMU_NAME='Ares'

# URL presented to the user if they need to download the emulator
EMU_DOWNLOAD_URL='https://ares-emu.net/download'

# Path to the emulator's support directory, relative to $HOME/Library/
EMU_SUPPORT_PATH='Application Support/ares'

# Scriptlet called during retroapp-bundle.sh that embed's the user's current emulator
# config into the launcher app.
EMU_EMBED_CONFIG_COMMAND='mkdir $BUILD_BUNDLE_DIR/Contents/Resources/Config && \
cp "$HOME/Application Support/ares/*" "$BUILD_BUNDLE_DIR/Contents/Resources/Config"'

# Scriptlet that copies the bundled config into the sandboxed emulator config on first launch.
EMU_DEPLOY_CONFIG_COMMAND='
if ! [ -d "\$RUN_SANDBOXED_CONFIG_DIR" ]; then
  # First launch: deploy bundled config into the per-game sandbox.
  set +e
  mkdir -p "\${RUN_SANDBOXED_CONFIG_DIR}"
  $EMU_DEPLOY_CONFIG_COMMAND
  set -e
fi'

# Direct path to the emulator application.
EMU_APP_PATH='/Applications/ares.app'

# Command to launch the emulator. Uses runtime variables set by the launch script.
EMU_RUN_COMMAND='open "$RUN_EMU_PATH" --args --fullscreen --settings $RUN_SANDBOXED_CONFIG_DIR/settings.bml "${RUN_ROM_PATH}"'