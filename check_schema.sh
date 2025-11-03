#!/bin/bash

# Source the library to initialize the database
source process_media.lib

echo "Checking database schema..."
echo ".schema" | sqlite3 "$MEDIA_DB"