#!/bin/sh

buildStandardBundle

DUCKSTATION_BIN_PATH="/Contents/MacOS/DuckStation"

if ! [ -f "$APP_DIR/$CLI_PACKAGED_EMULATOR_PATH/$DUCKSTATION_BIN_PATH" ]; then
    echo "Could not find DuckStation binary at $APP_DIR/$CLI_PACKAGED_EMULATOR_PATH/$DUCKSTATION_BIN_PATH.  Are you sure this is the right DuckStation.app?"
    exit "$EXIT_BAD_EMULATOR"
fi

LAUNCH_ROM=$(findLaunchRom "*.m3u" "*.cue" "*.bin")

cat <<EOF > "$APP_DIR/Contents/MacOS/run"
#!/bin/sh
APP_DIR=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)/../..
"\$APP_DIR/$CLI_PACKAGED_EMULATOR_PATH/$DUCKSTATION_BIN_PATH" -nogui -fastboot -fullscreen -batch -- "\$APP_DIR/$CLI_PACKAGED_ROMS_PATH/$LAUNCH_ROM"
EOF
