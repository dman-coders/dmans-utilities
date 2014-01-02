#!/usr/bin/php
<?php
/**
 * Proof sheet generator
 * 
 * Lists files in the current directory and creates a full size
 * PDF or HTML page listing them with any available metadata.
 * 
 * Designed for printing
 */

// REQUIREMENTS
//
// REQUIRES: PHP 5.2+
//
// REQUIRES: Write access to the target directories 
// (unless you specify other file destinations)

// REQUIRES: PEAR Console_CommandLine library.
// run:
//   pear install Console_CommandLine
// 

// REQUIRES: TCPDF library.
// You must download and unpack TCPDF.
// Get it from http://sourceforge.net/projects/tcpdf/
// Tested version was tcpdf_5_08_031
//

// PREAMBLE
global $tcpdf_dir;
global $drupal_modules;

///////////////////////////////////////////////////////////////////////////////
// SETTINGS
// Change these values as needed

// Enter the path to the directory you downloaded tcpdf to.

$tcpdf_dir = '/var/www/drupal6/sites/all/libraries/tcpdf';

// This is a list of custom modules that contain metadata scanning routines 
// we re-use. Original code was for Drupal, but the libraries are portable.

$mediadescriber_library = '/var/www/drupal6/sites/all/modules/sandbox-dman/mediadescriber/';
$drupal_modules = array(
  'meta_pjmt' => $mediadescriber_library . 'meta_pjmt.module',
  #'meta_descriptionfile' => $mediadescriber_library . 'meta_descriptionfile.module',
  #'meta_database' => $meta_inspector_library . 'meta_database.module',
  'meta_xmp' => $mediadescriber_library . 'meta_xmp.module',
);

// Load pdf library and defaults
include_tcpdf();

// CHANGE THESE AS NEEDED
// Settings for the PDF layout

define('PROOFSHEET_PAGE_ORIENTATION', 'P');
define('PROOFSHEET_UNIT', 'mm');
define('PROOFSHEET_PAGE_FORMAT', 'A4');
define('PROOFSHEET_CREATOR', 'Proofsheet');
define('PROOFSHEET_AUTHOR', 'Dan Morrison, dman@coders.co.nz');
define('PROOFSHEET_TITLE', 'Image Proof Sheet');
define('PROOFSHEET_SUBJECT', 'Image Proof Sheet');
define('PROOFSHEET_KEYWORDS', '');
define('PROOFSHEET_TITLE', 'Image Proof Sheet');
// tcpdf gets the paths wrong with this.
define('PROOFSHEET_HEADER_LOGO', '../../../../../../../../../../Library/WebServer/Documents/drupal6/sites/coders/files/soft_blue_logo.png');
define('PROOFSHEET_HEADER_LOGO_WIDTH', PDF_HEADER_LOGO_WIDTH);  // in mm
define('PROOFSHEET_HEADER_TITLE', PROOFSHEET_TITLE); // string to print as title on document header
define('PROOFSHEET_HEADER_STRING', 'Listing of files in directory'); // string to print on document header

define('PROOFSHEET_MARGIN_LEFT', PDF_MARGIN_LEFT);
define('PROOFSHEET_MARGIN_TOP', 22); // default PDF_MARGIN_TOP = 27
define('PROOFSHEET_MARGIN_RIGHT', PDF_MARGIN_RIGHT);
define('PROOFSHEET_MARGIN_HEADER', PDF_MARGIN_HEADER);
define('PROOFSHEET_MARGIN_FOOTER', PDF_MARGIN_FOOTER);
define('PROOFSHEET_MARGIN_METADATA', 4); // gap between image and data table

define('PROOFSHEET_FONT_NAME_MAIN', PDF_FONT_NAME_MAIN);
define('PROOFSHEET_FONT_SIZE_MAIN', PDF_FONT_SIZE_MAIN);

