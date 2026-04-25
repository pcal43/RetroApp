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

RA_URL_ONLY=0

while getopts "uh" opt; do
  case $opt in
    u) RA_URL_ONLY=1 ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
  echo "Error: SYSTEM_NAME and GAME_NAME are required." >&2
  usage
fi

RA_SYSTEM_NAME="$1"
RA_GAME_NAME="$2"

RA_ICON_URL=$(python3 -c "
import sys
from urllib.parse import quote
system = quote(sys.argv[1], safe='()')
game   = quote(sys.argv[2], safe='()')
print('https://thumbnails.libretro.com/{}/Named_Boxarts/{}.png'.format(system, game))
" "$RA_SYSTEM_NAME" "$RA_GAME_NAME")

if [ "$RA_URL_ONLY" = "1" ]; then
  echo "$RA_ICON_URL"
  exit 0
fi

RA_DEFAULT_ICON="$RA_BLUEPRINTS_DIR/default-icon.png"

RA_TEMP_PNG=$(mktemp /tmp/retroapp-icon-XXXXXX)
mv "$RA_TEMP_PNG" "${RA_TEMP_PNG}.png"
RA_TEMP_PNG="${RA_TEMP_PNG}.png"

echo "Downloading thumbnail from $$RA_TEMP_PNG" >&2
if curl -fsSL -o "$RA_TEMP_PNG" "$RA_ICON_URL" 2>/dev/null; then
  echo "$RA_TEMP_PNG"
else
  echo "Download failed, default icon will be used" >&2
  exit 1
fi
