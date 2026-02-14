# Jellyfin Thumbnail Management

## Overview

Jellyfin manages thumbnails and images using a **tag-based system**. Each item can have multiple image types (Primary, Backdrop, Art, Thumb, etc.), and each image type can have multiple versions identified by unique tags.

**On-Demand vs Pre-Cached:**
- Jellyfin **generates images on-demand** by default when you request them via the image endpoint
- It **caches resized/formatted versions** after the first request to the cache directory
- You can check if a thumbnail is pre-cached by querying the `/Items/{itemId}/Images` endpoint, which returns `ImageInfo` objects including the file `Path` and `Size`

From the example item response (`6ab51bc9765f4df9036079657f612601`):
```json
"ImageTags": {
  "Primary": "cca77c6e8a459a4f32f4513b24665383"
},
"ImageBlurHashes": {
  "Primary": {
    "cca77c6e8a459a4f32f4513b24665383": "WbGk%jR5D%sS%gW=~qMxMxaytRoL?cIURPWBozof-;RPRjj[ofof"
  }
}
```

---

## How the API Tells Clients About Images

The Jellyfin API provides image information through two main channels:

### 1. GetItem Response (Quick lookup)
Returns `ImageTags` dictionary showing which image tags are available for each type:
```json
{
  "ImageTags": {
    "Primary": "cca77c6e8a459a4f32f4513b24665383"
  },
  "ImageBlurHashes": {
    "Primary": {
      "cca77c6e8a459a4f32f4513b24665383": "WbGk%jR5D%sS%gW=~qMxMxaytRoL?cIURPWBozof-;RPRjj[ofof"
    }
  },
  "PrimaryImageAspectRatio": 1.7769230769230768
}
```

**This tells clients:**
- The tag to use in the image URL
- The aspect ratio for layout planning
- The BlurHash for showing a placeholder while loading

### 2. GetItemImages Endpoint (Detailed info)
**Endpoint:** `GET /Items/{itemId}/Images`

**Returns:** Array of `ImageInfo` objects with:
- `ImageType` - e.g., "Primary", "Backdrop"
- `ImageTag` - the unique tag
- `Path` - **file path on server** (if pre-cached)
- `Width`, `Height` - dimensions
- `Size` - file size in bytes
- `BlurHash` - blurhash representation

**This tells clients:**
- Whether the image is pre-cached (if `Path` and `Size` are present)
- Actual dimensions and file size
- Where the image is stored on the server

**Using the JellyFin wrapper:**
```bash
./JellyFin GetItem 6ab51bc9765f4df9036079657f612601 --fields ImageTags,PrimaryImageAspectRatio
```

---

## A: Retrieve the Path to a Jellyfin Thumbnail

### Method 1A: Simple Query Parameter URL (Recommended for Clients)

This is what you discovered - the simplest way to get an image:

**Endpoint:** `GET /Items/{itemId}/Images/{imageType}`

**Query Parameters:**
- `tag` - The image tag from `ImageTags`
- `fillHeight` - Desired height (maintains aspect ratio)
- `fillWidth` - Desired width (maintains aspect ratio)
- `quality` - JPEG quality 0-100 (default 90)
- Optional: `width`, `height` for fixed dimensions
- Optional: `format` for output type

**Example URL:**
```bash
http://granite.local:8096/Items/6ab51bc9765f4df9036079657f612601/Images/Primary?fillHeight=400&fillWidth=710&quality=96&tag=cca77c6e8a459a4f32f4513b24665383
```

**This is the approach your browser used - it's simple and requires no path construction!**

### Method 1B: Complex Path-Based URL (Alternative)

**Endpoint:** `GET /Items/{itemId}/Images/{imageType}/{imageIndex}/{tag}/{format}/{maxWidth}/{maxHeight}/{percentPlayed}/{unplayedCount}`

**Path Parameters:**
- `itemId` - The item UUID (e.g., `6ab51bc9765f4df9036079657f612601`)
- `imageType` - Type: `Primary`, `Backdrop`, `Art`, `Thumb`, `Disc`, `Box`, `Screenshot`, `Menu`, `Chapter`, `Banner`, `Logo`, `BoxRear`, `Profile`
- `tag` - The image tag from `ImageTags`
- `format` - Output format: `Bmp`, `Gif`, `Jpg`, `Png`, `Webp`, `Svg`
- `maxWidth` / `maxHeight` - Resize to fit within dimensions
- `percentPlayed` / `unplayedCount` - Optional overlays (typically 0)

**Example URL:**
```bash
# Get 300x300 Primary image as JPEG
http://granite.local:8096/Items/6ab51bc9765f4df9036079657f612601/Images/Primary/0/cca77c6e8a459a4f32f4513b24665383/Jpg/300/300/0/0
```

**Note:** This path-based approach is more complex but supports more options via query params: `width`, `height`, `quality`, `fillWidth`, `fillHeight`

### Method 2: Get Image Metadata

**Endpoint:** `GET /Items/{itemId}/Images`

**Purpose:** Returns metadata about all images associated with an item

**Returns:** Array of `ImageInfo` objects containing:
- Image type
- Image index
- Image tag
- Width, height, size
- Blur hash

**Example:**
```bash
./JellyFin GetItem <itemId> --fields ImageTags,ImageBlurHashes
```

---

## B: Update Item Record to Define Preferred Thumbnail

### Method 1: Set Primary Image (Metadata Update)

