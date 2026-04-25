#!/bin/zsh


if [ "$#" -ne 2 ]; then
  echo "Usage: $0 INPUT_PNG_FILE OUTPUT_ICNS_FILE" >&2
  exit 1
fi

INPUT="$1"
OUTPUT="$2"

# Check input file existence
if [ ! -f "$INPUT" ]; then
  echo "Input file not found: $INPUT" >&2
  exit 1
fi

# Create a unique temp directory for the iconset
TMP_DIR=$(mktemp -d -t retroapp-make-icon)
TMP_ICONSET="$TMP_DIR/temp.iconset"
mkdir -p "$TMP_ICONSET"
if [ ! -d "$TMP_ICONSET" ]; then
  echo "Failed to create temporary directory" >&2
  exit 1
fi


# Sizes needed for macOS iconset
SIZES=(16 32 64 128 256 512 1024)

# Crop input to centered square if needed
WIDTH=$(sips -g pixelWidth "$INPUT" | awk '/pixelWidth:/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$INPUT" | awk '/pixelHeight:/ {print $2}')

if [ "$WIDTH" -ne "$HEIGHT" ]; then
  # Find crop size and offsets
  if [ "$WIDTH" -gt "$HEIGHT" ]; then
    CROP_SIZE="$HEIGHT"
    CROP_X=$(( (WIDTH - HEIGHT) / 2 ))
    CROP_Y=0
  else
    CROP_SIZE="$WIDTH"
    CROP_X=0
    CROP_Y=$(( (HEIGHT - WIDTH) / 2 ))
  fi
  CROP_INPUT="$TMP_DIR/cropped.png"
  sips -c "$CROP_SIZE" "$CROP_SIZE" --cropOffset "$CROP_X" "$CROP_Y" "$INPUT" --out "$CROP_INPUT" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error cropping image to square" >&2
    exit 1
  fi
else
  CROP_INPUT="$INPUT"
fi

for size in $SIZES; do
  sips -s format png -z "$size" "$size" "$CROP_INPUT" --out "$TMP_ICONSET/icon_${size}x${size}.png" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error resizing image to ${size}x${size}" >&2
    exit 1
  fi
done

iconutil -c icns -o "$OUTPUT" "$TMP_ICONSET"
if [ $? -ne 0 ]; then
  echo "Error creating .icns file" >&2
  exit 1
fi

# Cleanup temp directory
#rm -rf "$TMP_ICONSET"

echo "Created $OUTPUT" >&2
exit 0
