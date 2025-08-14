#!/bin/sh

buildStandardBundle

EMU_APP_NAME=$(basename "$CLI_EMULATOR_PATH")
EMU_APP_PATH="/Contents/MacOS/$EMU_APP_NAME"
EMU_BIN_PATH="$EMU_APP_NAME/Contents/MacOS/PCSX2"
cp -c -r "$CLI_EMULATOR_PATH" "$APP_DIR/$EMU_APP_PATH"

if ! [ -f "$APP_DIR/Contents/MacOS/$EMU_BIN_PATH" ]; then
    echo "Could not find PCSX2 binary at $APP_DIR/Contents/MacOS/$EMU_APP_PATH.  Are you sure this is the right PCSX2 app?"
    exit "$EXIT_BAD_EMULATOR"
fi

cat <<EOF > "$APP_DIR/Contents/MacOS/run"
#!/bin/sh
MACOS_DIR=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)
"\$MACOS_DIR/$EMU_BIN_PATH" -nogui -fastboot -fullscreen  "\$MACOS_DIR/../Resources/$CLI_MAIN_ROM"
EOF
