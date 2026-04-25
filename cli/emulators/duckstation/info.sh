
# Path to the emulator's support directory, relative to $HOME/Library/
EMU_SUPPORT_PATH="Application Support/DuckStation"

# Label used in the sandboxed home dir path.  The launcher's HOME will be
# ~/Library/Application Support/RetroApp/$EMU_SANDBOX_HOME/$GAME_NAME
EMU_SANDBOX_HOME="DuckStation"

# Direct path to the emulator application.
EMU_APP_PATH="/Applications/DuckStation.app"

# Options passed to the emulator.
# TODO: verify correct DuckStation CLI flags
EMU_OPTIONS="-batch -fastboot -fullscreen -nogui --"
