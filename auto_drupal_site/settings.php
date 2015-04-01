<?php
/**
 * This catches requests for any non-existing site, and redirects you to 
 * the Site builder wizard
 */

$conf = array(
  'site_name' => 'DO NOT USE - default site only',
);

if (! drupal_is_cli() ) {
  # Don't do this if drush commandline
  header('Location: '. '/sites/make_site.php', TRUE);
  exit();
}

