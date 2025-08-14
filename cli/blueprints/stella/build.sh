#!/bin/sh

buildStandardBundle

cat <<EOF > "$CLI_RUN_SCRIPT_PATH"
#!/bin/sh
APP_DIR=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)/../..

"\$APP_DIR/$CLI_PACKAGED_EMULATOR_PATH" \
    -nogui -fastboot -fullscreen -batch \
    "\$APP_DIR/$CLI_LAUNCH_ROM_PACKAGE_PATH"
EOF
