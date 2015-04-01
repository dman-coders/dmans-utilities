<html>
<body>
<h1>Create a site!</h1>
<?php
$localhost = isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : trim(`hostname`);
$sitename = $localhost;
$site_dir = dirname($_SERVER['SCRIPT_FILENAME']);
$url_parts = explode(".", $localhost);
array_pop($url_parts);
$dbname = implode('_', array_reverse($url_parts));

if (@$_GET['op'] == 'Create!') {
  if (empty($sitename)) {
    print("<h2>Need a valid subsite name</h2>");
  }
  else {
    if (!is_writable($site_dir)) {
      print("<h2>Need write permissions to $site_dir</h2>");
      print('<pre>');
      passthru('whoami');
      passthru('ls -la ' . $site_dir);
      print('</pre>');

    }
    else {
      // Prepare the drush command.

      exec(" cd $site_dir; ./make_site.sh $sitename $dbname", $output, $return);
      if (!$return) {
        print("<h2><a href='/install.php'>Created $sitename</a></h2>");
      }
      print('<pre>');
      print_r($output);
      print('</pre>');
      #header('Location: '. '/install.php', TRUE);
      #exit();
    }
  }
}
else {
  print("<h2>Press the button to create $sitename?</h2>");
  print("<p>DB ID: $dbname</p>");
  ?>
  <form>
    <input type="submit" name="op" value="Create!"/>
  </form>
<?php
}
?>
</body>
