#!/bin/sh

usage() {
  echo "Usage: retroapp list-blueprints [-h]" >&2
  exit 1
}

while getopts "he:" opt; do
  case $opt in
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

find "$RA_BLUEPRINTS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | paste -sd, - | sed 's/,/, /g'
