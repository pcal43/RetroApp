#!/bin/sh

usage() {
  cat >&2 <<'EOF'
Usage: retroapp thumbnail [-h] [-u] SYSTEM_NAME GAME_NAME

  Downloads box art for the given game from thumbnails.libretro.com and echoes
  the path to the local png file.

  If the download fails for any reason, the path to the default-icon.png is
  echoed instead and the command exits with a nonzero status.

  All paths are absolute.

  Options:
    -h   Print this message.
    -u   Instead of downloading, just echo the URL that would be used.

  Examples:

    retroapp thumbnail 'Nintendo - Nintendo Entertainment System' 'Super Mario Bros. (World)'

    retroapp thumbnail -u 'Atari - 2600' 'Halo 2600 (World) (Aftermarket) (Unl)'

EOF
  exit 1
}

CLI_URL_ONLY=0

while getopts "uh" opt; do
  case $opt in
    u) CLI_URL_ONLY=1 ;;
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

CLI_ICON_URL=$(python3 -c "
import sys
from urllib.parse import quote
system = quote(sys.argv[1], safe='()')
game   = quote(sys.argv[2], safe='()')
print('https://thumbnails.libretro.com/{}/Named_Boxarts/{}.png'.format(system, game))
" "$CLI_SYSTEM_NAME" "$CLI_GAME_NAME")

if [ "$CLI_URL_ONLY" = "1" ]; then
  echo "$CLI_ICON_URL"
  exit 0
fi

RA_DEFAULT_ICON="$RA_BLUEPRINTS_DIR/default-icon.png"

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
