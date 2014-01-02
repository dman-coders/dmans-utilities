#!/bin/bash

# Given a video, grab a frame from it
# then munge it artistically to serve as a background for media player.

minutes_in=5;
# dimensions="1920x1080"
dimensions="1280x720"

if (( $# != 1 ))
then
  echo "Please pass in a video file name"
  exit 1
fi

vidfile="$1";
framefile="$vidfile.frame-%3d.jpg"
ffmpeg -ss 00:${minutes_in}:00 -t 00:00:01 -i "$vidfile" -r 0.1 "$framefile"
framefile="$vidfile.frame-001.jpg"
framefile2="$vidfile.backdrop.jpg"

convert "$framefile" -resize "${dimensions}^" -gravity center -crop "${dimensions}+0+0" +repage  -blur 0x3 -paint 7 -blur 1x4 "$framefile2"

echo $backdrop

