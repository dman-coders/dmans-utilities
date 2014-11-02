#!/usr/local/apache2/bin/php
<?php
# https://www.drupal.org/node/403742
############################################################
#         prefix or remove prefix from mysql tables        #
# Author : Mark Crandell                                   #
# User  : markDrupal                              #
# Date   : March 16, 2009                                  #
############################################################
#  This script runs with PHP.  It accepts 3 arguments,     #
#  1. the database name                                    #
#  2. the prefix                                           #
#  3. (optional) "remove" or "r" to reverse the operation  #
#     and remove the prefix.                               #
#  Example : ./prefix.php mydatabase prefix_
#  Example : ./prefix.php mydatabase prefix_ remove
#  The script adds a prefix to all tables in a specified   #
#  database.                                               #
#  NOTE : Be sure to set the password                      #
#  For safety, you uncomment "if(!in_array($db_name,..."   #
#  and specify the databases that you want to allow name   #
#  changing                                                #
############################################################
$db_password = 'PASSWORD GOES HERE';
$db_user = 'MYSQL USER NAME';
$db_host = "-h HOSTNAME"; // "-h localhost"; // Probally localhost
$db_port = "-P 3306"; // ""; //Use blank if not needed
$db_name = $_SERVER['argv'][1];
$prefix = $_SERVER['argv'][2];
$remove = $_SERVER['argv'][3];
if(strtolower($remove) == 'remove' || strtolower($remove) == 'r'){
  $remove = (bool) TRUE;
}
else {
  $remove = (bool) FALSE;
}
/*
if(!in_array($db_name, array('drupal_site', 'd7' ) )){
  echo "Not a valid mysql database name, try editing the script.\n";
  exit;
}
*/
$query = "mysql -u$db_user -B -p$db_password -s -r $db_host $port $db_name -e 'SHOW TABLES;'";
exec($query, $tables);
if($remove){
  foreach($tables as $key => $t){
    $rename[$key]['from'] = $t;
    $rename[$key]['to'] = preg_replace('/^'.$prefix.'/i','',$t);    
  }
}
else {
  foreach($tables as $key => $t){
    $rename[$key]['from'] = $t;
    $rename[$key]['to'] = $prefix . $t;
  }
}
foreach($rename as $r){
  $query = "mysql -u$db_user -B -p$db_password -s -r $db_host $port $db_name -e 'RENAME TABLE $db_name.{$r['from']} TO $db_name.{$r['to']};'";
  exec($query);
}
exit;
?>

