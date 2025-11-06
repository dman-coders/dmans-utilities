
Place these files in your local Drupal development instance.
eg, /var/www/drupal7/

  {siteroot}/sites/default/settings.php # This catches any new/undefined sitenames, and redirects to the utility php script.
  {siteroot}/sites/make_site.php        # This utility script starts the site build process
  {siteroot}/sites/make_site.php        # This is a commandline utility that actually builds a new Drupal site.

Set up a local wildcard DNS, such that all requests for 
  {anything}.drupal7.local
resolves to 127.0.0.1
  https://echo.co/blog/never-touch-your-local-etchosts-file-os-x-again


Set up your Vhosts such that all requests for {anything}.drupal7.local 
are served from your /var/www/drupal7/ 
  http://brunodbo.ca/blog/2013/04/26/setting-up-wildcard-apache-virtual-host-wildcard-dns


