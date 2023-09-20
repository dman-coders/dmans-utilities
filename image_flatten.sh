#!/bin/bash

# Makes whites whiter and darks darker.
# Use this on simple black & white scans to remove paper texture and make the ink 100% black.
# Will write-back in place by default.
# set `export image_target_dir=/tmp` to run this in dry-run mode.

SOURCE_FILE="$1"
echo "$SOURCE_FILE"

SOURCE_FILENAME="$(basename -- ${SOURCE_FILE})"
SOURCE_DIR="$(dirname ${SOURCE_FILE})"
echo "$SOURCE_DIR"

TARGET_DIR="${image_target_dir:-${SOURCE_DIR}}"
TARGET_FILE="${TARGET_DIR}/${SOURCE_FILENAME}"

echo " ${SOURCE_FILENAME} -> ${TARGET_FILE}" >&2

# adjust levels to force any near-black to black,
# and a lot of near-white to white.
magick "$SOURCE_FILENAME"  -colorspace Gray -level 15%,85% "$TARGET_FILE"

echo " open \"$SOURCE_FILENAME\" ; open \"$TARGET_FILE\" " >&2

echo \"$TARGET_FILE\"
open "$TARGET_FILE"
