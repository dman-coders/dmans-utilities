#!/bin/bash

# As cbr is deprecated by the more advanced comic book readers, old
# .cbr or .rar archives should be re-packed as zips.

echo "Converting CBR  (Comic Book RAR archive) file to CBZ (Comic Book Zip archive) format as CBR are not as well supported for metadata.
"

# Use getopt to read parameters.
PARSED_OPTIONS=$(getopt -n "$0"  -o "dh?q" --long "delete,help,quiet"  -- "$@")
eval set -- "$PARSED_OPTIONS"

QUIET=0;

while true;
do
  case "$1" in
    -h|-\?|--help)
     echo "usage $0 [-h|-?|--help] [-d|--delete] filename.cbr"
     echo "  --delete option will remove the original file. Take care."
     shift;
     exit;
     ;;
    -d|--delete)
      DELETE=1; shift;;
    -q|--quiet)
      QUIET=1; shift;;
    --)
      shift; break;;
  esac
done

# Check unrar requirement.
rarbin=`which unrar`
if [ "$rarbin" == "" ] ; then
  echo "You need unrar on the commandline. Install with 'sudo apt-get install unrar'"
  echo "'With OSX homebrew you can install it with  'brew install unrar'"
  exit 1
fi

# At least one filename is expected.
if [ $# -lt 1 ] ; then
  echo "Please pass in a file name to convert."
  exit 1
fi

# Loop over remaining filename args.
while sourcefilename="$1"; do
  if [ "$sourcefilename" == "" ] ; then break; fi;
  shift;

  basename=$(basename "$sourcefilename")
  extension="${basename##*.}"
  filename="${basename%.*}"

  if [ "$extension" != "cbr" ] && [ "$extension" != "rar" ] ; then 
    echo "Skipping '$sourcefilename'. This only works on .cbr or .rar files."
    continue;
  fi

  if [ ! -f "$sourcefilename" ]; then
    echo "Skipping '$sourcefilename'. File not found.";
    continue;
  fi

  #######################
  # Actually begin here.
  #######################

  [ $QUIET == 1 ] || echo "Processing '$sourcefilename'.";
  [ $QUIET == 1 ] || echo "Unpacking archive temporarily to recompile ${filename}";

  mkdir "/tmp/${filename}"
  # To quieten unrar messages is -idq
  $rarbin -idq x "$sourcefilename" "/tmp/${filename}"
  rarsuccess=$?
  [ $QUIET == 1 ] || echo "Unpacked to /tmp/${filename}";
  if [[ $rarsuccess -ne 0 ]] ; then
    echo "**** Unpacking '$sourcefilename' threw an error or warning."
  fi

  # Need to pushd or we get unwanted leading folder names.
  here=`pwd`
  pushd "/tmp";
  zip --quiet -r "$here/${filename}.cbz" "${filename}"
  popd;
  echo "Created '$here/${filename}.cbz'"

  rm -rf "/tmp/${filename}"
  if [[ $DELETE && ( $rarsuccess -eq 0 ) ]] ; then
    echo "** Deleting original '$sourcefilename' file!"
    rm "$sourcefilename";
  fi

  [ $QUIET == 1 ] || echo "Cleaned up, deleted /tmp/${filename}";

done; # end loop

echo "Done."