**Endpoint:** `POST /Items/{itemId}` (via UpdateItem wrapper)

**Purpose:** Update item metadata including the primary image tag

**Request Body:** BaseItemDto with `ImageTags` property

**Example:**
```json
{
  "ImageTags": {
    "Primary": "new_image_tag_here"
  }
}
```

Using the JellyFin wrapper:
```bash
./JellyFin UpdateItem <itemId> '{"ImageTags": {"Primary": "new_tag"}}'
```

**Note:** This updates the metadata to reference a different existing image, it doesn't create a new image.

### Method 2: Upload New Image

**Endpoint:** `POST /Items/{itemId}/Images/{imageType}`

**Purpose:** Upload a new image file and set it as the specified image type

**Request:** Binary image data (Content-Type: `image/*`)

**HTTP Methods Available:**
- `POST` - Set/upload new image
- `DELETE` - Remove image of type
- `GET` - Retrieve image
- `POST .../Index` - Set which index is primary

**Example with curl:**
```bash
curl -X POST \
  -H "Authorization: MediaBrowser Token=\"$JELLYFIN_API_KEY\"" \
  --data-binary @/path/to/thumbnail.jpg \
  "http://granite.local:8096/Items/{itemId}/Images/Primary"
```

**Image Types Supported:**
- `Primary` - Main thumbnail
- `Backdrop` - Background/hero image
- `Art` - Album art style
- `Thumb` - Smaller thumbnail variant
- `Disc` - DVD/Blu-ray disc art
- `Box` - Box art
- `Logo` - Logo image
- `Banner` - Wide banner image
- `Screenshot` - Screenshot
- `Menu` - Menu image
- `Chapter` - Chapter image
- `BoxRear` - Back of box art
- `Profile` - Profile picture

---

## Are Thumbnails Pre-Calculated or On-the-Fly?

**Answer: Both, depending on the situation**

- **First request:** Jellyfin generates the image on-the-fly from the original source (video frame, uploaded image, etc.)
- **Subsequent requests:** Jellyfin serves from cache (caches resized versions for performance)

Not all transcodes appear to be possible - eg requesting a Webp or Jpeg of a gif still returns a gif.

### How to Check if an Image is Pre-Cached

**Endpoint:** `GET /Items/{itemId}/Images`

This returns `ImageInfo` objects with:
- `Path` - File path on the server
- `Size` - File size in bytes

**If `Path` and `Size` are present:** Image is already cached on disk
**If `Path` is null or `Size` is 0:** Image will be generated on-demand

**Example to check:**
```bash
# Get image cache status
curl -s -H "Authorization: MediaBrowser Token=\"$JELLYFIN_API_KEY\"" \
  "http://granite.local:8096/Items/6ab51bc9765f4df9036079657f612601/Images" \
  | jq '.[] | {ImageType, ImageTag, Path, Size}'
```

**In your JellyFin wrapper** (if we add the Images function):
```bash
./JellyFin GetItemImages 6ab51bc9765f4df9036079657f612601
```

---

## Complete Workflow Example

### 1. Get Current Images for an Item
```bash
./JellyFin GetItem 6ab51bc9765f4df9036079657f612601 --fields ImageTags
```

Output shows:
```json
"ImageTags": {
  "Primary": "cca77c6e8a459a4f32f4513b24665383"
}
```

### 2. Retrieve the Current Thumbnail Image
```bash
# Get as 400x400 JPEG (best for preview)
wget -O thumbnail.jpg \
  "http://granite.local:8096/Items/6ab51bc9765f4df9036079657f612601/Images/Primary/0/cca77c6e8a459a4f32f4513b24665383/Jpg/400/400/0/0"
```

### 3. Update to a Different Existing Image
```bash
# If item has multiple images, reference a different tag
./JellyFin UpdateItem 6ab51bc9765f4df9036079657f612601 \
  '{"ImageTags": {"Primary": "different_tag_value"}}'
```

### 4. Upload New Thumbnail
```bash
curl -X POST \
  -H "Authorization: MediaBrowser Token=\"$JELLYFIN_API_KEY\"" \
  --data-binary @new_thumbnail.jpg \
  "http://granite.local:8096/Items/6ab51bc9765f4df9036079657f612601/Images/Primary"
```

---

## Technical Notes

### Image Storage
- Jellyfin stores images in the cache directory
- Path pattern: `{library}/metadata/{item-id}/`
- Images are identified by UUID tags, not filenames
- The `ImageBlurHash` provides a compact representation for UI rendering while loading

### Image Tag System
- `ImageTags` is a dictionary mapping image type to tag
- Each tag is a unique identifier for that specific image file
- Same tag = same image file (used for caching)
- Changing the tag pointer doesn't delete old images

### Performance Considerations
- Use `maxWidth` and `maxHeight` for efficient thumbnail sizes (300-400px typically good)
- Jellyfin caches resized images, so first request may be slower
- Use `quality` parameter to balance file size vs visual quality
- `BlurHash` can be shown while actual image loads

### API Security
- Most image operations require authentication
- Some require elevation/admin privileges
- `POST` operations (uploading) require `RequiresElevation`

---

## Related Files
- `JELLYFIN_OPENAPI.json` - Full API specification
- `JELLYFIN_DATA_MODEL.md` - Additional API documentation
- `README-utilities.md` - Function index and quick start

---

**Last Updated:** 2025-02-14
**Source:** Jellyfin OpenAPI v10.8.x