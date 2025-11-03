#!/bin/zsh
echo '{';
find . -type f \( -iname '*.mp4' -o -iname '*.mov' \) | while read -r file; do
  json=$(ffprobe -v error -print_format json \
    -show_format -show_streams -select_streams v:0 "$file")

  sar=$(jq -r '.streams[0].sample_aspect_ratio // "N/A"' <<< "$json")
  dar=$(jq -r '.streams[0].display_aspect_ratio // "N/A"' <<< "$json")

  # Flag if either is missing or "N/A"
  if [[ "$sar" == "N/A" || "$sar" == "" || "$dar" == "N/A" || "$dar" == "" ]]; then
    width=$(jq -r '.streams[0].width // 0' <<< "$json")
    height=$(jq -r '.streams[0].height // 0' <<< "$json")
    echo "\"$file\": {\"width\": $width, \"height\": $height, \"sar\": \"$sar\", \"dar\": \"$dar\"}"
  fi
done
echo 'done:{}}'