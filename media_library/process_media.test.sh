#!/usr/bin/env bash

export UTIL_DIR=~/.media_processing_test
export MEDIA_DB="$(dirname "${BASH_SOURCE[0]}")/tests/test.sqlite"

LIB_DIR=$(dirname $0)
source "$LIB_DIR/process_media.lib"

log_notice "testing a few utilities in a test DB"

bash "${LIB_DIR}/tests/test_ensure_tag_exists.sh"

dump_tags
dump_db

bash "${LIB_DIR}/tests/test-process-tags-to-db.sh"
