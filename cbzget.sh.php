#!/usr/bin/php
<?php
/**
 * @file Make a zip of images from a web page
*/

# Given an URL of a page containing a gallery,
# download the images,
# zip them into an album


require_once 'Console/CommandLine.php';
require_once 'Log.php';
require_once 'Net/URL2.php';

global $logger;
$logger = Log::singleton('console', '', 'ident', NULL, PEAR_LOG_INFO);
function print_log($message, $priority = PEAR_LOG_INFO){
  global $logger;
  $logger->log($message, $priority);
};


// Start parsing options

$parser = new Console_CommandLine();
$parser->description = 'Lists files in the current directory and creates a full size PDF or HTML page listing them with any available metadata.';
$parser->version = '1.1';
$parser->addArgument('url', array('multiple'=>true, 'required' => TRUE));
$parser->addOption('quiet', array(
    'short_name'  => '-q',
    'long_name'   => '--quiet',
    'description' => "don't print status messages to stdout",
    'action'      => 'StoreTrue'
));
$parser->addOption('verbose', array(
    'short_name'  => '-v',
    'long_name'   => '--verbose',
    'description' => "display extra log messages",
    'action'      => 'StoreTrue'
));



global $commandline_input;
try {
    $commandline_input = $parser->parse();
} catch (Exception $exc) {
    $parser->displayError($exc->getMessage());
}
$options = $commandline_input->options;

if ($options['verbose']) { $logger->setMask(PEAR_LOG_ALL); ; }
if ($options['quiet']) { $logger->setMask(PEAR_LOG_NONE); ; }
$urls = $commandline_input->args['url'];

#print_r($commandline_input);
////////////////////////////////////////////////////////////////////////////
// START

foreach ($urls as $url) {
  try {
    $base_url = new Net_URL2($url);
    $safe_name = preg_replace('/[^a-zA-Z0-9_\-]+/', '_', $base_url->host);
    if (substr($safe_name, 0, 3) == 'www') {
      $safe_name = substr($safe_name, 4);
    }
    if ($base_url->path) {
      $safe_name .= '-' .  preg_replace('/[^a-zA-Z0-9_\-]+/', '-', $base_url->path);
    }
    $dirname = "/tmp/$safe_name";
    mkdir($dirname);

    $page_title = preg_replace('/[^a-zA-Z0-9_\-]+/', ' ', $base_url->path) . ' - ' . $base_url->host; 

    print_log("Fetching $url");
    $page_source = file_get_contents($url);
    $doc = new DOMDocument(); 
    @$doc->loadHTML($page_source);

    $tags = $doc->getElementsByTagName('title');
    foreach ($tags as $tag) {
      $page_title = $tag->textContent; 
    }

    $tags = $doc->getElementsByTagName('img');

    $contents = array();
    foreach ($tags as $tag) {
      // If the image is surrounded by an a tag
      // And that links directly to a jpeg, get that instead
      $tag_parent = $tag->parentNode;
      while ($tag_parent && $tag_parent->nodeName != 'a') {
        $tag_parent = $tag_parent->parentNode;
      }
      if ($tag+parent && $tag_parent->nodeName == 'a') {
        $tag_src = $tag_parent->getAttribute('href');
      }
      else {
        $tag_src = $base_url->resolve($tag->getAttribute('src'));
      }
      // Check it's an image 
      $parts = explode('.', $tag_src);
      $suffix = array_pop($parts);
      if (strtolower($suffix) != 'jpg') {
        print_log("$tag_src is a $suffix not a jpeg, skipping it");
        continue;
      }

      print_log("Fetching $tag_src"); 
      $safe_filename = preg_replace('/[^a-zA-Z0-9_\.]+/', '-', basename($tag_src));
      $save_as = $dirname . '/' . $safe_filename ;
      if (! is_file($save_as)) {
        $file_source = file_get_contents($tag_src);
        file_put_contents($save_as, $file_source);
        print_log("Saved to $save_as");
      }
      $contents[$save_as] = array(
        'filename' => $safe_filename,
        'url' => $tag_src,
      );
    }

    // Downloaded what we need, 
    // make the zip (current directory)
    $zip = new ZipArchive();
    $filename = $safe_name .".zip";

    if ($zip->open($filename, ZIPARCHIVE::CREATE)!==TRUE) {
      exit("cannot open <$filename>\n");
    }
    foreach ($contents as $filepath => $file) {
      $zip->addFile($filepath, $file['filename']);
      $manifest .= "{$file['filename']}, '{$file['url']}'\n";
      $zip->setCommentName($file['filename'], $file['url']);
    }
    $zipinfo = '{
"appID":"cbzget/001",
"lastModified":"'. date("Y-m-d h:i:s O") . '",
"ComicBookInfo/1.0":{
  "title":"'. $page_title . '",
  "series":"'. $base_url->host .'",
  "publisher":"'. $base_url .'",
  "url":"'. $base_url .'",
  "publicationYear":'. date('Y') .',
  "publicationMonth":'. date('n') .',
  "tags":["Downloads"]
}}';   

    $zip->addFromString("ZipInfo.txt", $zipinfo);
    $zip->addFromString("manifest.txt", $manifest);
    $zip->setArchiveComment($zipinfo);
    $zip->close();
    print_log("Created zip file $filename");
    print_log("numfiles: {$zip->numFiles}, size: " . format_bytes(filesize($filename)));
    
    // Clean up
    rrmdir($dirname);

  } catch (Exceptions $exc) {
    print_log("Processing $url failed");
  }

}


///////////////////////////////////////////////////////////////////////
function format_bytes($size) {
    $units = array(' B', ' KB', ' MB', ' GB', ' TB');
    for ($i = 0; $size >= 1024 && $i < 4; $i++) $size /= 1024;
    return round($size, 2).$units[$i];
}

function rrmdir($path){
  return is_file($path)?
    @unlink($path):
    array_map('rrmdir',glob($path.'/*'))==@rmdir($path) ;
}
