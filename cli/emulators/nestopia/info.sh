
# Display name for the emulator
EMU_NAME='Nestopia'

# URL presented to the user if they need to download the emulator
EMU_DOWNLOAD_URL='https://github.com/0ldsk00l/nestopia'

# Path to the emulator's support directory, relative to $HOME/Library/
EMU_SUPPORT_PATH="Application Support/Bannister/Nestopia"

# Direct path to the emulator application.
EMU_APP_PATH="/Applications/Nestopia.app"

# Copies the user's current Nestopia config into the bundle at build time.
EMU_EMBED_CONFIG_COMMAND='
CONFIG_SRC="$HOME/Library/$EMU_SUPPORT_PATH"
if [ -d "$CONFIG_SRC" ]; then
  mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Config"
  cp -r "$CONFIG_SRC/." "$BUILD_BUNDLE_DIR/Contents/Resources/Config/"
fi'
