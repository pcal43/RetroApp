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


# Get input image dimensions
WIDTH=$(sips -g pixelWidth "$INPUT" | awk '/pixelWidth:/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$INPUT" | awk '/pixelHeight:/ {print $2}')

for size in $SIZES; do
  # Calculate target dimensions to preserve aspect ratio
  if [ "$WIDTH" -gt "$HEIGHT" ]; then
    TARGET_W="$size"
    TARGET_H=$(( size * HEIGHT / WIDTH ))
  elif [ "$HEIGHT" -gt "$WIDTH" ]; then
    TARGET_H="$size"
    TARGET_W=$(( size * WIDTH / HEIGHT ))
  else
    TARGET_W="$size"
    TARGET_H="$size"
  fi
  RESIZED_PNG="$TMP_DIR/resized_${size}.png"
  FINAL_PNG="$TMP_ICONSET/icon_${size}x${size}.png"
  sips -s format png -z "$TARGET_H" "$TARGET_W" "$INPUT" --out "$RESIZED_PNG" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error resizing image to ${TARGET_W}x${TARGET_H}" >&2
    exit 1
  fi
  # If not square, pad to square using ImageMagick convert (if available)
  if [ "$TARGET_W" -ne "$size" ] || [ "$TARGET_H" -ne "$size" ]; then
    if command -v convert >/dev/null 2>&1; then
      convert "$RESIZED_PNG" -background none -gravity center -extent ${size}x${size} "$FINAL_PNG"
    else
      echo "WARNING: ImageMagick 'convert' not found, icon will not be square for size $size" >&2
      mv "$RESIZED_PNG" "$FINAL_PNG"
    fi
  else
    mv "$RESIZED_PNG" "$FINAL_PNG"
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
