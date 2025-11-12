#!/usr/bin/env bash

# Usage: ./force_dar_passthrough.sh input.mp4

input="$1"

if [[ ! -f "$input" ]]; then
  echo "File '$input' not found."
  exit 1
fi

# Extract DAR from ffprobe
dar=$(ffprobe -v error -select_streams v:0 -show_entries stream=display_aspect_ratio \
            -of default=noprint_wrappers=1:nokey=1 "$input")

if [[ -z "$dar" ]]; then
  echo "Could not determine DAR."
  exit 1
fi

echo "Forcing DAR to $dar in container metadata..."

output="${input%.mp4}_fixed.mp4"

# Remux the file with enforced aspect (no re-encode)
ffmpeg -i "$input" -aspect "$dar" -c copy "$output"

echo "Output written to $output"
