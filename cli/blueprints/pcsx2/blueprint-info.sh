#!/bin/sh
# shellcheck disable=SC2034

BP_LABEL="PCSX2 (Playstation 2)"
BP_EMULATOR_CONFIG_DIR="$HOME/Library/Application\ Support/PCSX2/"
BP_EMULATOR_SEARCH_PATH=" /Applications/PCSX2*.app"
BP_MAIN_ROM_SEARCH_PATH="*.m3u *.cue *.bin"
BP_IS_PER_GAME_CONFIG_SUPPORTED='false'
BP_LAUNCH_OPTS="-nogui -fastboot -fullscreen"
