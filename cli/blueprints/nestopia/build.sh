#!/bin/sh

buildStandardBundle

cp -c -r "$CLI_EMULATOR_PATH" "$APP_DIR/Contents/MacOS/nestopia"

cat <<EOF > "$APP_DIR/Contents/MacOS/run"
#!/bin/sh
MACOS_DIR=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)
"\$MACOS_DIR/nestopia" --fullscreen "\$MACOS_DIR/../Resources/$CLI_MAIN_ROM"
EOF
