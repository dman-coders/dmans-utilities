<html>
<body>
<h1>Create a site!</h1>
<?php
$localhost = isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : trim(`hostname`);
$leftname = preg_replace('/\..*$/', '', $localhost); # macs call machines 'name.local'
$rightname = preg_replace('/^.*\./', '', $localhost);
$sitename = $leftname;

if (isset($_GET['op']) && $_GET['op'] == 'Create!') {
  if (empty($sitename)) {
    print("<h2>Need a valid subsite name</h2>");
  } else if (! is_writable(dirname(__FILE__))) {
    print("<h2>Need write permissions to ".dirname(__FILE__)." </h2>");
    print('<pre>');
    passthru('whoami');
    passthru('ls -la '. dirname(__FILE__));
    print('</pre>');
    
  } 
  else {
    exec(" cd ". dirname(__FILE__) . "; ./make_site.sh $sitename", $output, $return);
    if(! $return) {
      print("<h2><a href='/install.php'>Created $sitename</a></h2>");
    }
    print('<pre>');
    print_r($output);
    print('</pre>');
    #header('Location: '. '/install.php', TRUE);
    #exit();
  }
} 
else {
  print("<h2>Press the button to create $sitename?</h2>");
  ?>
    <form>
    <input type="submit" name="op" value="Create!"/>
    </form>
  <?php
}
?>
</body>
</html>