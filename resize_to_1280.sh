#!/bin/bash

# If your image folder is too big,
# and you really don't have to keep the originalt at 400DPI for web use,
# scrunch your pictures.

mogrify -quality 85% -resize 1280x960\> *.jpg
