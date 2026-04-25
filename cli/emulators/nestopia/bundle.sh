# Copy ROM into bundle
mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Roms"
cp "$BUILD_ROM_PATH" "$BUILD_BUNDLE_DIR/Contents/Resources/Roms/"

# Embed Nestopia config into the bundle if it exists on this machine
BUILD_CONFIG_SRC="$HOME/Library/Application Support/Bannister/Nestopia"
if [ -d "$BUILD_CONFIG_SRC" ]; then
  mkdir -p "$BUILD_BUNDLE_DIR/Contents/Resources/Config"
  cp -r "$BUILD_CONFIG_SRC/." "$BUILD_BUNDLE_DIR/Contents/Resources/Config/"
fi
