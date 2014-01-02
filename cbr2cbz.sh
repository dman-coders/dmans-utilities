#!/bin/bash

# As cbr is deprecated by the more advanced comic book readers, old
# .cbr or .rar archives should be re-packed as zips.

echo "Converting CBR  (Comic Book RAR archive) file to CBZ (Comic Book Zip archive) format as CBR are not as well supported for metadata.
"

# Use getopts to read parameters.
# Apparently it's more reliable than getopt, but doesn't do long opts (wtf?)
QUIET=0;

while getopts ":dhq?" opt; do
  case "$opt" in
    -h|-\?)
     echo "usage $0 [-h|-?] [-d] filename.cbr"
     echo "  -d (delete) option will remove the original file. Take care."
     shift;
     exit;
     ;;
    -d)
      DELETE=1; shift;;
    -q)
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
  zip -q -r "$here/${filename}.cbz" "${filename}"
  popd;
  if [ -e "$here/${filename}.cbz" ]; then
    echo "Created '$here/${filename}.cbz'"
  else
    echo "**** Something screwed up, failed to create zipfile for ${filename}."
    exit 1;
  fi

  rm -rf "/tmp/${filename}"
  if [[ $DELETE && ( $rarsuccess -eq 0 ) ]] ; then
    echo "** Deleting original '$sourcefilename' file!"
    rm "$sourcefilename";
  fi

  [ $QUIET == 1 ] || echo "Cleaned up, deleted /tmp/${filename}";

done; # end loop

echo "Done."

