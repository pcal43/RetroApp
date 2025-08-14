#!/bin/sh

buildStandardBundle

if [ -z "${CLI_EMULATOR_PATH:-}" ]; then
    set +e
    CLI_EMULATOR_PATH=$(which stella)
    set -e
    if [ -z "${CLI_EMULATOR_PATH:-}" ]; then
        exit_emulatorNotFound 'stella'
    fi
fi

cp -c -r "$CLI_EMULATOR_PATH" "$APP_DIR/Contents/MacOS/stella"

cat <<EOF > "$APP_DIR/Contents/MacOS/run"
#!/bin/sh
MACOS_DIR=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)
"\$MACOS_DIR/stella" -fullscreen 1 -uselauncher 0 "\$MACOS_DIR/../Resources/$CLI_MAIN_ROM"
EOF
