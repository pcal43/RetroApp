
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
  mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Config"
  cp -r "$EMU_CONFIG_SRC/." "$BUILD_BUNDLE_DIR/Contents/Resources/Config/"
fi'
