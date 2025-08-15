#!/bin/sh
# shellcheck disable=SC2034

BP_LABEL="Stella (Atari 2600)"
BP_EMULATOR_CONFIG_DIR="$HOME/Library/Application\ Support/Stella/"
BP_EMULATOR_SEARCH_PATH="/Applications/Stella*.app stella"
BP_MAIN_ROM_SEARCH_PATH="*.a26 *.bin *.zip *.rom *"
BP_IS_PER_GAME_CONFIG_SUPPORTED='true'
BP_LAUNCH_OPTS="-nogui -fastboot -fullscreen -batch"
