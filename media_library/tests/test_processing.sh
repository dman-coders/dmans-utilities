#!/usr/bin/env bash

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_SCRIPT_DIR/../process_media.lib"
source "$TEST_SCRIPT_DIR/test_framework.sh"

init_test_suite "Bulk processing of media files"

function processFile {
    # Spawned sub-processes need to require their dependenciies again.
    source "$TEST_SCRIPT_DIR/../process_media.lib"
    source "$TEST_SCRIPT_DIR/test_framework.sh"

    local file_path="$1"
    log_info "Processing file: $file_path"
    # Simulate processing delay
    sleep 1
    assert_true "true" "Processed file $file_path."
    log_info "Finished processing file: $file_path"
}

######
cd "$TEST_SCRIPT_DIR"


begin_test "Run the arbitrary ProcessFile command on a single file "
parallelProcessFiles "fixtures/test-image.jpg"

begin_test "Run the arbitrary ProcessFile command on multiple files in parallal : shell globbing"
files_to_process=( fixtures/*.jpg )
parallelProcessFiles "${files_to_process[@]}"

begin_test "Run the arbitrary ProcessFile command on multiple files in parallal : dir recursion"
parallelProcessFiles "fixtures/"

finish_test_suite
exit $?