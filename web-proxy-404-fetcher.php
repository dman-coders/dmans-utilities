<pre>
<?php
/**
 * @file
 *   Proxy file fetcher Used to suipport a sparse mirror of a remote site. Use
 * this script as a 404 handler Lost files will be retrieved, cached, and served
 * behind the scenes when they are requested
 *
 *
 * To set up a full static site mirror from anywhere else:
 * # Make an Apache vhost named, eg mirror.sitename.local, pointing to an empty directory
 * # place this proxy script where it can be found, eg in {DocumentRoot}/wrapper/web-proxy-404-fetcher.php
 * # in the htaccess fil for that site (or even in the Vhost)
 * add the following line as a 404 handler
 *  ErrorDocument 404 /wrapper/web-proxy-404-fetcher.php?target_base=http://sitename.com/
 *
 * Now when you visit http://mirror.sitename.local/ content from http://sitename.com/ will be served in its place.
 *
 * If the pages you visit are several sections deep, you may find that DirectoryIndexing serves the content instead.
 * - you will see directory listings of folders that were created before the index file was retrieved.
 * To avoid that, Also add the lines
 *  Options -Indexes
 *  ErrorDocument 403 /wrapper/web-proxy-404-fetcher.php?target_base=http://sitename.com/
 * and local dirs will not be indexed, instead they will error, and the error will use the same fetcher behavior as the 404 
 *
 *
 * To work within Drupal, and override the files directory so they get retrieved as needed:
 * In the root .htaccess, where Drupal adds the rewrite rules,
 * Add the following extra exception
 *
 * RewriteCond         %{REQUEST_URI} !^/sites/default/files/imported/.*
 *
 * Modify
 * /sites/default/files/.htaccess
 *
 * and comment out the
 *
 * #SetHandler Drupal_Security_Do_Not_Remove_See_SA_2006_006
 *
 * Now, in the file
 * /sites/default/files/.htaccess
 * (create it)
 * Add
 *
 * ErrorDocument 404 /sites/default/files/imported/web-proxy-404-fetcher.php?target_base=http://sitename.com/&local_base=/sites/default/files/
 *
 * COPY this file into that named location, and adjust some paths as needed.
 *
 * @author Dan (dman) Morrison 2010-10
 */

// Parameters can be set here, or passed in dynamically through the GET parameter
// Set up the .htaccess to define ?target_base=http://example.com/ and that will be the target_base

print_r($_SERVER);
print_r($_REQUEST);

// Where this script is running from
#$ local_base = '/sites/default/files/';
$local_base = '/';

// Where to get stuff from
$target_base = 'http://legacy.linz.govt.nz/' ;

################################################################################


// What we were asked for
$request_path = isset($_SERVER['REDIRECT_URL']) ? $_SERVER['REDIRECT_URL'] : @$_REQUEST['request_path'] ;

// Subdir is an optional argument. Should end with a /
$subdir = @$_REQUEST['subdir'];

// Allow script parameters to override/configure us.

// Where, relative to serverroot this mirror is based
$local_base = (@$_REQUEST['local_base'] ? @$_REQUEST['local_base'] : $local_base ) . $subdir;

// Where to get stuff from
$target_base = @$_REQUEST['target_base'] ? @$_REQUEST['target_base'] : $target_base ;


// What to get this time
if ($local_base != '/') {
  // Remove the local base from the request (may be just '/')
  $target_path = str_replace($local_base, '', $request_path);
  // Glue on the target base, and we have our URL.
  $target_path = $target_base . ltrim($target_path, '/');
}
else {
  // special (normal) case, this server mirror is based at the root. Just prepend the remote base
  $target_path = rtrim($target_base, '/') . $request_path;
}

// Where to store what we get
$local_filepath = $_SERVER['DOCUMENT_ROOT'] . $request_path;

// if it seems we are about to save something with no suffix, 
// make a dir and save an index.html in it
if ('' == pathinfo($request_path, PATHINFO_EXTENSION)) {
  $local_filepath .= "/index.html";
}


#print_r(get_defined_vars());

$message = "Asked for '$request_path', fetching '$target_path' to store it locally at '$local_filepath'";
error_log(basename(__FILE__) .' : '. $message, 0 );

$target_content = '';

// Before requesting the file, set a context to say we refuse gzipped response, otherwise we have to unzip it
// Create a stream
$opts = array(
  'http'=>array(
    'method' => "GET",
    'header' => "Accept-Encoding: gzip;q=0, compress;q=0\r\n", //Sets the Accept Encoding Feature.
  )
);
$context = stream_context_create($opts);


#if (file_exists($target_path)) {
  $target_content = file_get_contents($target_path);
#}

// Rough search & replace to fix URLs if they pointed at full URLs that match the from location
$target_content = str_replace($target_base, $local_base, $target_content);

if (!empty($target_content)) {
  if ( ensure_directory_exists(dirname($local_filepath)) ) {
    file_put_contents($local_filepath, $target_content);
    chmod($local_filepath, 0664);
    // Redirect to it now
    $redirect_target = "http://{$_SERVER['HTTP_HOST']}{$request_path}";
    #print("Go to <a href='$redirect_target'>$redirect_target</a> now");
    header("Location: $redirect_target");
  }
  else {
    trigger_error("Failed to prepare a save location to save '$local_filepath' in.");
  }
}
else {
  $message = "No content retrieved from '$target_path'";
  error_log(basename(__FILE__) .' : '. $message, 0 );
  print($message);
}


function ensure_directory_exists($dirpath, $mode = 0775) {
  if (is_dir($dirpath)) return TRUE;
  if (ensure_directory_exists(dirname($dirpath), $mode)) {
    if (mkdir($dirpath)) {
      chmod($dirpath, $mode);
      return TRUE;
    }
  }
  // Dunno why we'd fail, but fail anyway
  return FALSE;
}
