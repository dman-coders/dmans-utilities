#!/bin/env bash

export UTIL_DIR=~/.media_processing_test

LIB_DIR=$(dirname $0)
source "$LIB_DIR/process_media.lib"

log_notice "testing a few utilities in a test DB"

bash "${LIB_DIR}/test_ensure_tag_exists.sh"

dump_tags
dump_db