
# Path to the emulator's support directory, relative to $HOME
EMU_SUPPORT_PATH="Application Support/Stella"

# Path segment for the sandboxed support dir.  The home dir for 
# launchers using this emulator will be
# /Application Support/RetroApp/$EMU_SANDBOX_SUPPORT_PATH/$GAME_NAME
EMU_SANDBOX_HOME="Stella"

# Colon-separated lsit of places to search for the emulator application.
# This will be evaluated at runtime by the launcher.
EMU_APP_SEARCH_PATH="\${BUNDLE_DIR}/Stella.app:/Applications/Stella.app"

# Options that will be passed to the emulator.
EMU_OPTS=""