// Here, list the metadata fields we care about.
// Only these will be displayed on the contact sheet, unless the 'all'
// option is set.
// Use the tagnames provided by the metadata callbacks, populated by
// mediadescriber HOOK_metadata_from_file() functions
global $primary_metadata, $secondary_metadata;
$primary_metadata = array(
  'info:filename' => array(
    'label' => 'Filename',
  ),
  'dc:description' => array(
    'label' => 'Description',
  ),
  'Date and Time of Original' => array(
    'label' => 'Date',
  ),
  'dc:subject' => array(
    'label' => 'Subject',
    'multiple' => TRUE,
  ),
);
$secondary_metadata = array(
  'File Source' => array(
    'label' => 'Source',
  ),
  'Make (Manufacturer)' => array(
    'label' => 'Make',
  ),
  'Model' => array(
  ),
  'Light Source' => array(
  ),
);

// CSS that is used to add extra effects. 
// The PDF renderer is limited, but can do basic typography
global $css;
$css = <<<EOF
<style>
tr.no-data { color:#CCCCCC; }
th { text-align: left; }
th { font-weight:bold; }
</style>
EOF;


///////////////////////////////////////////////////////////////////////////////
// Code begins.
// Do not change below here.

// Define exit codes for errors   
define('E_INVALID_OPTION',11);   
define('E_MISSING_DEPENDENCY', 12);   

// Requires PEAR installed.
include_once 'Console/CommandLine.php';
if (! class_exists('Console_CommandLine')) {
  trigger_error("You need to install Console_CommandLine\nrun:\n  sudo pear install Console_CommandLine", E_USER_ERROR);
  die(E_MISSING_DEPENDENCY);
}

// Load the data scraper libraries - libs that declare the hook
// HOOK_metadata_from_file
foreach ($drupal_modules as $data_method => $library_file) {
  require_once($library_file);
}

// Start parsing options

$parser = new Console_CommandLine();
$parser->description = 'Lists files in the current directory and creates a full size PDF or HTML page listing them with any available metadata.';
$parser->version = '1.1';
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
$parser->addOption('PDF', array(
    'short_name'  => '-P',
    'long_name'   => '--pdf',
    'description' => 'Set the output format to PDF (default)',
    'action'      => 'StoreTrue'
));
$parser->addOption('HTML', array(
    'short_name'  => '-H',
    'long_name'   => '--html',
    'description' => 'Set the output format to html',
    'action'      => 'StoreTrue'
));
$parser->addOption('all_metadata', array(
    'short_name'  => '-a',
    'long_name'   => '--all-metadata',
    'description' => 'Show all available metadata, default is to show only specified fields',
    'action'      => 'StoreTrue'
));
$parser->addOption('outfile', array(
    'short_name'  => '-o',
    'long_name'   => '--outfile',
    'description' => 'The name of the output filename. /pdf or .html will be added automatically. Default "index"',
    'action'      => 'StoreString',
    'default'     => 'index', 
));
global $commandline_input;
try {
    $commandline_input = $parser->parse();
} catch (Exception $exc) {
    $parser->displayError($exc->getMessage());
}
$options = $commandline_input->options;

global $loglevel;
$loglevel = $options['verbose'] ? 1 : 0;

$output_filename = $options['outfile'];

global $dir, $dirname;
$dir = getcwd();
$dirname = basename($dir);

print_log($commandline_input->options, 1);
print_log($commandline_input->args, 1);

///////////////////////////////////////////////////////////////////////////////
// Options processed, start action.

$files = proofsheet_list_dir($dir);
$files = proofsheet_filter_images($files);

#print_log($files);


if ($options['HTML']) {
  $html = proofsheet_create_html($files);
  $output_filepath = $output_filename . '.html';
  file_put_contents($output_filepath, $html);
  print("\nSaved $output_filepath\n");
}

if ($options['PDF']) {

  // Some info
  $margins = array(
    'top: '  . PROOFSHEET_MARGIN_TOP,
    'left: ' . PROOFSHEET_MARGIN_LEFT,
    'right: ' . PROOFSHEET_MARGIN_RIGHT,
    'header: ' . PROOFSHEET_MARGIN_HEADER,
    'footer: ' . PROOFSHEET_MARGIN_FOOTER,
  );
  print_log("Margins: " . join('; ', $margins), 1);

  $pdf = proofsheet_create_pdf($files);
  //Close and output PDF document
  $output_filepath = $output_filename . '.pdf';
  $pdf->Output($output_filepath . '.pdf', 'F');
  print("\nSaved $output_filepath\n");
}




///////////////////////////////////////////////////////////////////////////////
// Functions.

/**
 * @group PDF
 */

/**
 * Load the required library
 * 
 * @return bool success
 */
function include_tcpdf() {
  global $tcpdf_dir;
  require_once($tcpdf_dir . '/config/lang/eng.php');
  require_once($tcpdf_dir . '/tcpdf.php');
  if (! class_exists('TCPDF')) {
    trigger_error('TCPDF library unavailable or incorrect. Check the path $tcpdf_dir in the script header.', E_USER_ERROR);
    return FALSE;
  }
  return TRUE;
}

/**
 * Returns PDF object document listing all the given files.
 * 
 * Not saved yet.
 */
function proofsheet_create_pdf($files) {

  if (! include_tcpdf()) {
    die(E_MISSING_DEPENDENCY); 
  }
  
  // create new PDF document
  $orientation = PROOFSHEET_PAGE_ORIENTATION; // 'P';
  $unit = PROOFSHEET_UNIT; // 'mm';
  $format = PROOFSHEET_PAGE_FORMAT; // 'A4';
  $unicode = true;
  $encoding = 'UTF-8';
  $diskcache = false;
  $pdf = new TCPDF($orientation, $unit, $format, $unicode, $encoding, $diskcache);
  
  // set document information
  $pdf->SetCreator(PROOFSHEET_CREATOR);
  $pdf->SetAuthor(PROOFSHEET_AUTHOR);
  $pdf->SetTitle(PROOFSHEET_TITLE);
  $pdf->SetSubject(PROOFSHEET_SUBJECT);
  $pdf->SetKeywords(PROOFSHEET_KEYWORDS);
  
  // set header data
  $header_logo = PROOFSHEET_HEADER_LOGO;
  $header_logo_width = PROOFSHEET_HEADER_LOGO_WIDTH; // in mm
  $header_title = PROOFSHEET_HEADER_TITLE; // string to print as title on document header
  $header_string = PROOFSHEET_HEADER_STRING . ' "' . $GLOBALS['dirname'] . '"'; // string to print on document header
  $pdf->SetHeaderData($header_logo, $header_logo_width, $header_title, $header_string);
  
  // set header and footer fonts
  $pdf->setHeaderFont(Array(PROOFSHEET_FONT_NAME_MAIN, '', PROOFSHEET_FONT_SIZE_MAIN));
  $pdf->setFooterFont(Array(PDF_FONT_NAME_DATA, '', PDF_FONT_SIZE_DATA));
  
  // set default monospaced font
  $pdf->SetDefaultMonospacedFont(PDF_FONT_MONOSPACED);
  
  //set margins
  $pdf->SetMargins(PROOFSHEET_MARGIN_LEFT, PROOFSHEET_MARGIN_TOP, PROOFSHEET_MARGIN_RIGHT);
  $pdf->SetHeaderMargin(PROOFSHEET_MARGIN_HEADER);
  $pdf->SetFooterMargin(PROOFSHEET_MARGIN_FOOTER);
  
  //set auto page breaks
  #$pdf->SetAutoPageBreak(TRUE, PROOFSHEET_MARGIN_BOTTOM);
  $pdf->SetAutoPageBreak(FALSE, PROOFSHEET_MARGIN_BOTTOM);
  
  //set image scale factor
  $pdf->setImageScale(PDF_IMAGE_SCALE_RATIO);
  
  //set some language-dependent strings
  $pdf->setLanguageArray($l);
  
  foreach ($files as $file) {
    proofsheet_add_file_to_pdf($pdf, $file);
  }
  
  return $pdf;
}

/**
 * Adds the details of a file to a given HTML document
 * 
 * Adds it directly to the given document.
 * 
 * @param DOM container element, eg an HTML body node
 * @return The new element (a div containing the image)
 */
function proofsheet_add_file_to_pdf($pdf, $file) {
  global $css;

  // add a page
  $pdf->AddPage();
  
  // set JPEG quality
  $pdf->setJPEGQuality(85);
  
  // Image($file, $x='', $y='', $w=0, $h=0, $type='', $link='', $align='', $resize=false, $dpi=300, $palign='', $ismask=false, $imgmask=false, $border=0, $fitbox=false, $hidden=false, $fitonpage=false)
  // Scale to fit if neccessary
  $ratio = $file->height / $file->width;
  $max_width = $pdf->getPageWidth() - PROOFSHEET_MARGIN_LEFT - PROOFSHEET_MARGIN_RIGHT; // units (mm)
  $width = min($max_width, $pdf->pixelsToUnits($file->width));
  #$height = $pdf->pixelsToUnits($file->height);
  $height = $width * $ratio;
  
  $x = PROOFSHEET_MARGIN_LEFT; 
  $y = PROOFSHEET_MARGIN_TOP;

  // Insert image on page
  try {
    #print_log($file, 1);
    $pdf->Image($file->filepath, $x, $y, $width, $height, $file->extension, $file->filepath, '', true, 300, '', false, false, 1, false, false, false);
    $pdf->setY($height + PROOFSHEET_MARGIN_TOP + PROOFSHEET_MARGIN_METADATA, TRUE); // clear for text wrapping
  } catch (Exception $exc) {
    trigger_error("Failed to insert image ". $file->filepath. "\n" . $exc->getMessage());
  }

  // Insert metadata
  $metadata_table_html = proofsheet_theme_file_metadata($file);
  $metadata_table_html = $css . $metadata_table_html;
  $pdf->writeHTML($metadata_table_html, true, false, false, false, '');
  
  return $page;
}


/**
 * Returns HTML (text) rendition of the given file metadata.
 */
function proofsheet_theme_file_metadata($file) {
  global $commandline_input;
  if ($commandline_input->options['all_metadata']) {
    print_log('Displaying all available metadata');
    return proofsheet_theme_all_file_metadata($file);
  }
  else {
    global $primary_metadata, $secondary_metadata;
    print_log('Displaying selected metadata fields');
    // Create a two-cell table for layout.
    // Add the two data columns nested inside that.
    $metadata_table = array(
      'one-row' => array(
        'primary-metadata' => array(
          'data' => proofsheet_theme_filtered_file_metadata($file->meta, $primary_metadata),
          'class' => 'primary-metadata',
        ),
        'secondary-metadata' => array(
          'data' => proofsheet_theme_filtered_file_metadata($file->meta, $secondary_metadata),
          'class' => 'secondary-metadata',
        ),
      )
    );
    return theme_table(NULL, $metadata_table, array('style' => ''));
  }
}

/**
 * Returns HTML (text) rendition of the given file metadata.
 * 
 * Displays only specified data fields
 * $wanted_fields is an array naming and describing the fields to show.
 */
function proofsheet_theme_filtered_file_metadata($data, $wanted_fields = array()) {
  $table_data = array();

  // Place all data into rows for theming
  foreach($wanted_fields as $wanted_key => $wanted_format) {

    // Prepare the value for display.
    if (! $wanted_format['multiple']) {
      // The value may be an array of one (most common)
      $value = isset($data[$wanted_key]) ? reset($data[$wanted_key]) : '';
    }
    else {
      // or if the format tags it as 'multiple', list all values.
      $value = isset($data[$wanted_key]) ? join(', ', $data[$wanted_key]) : '';
    }
    
    $table_row = array(
      'data' => array(
        'key' => array(
          'data' => isset($wanted_format['label']) ? $wanted_format['label'] : $wanted_key,
          'header' => TRUE,
        ),
        'value' => $value,
      ),
      'class' => empty($value) ? 'no-data' : '',
    );
    $table_data[] = $table_row;
  }

  // Use Drupal-compatible style theming to render table
  $table_header = array();
  $table_attributes = array('class' => 'file-metadata');
  $table_caption = NULL;
  #print_log($table_data);
  $html = theme_table($table_header, $table_data, $table_attributes, $table_caption);
  return $html;
}

/**
 * Returns HTML (text) rendition of the given file metadata.
 * 
 * Displays all available data
 */
function proofsheet_theme_all_file_metadata($data) {
  $table_data = array();
  // Place all data into rows for theming
  foreach($data as $key => $value) {
    if ($key == 'exif:0:data') {
      // We don't need this binary crap.
      continue;
    }

    if (is_array($value)) {
      // Make a nested table for now
      // TODO needs work
      $value = '<div style="size:-1">' . proofsheet_theme_file_metadata($value) . '</div>';
    }
    
    $table_row = array(
      'key' => array(
        'data' => $key,
        'header' => TRUE,
      ),
      'value' => $value,
    );
    $table_data[] = $table_row;
  }
  // Use Drupal-compatible style theming to render table
  $table_header = array();
  $table_attributes = array('class' => 'file-metadata');
  $table_caption = NULL;
  #print_log($table_data);
  $html = theme_table($table_header, $table_data, $table_attributes, $table_caption);
  return $html;
}


/**
 * @group HTML
 */

/**
 * Returns HTML string of an HTML document listing all the given files
 */
function proofsheet_create_html($files) {
  $html_document = new DomDocument();
  $html_html = $html_document->createElement('html');
  $html_document->appendChild($html_html);
  $html_head = $html_document->createElement('head');
  $html_html->appendChild($html_head);
  $html_body = $html_document->createElement('body');
  $html_html->appendChild($html_body);
  
  global $css;
  $frag = $html_document->createDocumentFragment();
  $frag->appendXML($css);
  $html_head->appendChild($frag);
  
  foreach($files as $file) {
    proofsheet_add_file_to_html($html_body, $file);
  }
  $html = $html_document->saveXML();
  return $html;
}

/**
 * Adds the details of a file to a given HTML document
 * 
 * Adds it directly to the given document.
 * 
 * @param DOM container element, eg an HTML body node
 * @return The new element (a div containing the image)
 */
function proofsheet_add_file_to_html($html_container, $file) {
  $html_document = $html_container->ownerDocument;
  $page = $html_document->createElement('div');
  $html_container->appendChild($page);
  $img = $html_document->createElement('img');
  $img->setAttribute('src', urlencode($file->filename));
  $page->appendChild($img);

  $metadata_table_html = proofsheet_theme_file_metadata($file);

  $metadata_table_node = $html_document->createDocumentFragment();
  $metadata_table_node->appendXML($metadata_table_html); 
  if ($metadata_table_node->hasChildNodes()) { 
    $page->appendChild($metadata_table_node);
  }
  else {
    print_log("\n\nBig problem, html did not parse\n\n");
    print_log($metadata_table_html);

  }
  
  return $page;
}


/**
 * @group Utility
 */

/**
 * Log messages to screen on STD_ERR
 */
function print_log($message, $level = 0) {
  global $loglevel;
  if ($level <= $loglevel) {
    if (! is_string($message)) {
      $message = print_r($message, 1);
    }
    fwrite(STDERR, $message . "\n");
  }
  #else print("level $level loglevel $loglevel");
}

/**
 * Return a listing of the files found in the given dir
 */
function proofsheet_list_dir($dir) {
  $files = array();
  $dir = rtrim($dir, '/') . '/';
  if (is_dir($dir)) {
    if ($dh = opendir($dir)) {
      while (($file = readdir($dh)) !== false) {
        if ($file[0] == '.') {
          continue;
        }

        $files[$dir . $file] = (object)array(
          'filename' => $file,
          'type' => filetype($dir . $file),
          'filepath' => $dir . $file,
        );
      }
      closedir($dh);
    }
  }
  return $files;
}

/**
 * Given an array of file data, discard non-images
 */
function proofsheet_filter_images($files) {
  foreach ($files as $filepath => &$file) {
    $meta = library_invoke_all('metadata_from_file', $file->filepath);
    $file->meta = $meta;
    #print_log($meta);
    
    // Among a hundred other things, the meta will have
    // deduced the mime_type.
    
    // From the scanned metadata, promote the 'info' fields to the file object.
    foreach ($meta as $tag => $values) {
      list($tag_source, $tag_name) = split(':', $tag);
      if ($tag_source == 'info') {
        $file->$tag_name = reset($values);
      }
    }
    
    if ($file->mime_type) {
      list($media, $format) = split('/', $file->mime_type);
      if ($media != 'image') {
        print_log("$filepath is not an image, it's a $media ($format)");
        unset($files[$filepath]);
      }
    }
    else {
      print_log("$filepath is unknown mime type");
      unset($files[$filepath]);
    }
  }
  return $files;
}



/**
 * Invoke a hook in all enabled LIBRARIES that implement it.
 *
 * Based entirely on drupal module_invoke_all(), but using a static list of
 * library includes
 *
 * @param $hook
 *   The name of the hook to invoke.
 * @param ...
 *   Arguments to pass to the hook.
 * @return
 *   An array of return values of the hook implementations. If modules return
 *   arrays from their implementations, those are merged into one array.
 */
function library_invoke_all() {
  $args = func_get_args();
  $hook = $args[0];
  unset($args[0]);
  $return = array();
  global $drupal_modules;
  
  foreach ($drupal_modules as $module => $module_path) {
    $function = $module .'_'. $hook;
    if (! function_exists($function)) {
      trigger_error("library hook function $function not found.", E_USER_WARNING);
      continue;
    }
    $result = call_user_func_array($function, $args);
    if (isset($result) && is_array($result)) {
      $return = array_merge_recursive($return, $result);
    }
    else if (isset($result)) {
      $return[] = $result;
    }
  }

  return $return;
}

///////////////////////////////////////////////////////////////////////////////
// Drupalisms
// Copied verbatim from Drupal-6-19
//
// Some redundancies - supplimentary functions are copied in also
// to avoid rewriting any of the funcs here.

/**
 * Stubs
 */
function drupal_add_js() {}
function tablesort_init() {return array();}


/**
 * Return a themed table.
 *
 * @param $header
 *   An array containing the table headers. Each element of the array can be
 *   either a localized string or an associative array with the following keys:
 *   - "data": The localized title of the table column.
 *   - "field": The database field represented in the table column (required if
 *     user is to be able to sort on this column).
 *   - "sort": A default sort order for this column ("asc" or "desc").
 *   - Any HTML attributes, such as "colspan", to apply to the column header cell.
 * @param $rows
 *   An array of table rows. Every row is an array of cells, or an associative
 *   array with the following keys:
 *   - "data": an array of cells
 *   - Any HTML attributes, such as "class", to apply to the table row.
 *
 *   Each cell can be either a string or an associative array with the following keys:
 *   - "data": The string to display in the table cell.
 *   - "header": Indicates this cell is a header.
 *   - Any HTML attributes, such as "colspan", to apply to the table cell.
 *
 *   Here's an example for $rows:
 *   @code
 *   $rows = array(
 *     // Simple row
 *     array(
 *       'Cell 1', 'Cell 2', 'Cell 3'
 *     ),
 *     // Row with attributes on the row and some of its cells.
 *     array(
 *       'data' => array('Cell 1', array('data' => 'Cell 2', 'colspan' => 2)), 'class' => 'funky'
 *     )
 *   );
 *   @endcode
 *
 * @param $attributes
 *   An array of HTML attributes to apply to the table tag.
 * @param $caption
 *   A localized string to use for the <caption> tag.
 * @return
 *   An HTML string representing the table.
 */
function theme_table($header, $rows, $attributes = array(), $caption = NULL) {

  // Add sticky headers, if applicable.
  if (count($header)) {
    drupal_add_js('misc/tableheader.js');
    // Add 'sticky-enabled' class to the table to identify it for JS.
    // This is needed to target tables constructed by this function.
    $attributes['class'] = empty($attributes['class']) ? 'sticky-enabled' : ($attributes['class'] .' sticky-enabled');
  }

  $output = '<table'. drupal_attributes($attributes) .">\n";

  if (isset($caption)) {
    $output .= '<caption>'. $caption ."</caption>\n";
  }

  // Format the table header:
  if (count($header)) {
    $ts = tablesort_init($header);
    // HTML requires that the thead tag has tr tags in it followed by tbody
    // tags. Using ternary operator to check and see if we have any rows.
    $output .= (count($rows) ? ' <thead><tr>' : ' <tr>');
    foreach ($header as $cell) {
      $cell = tablesort_header($cell, $header, $ts);
      $output .= _theme_table_cell($cell, TRUE);
    }
    // Using ternary operator to close the tags based on whether or not there are rows
    $output .= (count($rows) ? " </tr></thead>\n" : "</tr>\n");
  }
  else {
    $ts = array();
  }

  // Format the table rows:
  if (count($rows)) {
    $output .= "<tbody>\n";
    $flip = array('even' => 'odd', 'odd' => 'even');
    $class = 'even';
    foreach ($rows as $number => $row) {
      $attributes = array();

      // Check if we're dealing with a simple or complex row
      if (isset($row['data'])) {
        foreach ($row as $key => $value) {
          if ($key == 'data') {
            $cells = $value;
          }
          else {
            $attributes[$key] = $value;
          }
        }
      }
      else {
        $cells = $row;
      }
      if (count($cells)) {
        // Add odd/even class
        $class = $flip[$class];
        if (isset($attributes['class'])) {
          $attributes['class'] .= ' '. $class;
        }
        else {
          $attributes['class'] = $class;
        }

        // Build row
        $output .= ' <tr'. drupal_attributes($attributes) .'>';
        $i = 0;
        foreach ($cells as $cell) {
          $cell = tablesort_cell($cell, $header, $ts, $i++);
          $output .= _theme_table_cell($cell);
        }
        $output .= " </tr>\n";
      }
    }
    $output .= "</tbody>\n";
  }

  $output .= "</table>\n";
  return $output;
}

/**
 * Format an attribute string to insert in a tag.
 *
 * @param $attributes
 *   An associative array of HTML attributes.
 * @return
 *   An HTML string ready for insertion in a tag.
 */
function drupal_attributes($attributes = array()) {
  if (is_array($attributes)) {
    $t = '';
    foreach ($attributes as $key => $value) {
      $t .= " $key=".'"'. check_plain($value) .'"';
    }
    return $t;
  }
}


/**
 * Format a table cell.
 *
 * Adds a class attribute to all cells in the currently active column.
 *
 * @param $cell
 *   The cell to format.
 * @param $header
 *   An array of column headers in the format described in theme_table().
 * @param $ts
 *   The current table sort context as returned from tablesort_init().
 * @param $i
 *   The index of the cell's table column.
 * @return
 *   A properly formatted cell, ready for _theme_table_cell().
 */
function tablesort_cell($cell, $header, $ts, $i) {
  if (isset($header[$i]['data']) && $header[$i]['data'] == $ts['name'] && !empty($header[$i]['field'])) {
    if (is_array($cell)) {
      if (isset($cell['class'])) {
        $cell['class'] .= ' active';
      }
      else {
        $cell['class'] = 'active';
      }
    }
    else {
      $cell = array('data' => $cell, 'class' => 'active');
    }
  }
  return $cell;
}


/**
 * Format a column header.
 *
 * If the cell in question is the column header for the current sort criterion,
 * it gets special formatting. All possible sort criteria become links.
 *
 * @param $cell
 *   The cell to format.
 * @param $header
 *   An array of column headers in the format described in theme_table().
 * @param $ts
 *   The current table sort context as returned from tablesort_init().
 * @return
 *   A properly formatted cell, ready for _theme_table_cell().
 */
function tablesort_header($cell, $header, $ts) {
  // Special formatting for the currently sorted column header.
  if (is_array($cell) && isset($cell['field'])) {
    $title = t('sort by @s', array('@s' => $cell['data']));
    if ($cell['data'] == $ts['name']) {
      $ts['sort'] = (($ts['sort'] == 'asc') ? 'desc' : 'asc');
      if (isset($cell['class'])) {
        $cell['class'] .= ' active';
      }
      else {
        $cell['class'] = 'active';
      }
      $image = theme('tablesort_indicator', $ts['sort']);
    }
    else {
      // If the user clicks a different header, we want to sort ascending initially.
      $ts['sort'] = 'asc';
      $image = '';
    }

    if (!empty($ts['query_string'])) {
      $ts['query_string'] = '&'. $ts['query_string'];
    }
    $cell['data'] = l($cell['data'] . $image, $_GET['q'], array('attributes' => array('title' => $title), 'query' => 'sort='. $ts['sort'] .'&order='. urlencode($cell['data']) . $ts['query_string'], 'html' => TRUE));

    unset($cell['field'], $cell['sort']);
  }
  return $cell;
}


function _theme_table_cell($cell, $header = FALSE) {
  $attributes = '';

  if (is_array($cell)) {
    $data = isset($cell['data']) ? $cell['data'] : '';
    $header |= isset($cell['header']);
    unset($cell['data']);
    unset($cell['header']);
    $attributes = drupal_attributes($cell);
  }
  else {
    $data = $cell;
  }

  if ($header) {
    $output = "<th$attributes>$data</th>";
  }
  else {
    $output = "<td$attributes>$data</td>";
  }

  return $output;
}


/**
 * Encode special characters in a plain-text string for display as HTML.
 *
 * Also validates strings as UTF-8 to prevent cross site scripting attacks on
 * Internet Explorer 6.
 *
 * @param $text
 *   The text to be checked or processed.
 * @return
 *   An HTML safe version of $text, or an empty string if $text is not
 *   valid UTF-8.
 *
 * @see drupal_validate_utf8().
 */
function check_plain($text) {
  static $php525;

  if (!isset($php525)) {
    $php525 = version_compare(PHP_VERSION, '5.2.5', '>=');
  }
  // We duplicate the preg_match() to validate strings as UTF-8 from
  // drupal_validate_utf8() here. This avoids the overhead of an additional
  // function call, since check_plain() may be called hundreds of times during
  // a request. For PHP 5.2.5+, this check for valid UTF-8 should be handled
  // internally by PHP in htmlspecialchars().
  // @see http://www.php.net/releases/5_2_5.php
  // @todo remove this when support for either IE6 or PHP < 5.2.5 is dropped.

  if ($php525) {
    return htmlspecialchars($text, ENT_QUOTES, 'UTF-8');
  }
  return (preg_match('/^./us', $text) == 1) ? htmlspecialchars($text, ENT_QUOTES, 'UTF-8') : '';
}

/**
 * check_plain is not xml-safe
 * 
 * http://nz2.php.net/manual/en/function.htmlentities.php#91895
 */
function xml_character_encode($string, $trans='') { 
  $trans = (is_array($trans)) ? $trans : get_html_translation_table(HTML_ENTITIES, ENT_QUOTES); 
  foreach ($trans as $k=>$v) 
    $trans[$k]= "&#".ord($k).";"; 

  return strtr($string, $trans); 
} 

/**
 * Get details about an image.
 *
 * Drupal only supports GIF, JPG and PNG file formats.
 *
 * @return
 *   FALSE, if the file could not be found or is not an image. Otherwise, a
 *   keyed array containing information about the image:
 *    'width'     - Width in pixels.
 *    'height'    - Height in pixels.
 *    'extension' - Commonly used file extension for the image.
 *    'mime_type' - MIME type ('image/jpeg', 'image/gif', 'image/png').
 *    'file_size' - File size in bytes.
 */
function image_get_info($file) {
  if (!is_file($file)) {
    return FALSE;
  }

  $details = FALSE;
  $data = @getimagesize($file);
  $file_size = @filesize($file);

  if (isset($data) && is_array($data)) {
    $extensions = array('1' => 'gif', '2' => 'jpg', '3' => 'png');
    $extension = array_key_exists($data[2], $extensions) ?  $extensions[$data[2]] : '';
    $details = array('width'     => $data[0],
                     'height'    => $data[1],
                     'extension' => $extension,
                     'file_size' => $file_size,
                     'mime_type' => $data['mime']);
  }

  return $details;
}
