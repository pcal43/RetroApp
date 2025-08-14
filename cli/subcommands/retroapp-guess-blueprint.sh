#!/bin/sh

usage() {
  echo "Usage: retroapp guess-blueprint [-h] ROMFILE" >&2
  exit 1
}

ROMFILE="$1"

if [ "${ROMFILE##*.}" = "nes" ]; then
  echo "nestopia"
  exit 0
fi

case "$(echo "$ROMFILE" | tr '[:upper:]' '[:lower:]')" in
  *nes*)
    echo "nestopia"
    exit 0
    ;;
esac

case "$(echo "$ROMFILE" | tr '[:upper:]' '[:lower:]')" in
  *ps2*|*playstation2*|*pcsx2*)
    echo "pcsx2"
    exit 0
    ;;
esac

case "$(echo "$ROMFILE" | tr '[:upper:]' '[:lower:]')" in
  *2600*|*stella*)
    echo "stella"
    exit 0
    ;;
esac

