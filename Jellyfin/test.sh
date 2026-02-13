# Things to try with Jellyfin API:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jellyfin-utils.lib"

# List the collections
jf ListCollections

# Select a random collections
COLLECTION_JSON=$( jf ListCollections | jq -r 'to_entries | .[now % length].value' )
COLLECTION_NAME=$(echo $COLLECTION_JSON | jq -r '.Name')
COLLECTION_ID=$(echo $COLLECTION_JSON | jq -r '.Id')
log_success "Selected collection: $COLLECTION_NAME $COLLECTION_ID"

# List the items in that collections
#COLLECTION_ITEMS=$( ./CollectionItems "$COLLECTION_ID" )

# Select a random item from the collection.
# Select a media resource, not a container.
ITEM_JSON=$( jf CollectionItems "$COLLECTION_ID"  | jq -r 'to_entries | .[now % length].value' )
if [[ -z "$ITEM_JSON" ]]; then
    log_error "No items found in collection $COLLECTION_NAME ($COLLECTION_ID)"
    exit 1
fi
ITEM_NAME=$(echo $ITEM_JSON | jq -r '.Name')
ITEM_ID=$(echo $ITEM_JSON | jq -r '.Id')
log_success "Selected Item: $ITEM_NAME $ITEM_ID"

# Retrieve details about that item
# The JSON retrieved from the first lookup was 1/3 of the full data.
# Doesn't even include Path or metadata, mostly just JF organizational info..
ITEM_JSON=$( jf GetItem "$ITEM_ID" )
echo "$ITEM_JSON" | jq

# Find the file path on the server
#SERVER_FILE_PATH=$( echo "$ITEM_JSON" | jq -r '.MediaSources[0].Path' )
SERVER_FILE_PATH=$( echo "$ITEM_JSON" | jq -r '.Path' )

# convert that to a local path
LOCAL_FILE_PATH=$( jellyfin_local_path "$SERVER_FILE_PATH" )
# See if we can access it directly.
if [[ -f "$LOCAL_FILE_PATH" ]]; then
    log_success "Local file exists. '$LOCAL_FILE_PATH'"
else
    log_error "Local file is not accessible! Is the drive mapping atttached? '$LOCAL_FILE_PATH' "
fi

# Investigate the local path.
exiftool "$LOCAL_FILE_PATH"

# run some processes to ensure the metadata is clean and synchronised with the local media_library database
process-clips "$LOCAL_FILE_PATH"

######

# It seems that [box set] collections can only collect videos, not images.
# Try adding an item (in this case an iomage) to a collections.
IMAGE_ITEM_ID=a9d73876e9fb9682fa94c50a850e8fd1
VIDEO_ITEM_ID=8cac5059e3a6a58d2776ab029f75dc60
CURRENT_PARENT=f5c55291c1303a74c6daf09cd24c829e
TARGET_COLLECTION=3373004dfb73c7f8fd0e3b9eea701099
TARGET_COLLECTION=04f50e97aeb652dbaec8bf8fdc652e4b # Blowjob collection
PHOTO_ALBUM=4d94cf143866f724bc51f89eefabf2d6
# List current members
./CollectionItems $TARGET_COLLECTION | jq -r '.[] | "\(.Id), \(.Type), \"\(.Name)\",  \"\(.Path)\""'

# Add video to Collection
./AddItemToCollection "$TARGET_COLLECTION" "$VIDEO_ITEM_ID"
# Adding Image Item to Collection
./AddItemToCollection "$TARGET_COLLECTION" "$IMAGE_ITEM_ID"

# List current members to confirm they are now included
./CollectionItems $TARGET_COLLECTION | jq -r '.[] | "\(.Id), \(.Type), \"\(.Name)\",  \"\(.Path)\""'

###

# 26953732.gif Asian, Deepthroat, Blowjob
PHOTO_ITEM_ID=1a8ea828f2c8802f7940facb69a035c6
# HOWTO/deepthroat all the way
PHOTO_ALBUM_ID=4d94cf143866f724bc51f89eefabf2d6

ETHNICITY_COLLECTION=$(./CreateCollection "Ethnicity")
# ETHNICITY_COLLECTION=4e42f087638925ca919f59d3ff225327
ASIAN_COLLECTION=$(./CreateCollection "Asian")
#ASIAN_COLLECTION=b1db25f75d3251f46e6117a4f32616c1
./AddItemToCollection $ETHNICITY_COLLECTION $ASIAN_COLLECTION
# ^ says OK, but the paernt remains the original Folder (Album). Which is correct. But dunno where that setting went.
./AddItemToCollection $ASIAN_COLLECTION $PHOTO_ITEM_ID

PHOTO_JSON=$(./GetItem $PHOTO_ITEM_ID)
# ^ THis is fine, ParentId remains the original PHOTO_ALBUM_ID
# Yet the Photo can be found correctly in the ASIAN_COLLECTION when listing its items.
./CollectionItems $ASIAN_COLLECTION | jq -r '.[] | "\(.Id), \(.Type), \"\(.Name)\",  \"\(.Path)\""'

# Because the `Items lookup with filter of ParentID recognises all valid parents, even if it doesn't' list them