#!/usr/bin/env bash
set -e

export UTIL_DIR=~/.media_processing_test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MEDIA_DB="$SCRIPT_DIR/test.sqlite"
# Setting this will mean that the tests run in a virtual tmpfs filesystem if available
export SQLITE_USE_TMPFS=1

source "$SCRIPT_DIR/../process_media.lib"

log_notice "Running all tests in a test DB $MEDIA_DB"

bash "${SCRIPT_DIR}/test_create_fixtures.sh"
bash "${SCRIPT_DIR}/test_ensure_tag_exists.sh"
bash "${SCRIPT_DIR}/test_accessor_patterns.sh"
bash "${SCRIPT_DIR}/test_parent_child.sh"
bash "${SCRIPT_DIR}/test_longnames.sh"
bash "${SCRIPT_DIR}/test_pipe_in_names.sh"
bash "${SCRIPT_DIR}/test_longnames.sh"
bash "${SCRIPT_DIR}/test_synonyms.sh"

dump_tags
dump_db

bash "${SCRIPT_DIR}/test_process_tags_to_db.sh"

close_database