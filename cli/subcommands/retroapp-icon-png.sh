#!/bin/sh

usage() {
  cat >&2 <<'EOF'
Usage: retroapp icon-png [-h] SYSTEM_NAME GAME_NAME

  Echoes the path to a local png file that should be used for creating the
  application icon.

  This command will attempt to download the image at the url returned by

  retroapp icon-url SYSTEM_NAME GAME_NAME

  into a temp file.  If it's able to do so, the path to that temp file
  will be output.

  If that fails for any reason, the command will output the path to
  the default-icon.png and exit -1.

  All paths are absolute.
EOF
  exit 1
}

while getopts "h" opt; do
  case $opt in
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
  echo "Error: SYSTEM_NAME and GAME_NAME are required." >&2
  usage
fi

CLI_SYSTEM_NAME="$1"
CLI_GAME_NAME="$2"

RA_DEFAULT_ICON="$RA_BLUEPRINTS_DIR/default-icon.png"

CLI_ICON_URL=$("$RA_RETROAPP" icon-url "$CLI_SYSTEM_NAME" "$CLI_GAME_NAME")

CLI_TEMP_PNG=$(mktemp /tmp/retroapp-icon-XXXXXX)
mv "$CLI_TEMP_PNG" "${CLI_TEMP_PNG}.png"
CLI_TEMP_PNG="${CLI_TEMP_PNG}.png"

if curl -fsSL -o "$CLI_TEMP_PNG" "$CLI_ICON_URL" 2>/dev/null; then
  echo "$CLI_TEMP_PNG"
  exit 0
else
  rm -f "$CLI_TEMP_PNG"
  echo "$RA_DEFAULT_ICON"
  exit 1
fi
