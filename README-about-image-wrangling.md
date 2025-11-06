# A set of image metadata and conversion tools


Given:

A folder or subfolder full of downloaded images, some as webp.

Extract the provenance data, 
Stamp the files with index info so we can find the originals later
Generate derivatives we can work with
File the originals away somewhere safe


## `Process-clips`

Runs the following steps


### `process-metadata`

To add some metadata to keep track of things.

The idea is to tag and identify things before they get absorbed into an image management system where they may be moved, converted and renamed.

* Generate a UUID based on the binary hash, and add that as exif metadata
* Record the provenance (if known) and set that as the source in metadata
* Tag the file with the filename as the descriotion, to try and retain that info after renaming.
* Tag the file with a keyword named after the directory it is found in

> exiftool 2023 can read but not write webp metadata.

### `webp2gif`

Greate a gif variation of any webp files, if needed.

### `duplicate-exif-from-webp`

For cases where a new gif was generated, read the exif from the webp and apply it to the corresponding gif

### `move-file-to-uuid-archive`

Archive the webp files into a storage area where they are indexed by UUID.
