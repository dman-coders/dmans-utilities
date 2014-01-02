#!/bin/bash

# Given a cbz, cbr, tar or zip,
# unpack it enough to find an image
# get the thumbnail of that image
# copy that thumb to use as a file icon on the package
# maybe also support other metadata in a ComicBookLover or XMP compatible way.

export TEMPDIR="/tmp/enthumb";
if [ ! -d $TEMPDIR ] ; then
  mkdir $TEMPDIR
fi

# Mac utilities!
export PATH_TO_SIPS=sips
export PATH_TO_DEREZ=DeRez
export PATH_TO_REZ=Rez
export PATH_TO_SETFILE=SetFile

# Need this as there can be spaces in the name. It changes the delimiter that 'for' uses here.
IFS=$'\n\b'

########################################################
# Begin

# Do one file at a time. 
# If called with more than one arg, split the list and recurse

if [ $# \> 1 ] ; then
  echo "There are $# args"
  for i in "$@" ; do
    # call self now, but just with one arg;
    echo "Recursing to process $1"
    $0 "$i"
  done
  echo done all;
  exit;
fi;




export ARCHIVE="$1"
echo "Enthumbnailing $ARCHIVE";

export file_type_info=(`file --brief "$ARCHIVE"`);
# This will now be RAR, ZIP, TAR or other
echo "File info says $ARCHIVE is a $file_type_info";


case "$file_type_info" in 

  ZIP* | Zip* )
    echo unpacking a zip.
    # Look into the archive and extract the first jpg
    # -Z is zipinfo, and a quieter way to list just filenames
    for FILE in `unzip -Z -1 "$ARCHIVE"` ; do
      case "$FILE" in
        *.jpg | *.JPG | *.jpeg | *.JPEG )
        printf 'Image File found: '"'%s'"'\n' "$FILE";
        export COVER_IMAGE="$FILE";
        break;
      esac
    done
  
    # If found a file in the package, extract just it to the temp dir
    if [ -n "$COVER_IMAGE" ] ; then
      unzip "$ARCHIVE" "$COVER_IMAGE" -d "$TEMPDIR";
      echo "Extracted '$COVER_IMAGE' from '$ARCHIVE' into $TEMPDIR";
      export COVER_PATH="${TEMPDIR}/${COVER_IMAGE}" 
    else
      echo "No prime file found in RAR $ARCHIVE, no thumb"
    fi
  ;;
  
  TAR* )
  echo "I should unpack it";
  #tar --extract  --directory="$TEMPDIR" --file="$ARCHIVE"
  ;;
  
  RAR* )
    # Look into the archive and extract the first jpg
    # lb = 'list bare'
    # Rar DOES NOT show subfolders, making it impossible to extract a thumb if it's deep.
   
    for FILE in `unrar lb "$ARCHIVE"` ; do
      case "$FILE" in
        *.jpg | *.JPG | *.jpeg | *.JPEG )
        printf 'Image File found: '"'%s'"'\n' "$FILE";
        export COVER_IMAGE="$FILE";
        break;
      esac
    done

    # If found a file in the package, extract just it to the temp dir
    if [ -n "$COVER_IMAGE" ] ; then
      unrar e "$ARCHIVE" "$COVER_IMAGE" "$TEMPDIR";
      export COVER_PATH="${TEMPDIR}/${COVER_IMAGE}" 
      if [[ -f $COVER_PATH ]] ; then
        echo Extracted $COVER_IMAGE from $ARCHIVE into $TEMPDIR;
      else 
        echo "Looks like I failed to unrar $COVER_IMAGE from $ARCHIVE. This may be due to subfolders."
        COVER_PATH=""
      fi
    else
      echo "No prime file found in RAR $ARCHIVE, no thumb"
    fi
  ;;
  
  
  directory )
    SCAN="$ARCHIVE/*"
    for FILE in $SCAN; do
      echo $FILE;
      case "$FILE" in
        *.jpg | *.JPG | *.jpeg | *.JPEG )
        printf 'Image File found: '"'%s'"'\n' "$FILE";
        export COVER_IMAGE="$FILE";
        export COVER_PATH="${TEMPDIR}/COVER_IMAGE" 
        cp "$COVER_IMAGE" "$COVER_PATH"
        break;
      esac
    done
    # directories may or may not have their trailing slash when entered
    # I add my own each time, as double-ups are sorta allowed.
    
    
  ;;
  
esac

succeeded=0
if [ -n "$COVER_PATH" ] ; then
  # Thanks to http://superuser.com/questions/133784/manipulate-mac-os-x-file-icons-from-automator-or-command-line
  # Generate the thumbnail resource for this image
  echo "Aut-generating thumbnail for the cover image itself"
  $PATH_TO_SIPS --addIcon "$COVER_PATH"
  echo "Pretty sure I have a thumbnail now. Transferring it to the archive"
  $PATH_TO_DEREZ -only icns "$COVER_PATH" > "${TEMPDIR}/tempicns.rsrc"
  # Now apply this resource to the original archive file
  
  if [ -f "$ARCHIVE" ]; then
    # Destination is a file
    $PATH_TO_REZ -append "${TEMPDIR}/tempicns.rsrc" -o "$ARCHIVE" && success=1
    # And flag C for CustomIcon on
    $PATH_TO_SETFILE -a C "$ARCHIVE"
  elif [ -d "$ARCHIVE" ]; then
    echo Destination is a directory
    # Create the magical Icon\r file
    #$iconDestination/$'Icon\r'
    MAGIC=$'Icon\r';
    echo "Attemoting to set magic file $ARCHIVE/$MAGIC"
    touch "$ARCHIVE/$MAGIC"
    $PATH_TO_REZ -append "${TEMPDIR}/tempicns.rsrc" -o "$ARCHIVE/$MAGIC"  && success=1
    $PATH_TO_SETFILE -a C "$ARCHIVE"
    # hide the magic resource by setting it to V
    $PATH_TO_SETFILE -a v "$ARCHIVE/$MAGIC"
  fi  
  
  #$PATH_TO_REZ -append "${TEMPDIR}/tempicns.rsrc" -o "$ARCHIVE"
  echo Applied icon to "$ARCHIVE"

else
  echo "No prime file found in $ARCHIVE, no thumb applied."
fi

# Cleanup
if  [[ -f "$COVER_PATH" ]] && [[ $success ]]  ; then 
  rm "$COVER_PATH" "${TEMPDIR}/tempicns.rsrc"
else
  echo "Looks like I failed."
fi


echo .