
# Path to the emulator's support directory, relative to $HOME
EMU_SUPPORT_PATH="Application Support/Stella"

# Label used in the sandboxed home dir path.  The launcher's HOME will be
# ~/Library/Application Support/RetroApp/$EMU_SANDBOX_HOME/$GAME_NAME
EMU_SANDBOX_HOME="Stella"

# Colon-separated lsit of places to search for the emulator application.
# This will be evaluated at runtime by the launcher.
EMU_APP_SEARCH_PATH="\${BUNDLE_DIR}/Stella.app:/Applications/Stella.app"

# Options that will be passed to the emulator.
EMU_OPTIONS="-fullscreen 1"