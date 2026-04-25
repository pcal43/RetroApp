#!/bin/sh

usage() {
  echo "Usage: retroapp find-emulator [-h] BLUEPRINT" >&2
  exit 1
}

#FIXME make less redundant
findFirst() {
    for cmd; do
        if [ "$cmd" != "${cmd%/*}" ]; then
            # Ff the expression contains any slashes, assume it's a direct file path
          if [ "$cmd" != "${cmd%\**}" ]; then
              # cmd contains an asterisk, treat as a glob pattern
              pattern="$cmd"
              # save current IFS
              old_ifs="$IFS"
              IFS="$(printf '\n\t')"
              # Use shell globbing to find matching files, then sort them
              for match in $(find . -path "$pattern" -maxdepth 1 -print 2>/dev/null | sort); do
                  if [ -e "$match" ]; then
                      echo "$match"
                      # restore IFS before exiting
                      IFS="$old_ifs"
                      exit 0
                  fi
              done
              # restore IFS if no match was found
              IFS="$old_ifs"
          else
              # No glob pattern, just check if file exists directly
              if [ -e "$cmd" ]; then
                  echo "$cmd"
                  exit 0
              fi
          fi
        else
            # Otherwise, assume it's an executable name that we want to look for on their PATH
            set +e
            path=$(which "$cmd" 2>/dev/null)
            status=$?
            set -e
            if [ $status -eq 0 ] && [ -e "$path" ]; then
                echo "$path"
                exit 0
            fi
        fi
    done
    echo "Error: could not find ${RA_BLUEPRINT:-} on your machine.  Please install it or specify its location manually."
    exit "$EXIT_EMULATOR_NOT_FOUND"
}

while getopts "he:" opt; do
  case $opt in

    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

RA_BLUEPRINT="$1"

if [ -z "${RA_BLUEPRINT:-}" ]; then
  echo "A blueprint must be specified.  Must be one of $($RA_RETROAPP list-blueprints)" >&2
  usage
else
  if ! [ -d "$RA_BLUEPRINTS_DIR/$RA_BLUEPRINT" ]; then
    echo "Invalid blueprint.  Valid values are $($RA_RETROAPP list-blueprints)"
    usage
  fi
fi


# shellcheck disable=SC1090
# load the BP_xxx metadata for the chosen blueprint
. "$RA_BLUEPRINTS_DIR/$RA_BLUEPRINT/blueprint-info.sh"

# shellcheck disable=SC2086
findFirst $BP_EMULATOR_SEARCH_PATH





