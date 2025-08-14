#!/bin/sh

usage() {
  echo "Usage: retroapp guess-library-path [-h] BLUEPRINT EMULATOR_PATH" >&2
  exit 1
}

CLI_BLUEPRINT="${1}"
# shellcheck disable=SC2034
CLI_EMULATOR_PATH="${2}"

# shellcheck disable=SC1090
. "$RA_BLUEPRINTS_DIR/$CLI_BLUEPRINT/guess-library-path.sh"
