<html>
<body>
<h1>Create a site!</h1>
<?php
/**
 * @file
 * Trigger a real site-build - including db creation - from the web.
 */

// Configurables:
$db_port = 33066;
$db_host = '127.0.0.1';
$db_superuser = 'root';
$db_superuser_pass = '';
$db_user = 'drupaluser';
$db_pass = '';
$install_profile = 'standard';
$account_name = 'phpuser';
$account_pass = 'web';
// When running ADD, I have no shell PATH.
// So it's hard to find drush and php and mysql.
$path = '/Applications/acquia-drupal/mysql/bin';
$drush = '/Users/dan/.composer/vendor/bin/drush';
$drush_php = '/Applications/acquia-drupal/php5_4/bin/php';

// Begin.
$localhost = isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : trim(`hostname`);
$site_name = $localhost;
$site_dir = dirname($_SERVER['SCRIPT_FILENAME']);
$url_parts = explode(".", $localhost);
array_pop($url_parts);
$db_name = implode('_', array_reverse($url_parts));
$db_url = "mysql://${db_user}:${db_pass}@${db_host}:${db_port}/${db_name}";

// Allow form submissions to override our settings.
// Basically ... register_globals.
foreach ($_GET as $param => $val) {
  if (isset($$param)) {
    $$param = $val;
  }
}

if (@$_GET['op'] == 'Create!') {
  if (empty($site_name)) {
    print "<h2>Need a valid subsite name</h2>";
  }
  else {
    if (!is_writable($site_dir)) {
      print "<h2>Need write permissions to $site_dir</h2>";
      print '<pre>';
      passthru('whoami');
      passthru('ls -la ' . $site_dir);
      print '</pre>';
    }
    else {
      // Prepare the drush command.
      $commands = array(
        "export PATH=\$PATH:$path",
        "export DRUSH_PHP=$drush_php",
        "cd $site_dir",
      );
      $drush_args = array(
        "--verbose",
        "--site-name=${site_name}",
        "--sites-subdir=${site_name}",
        "--account-name=${account_name}",
        "--account-pass=${account_pass}",
        "--db-su=${db_superuser}",
        "--db-su-pw=${db_superuser_pass}",
        "--db-url=${db_url}",
        "${install_profile}",
      );
      $drush_command = "$drush site-install -y " . implode(" ", $drush_args);
      $commands[] = "( $drush_command ) 2> log.log";
      $command = implode(";\n", $commands);
      print "Running <pre>$command</pre>";
      $last_line = exec($command, $output, $return_var);

      print '<pre>';
      print_r($output);
      print '</pre>';
      print "<h3><a href='/sites/log.log'>Install log</a></h3>";

      if (!$return_var) {
        print "<h2><a href='/user'>Created $site_name</a></h2>";
        print "<p>Log in to ${site_name} as ${account_name}:${account_pass}</p>";
      }
      else {
        print "return code from the command was $return_var. Could be something went wrong.";
      }
    }
  }
}
else {
  print "<h2>Press the button to create $site_name?</h2>";
  print "<p>DB ID: $db_name</p>";
  ?>
  <form>
    <select name="install_profile">
      <option>standard</option>
      <option>minimal</option>
    </select>
    <input type="submit" name="op" value="Create!"/>
  </form>
<?php
}
?>
</body>
