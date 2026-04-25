#!/bin/sh

usage() {
  echo "Usage: retroapp blueprint-info BLUEPRINT" >&2
  exit 1
}

RA_BLUEPRINT="${1}"

cat "$RA_BLUEPRINTS_DIR/$RA_BLUEPRINT/blueprint-info.sh" | grep -v "^\s*#" | grep -v "^\s*$"