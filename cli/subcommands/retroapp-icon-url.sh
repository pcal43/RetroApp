#!/bin/sh

usage() {
  cat >&2 <<'EOF'
Usage: retroapp icon-url [-h] SYSTEM_NAME GAME_NAME

  Echoes a url from which box art or a similar png image can be downloaded
  for the given name.  This will be Named_Boxart at thumbnails.libretro.com.

  For example,

  retroapp icon-url 'Nintendo - Nintendo Entertainment System' 'Super Mario Bros. (World)'

  will output

  https://thumbnails.libretro.com/Nintendo%20-%20Nintendo%20Entertainment%20System/Named_Boxarts/Super%20Mario%20Bros.%20(World).png

  Note that no guarantee is made that the file is actually downloadable - this is just the url
  that might work.

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

RA_SYSTEM_NAME="$1"
RA_GAME_NAME="$2"

python3 -c "
import sys
from urllib.parse import quote
system = quote(sys.argv[1], safe='()')
game   = quote(sys.argv[2], safe='()')
print('https://thumbnails.libretro.com/{}/Named_Boxarts/{}.png'.format(system, game))
" "$RA_SYSTEM_NAME" "$RA_GAME_NAME"