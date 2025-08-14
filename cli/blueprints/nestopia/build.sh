#!/bin/sh

buildStandardBundle

cat <<EOF > "$CLI_RUN_SCRIPT_PATH"
#!/bin/sh
APP_DIR=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)/../..

"\$APP_DIR/$CLI_PACKAGED_EMULATOR_PATH" \\
  "\$APP_DIR/$CLI_LAUNCH_ROM_PACKAGE_PATH"
EOF

# the bundled version seems to support no options at all ugh
# -nogui -fastboot -fullscreen -batch \\
