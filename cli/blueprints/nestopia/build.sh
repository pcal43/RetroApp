#!/bin/sh

buildStandardBundle

LAUNCH_ROM=$(findLaunchRom "*.nes" "*.zip" "*.7z" "*.fds" "*.*")

cat <<EOF > "$APP_DIR/Contents/MacOS/run"
#!/bin/sh
APP_DIR=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)/../..
"\$APP_DIR/$CLI_PACKAGED_EMULATOR_PATH" -nogui -fastboot -fullscreen -batch -- "\$APP_DIR/$CLI_PACKAGED_ROMS_PATH/$LAUNCH_ROM"
EOF
