#!/bin/sh

buildStandardBundle

PACKAGED_EMU_APP_PATH="Contents/MacOS/$CLI_EMULATOR_BASENAME"
PACKAGED_EMU_BIN_PATH="$PACKAGED_EMU_APP_PATH/Contents/MacOS/DuckStation"

cp -c -r "$CLI_EMULATOR_PATH" "$APP_DIR/$PACKAGED_EMU_APP_PATH"

if ! [ -f "$APP_DIR/$PACKAGED_EMU_BIN_PATH" ]; then
    echo "Could not find DuckStation binary at $APP_DIR/Contents/MacOS/$EMU_APP_PATH.  Are you sure this is the right DuckStation.app?"
    exit "$EXIT_BAD_EMULATOR"
fi

cat <<EOF > "$APP_DIR/Contents/MacOS/run"
#!/bin/sh
APP_DIR=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)/../..
"\$APP_DIR/$PACKAGED_EMU_BIN_PATH" -nogui -fastboot -fullscreen -batch -- "\$APP_DIR/$CLI_PACKAGED_ROM_PATH"
EOF
