#!/bin/bash

echo Making a site $1 with database $2
site_name=$1
db_port=33066
db_host=127.0.0.1
db_name=$2
db_superuser=root
db_superuser_pass=
db_user=drupaluser
db_pass=
install_profile=standard
account_name=phpuser
account_pass=web
# When running ADD, I have no shell PATH. So it's hard to find drush and php and mysql
export PATH=$PATH:/Applications/acquia-drupal/mysql/bin

drush=/Users/dan/.composer/vendor/bin/drush
export DRUSH_PHP=/Applications/acquia-drupal/php5_4/bin/php
drupal_root=/var/www/drupal7

rm -r $site_name

echo Running drush..
command="$drush -vd si -y --root=${drupal_root} --sites-subdir=${site_name} --account-name=${account_name} --account-pass=${account_pass}  --db-su=${db_superuser}  --db-url=mysql://${db_user}:${db_pass}@${db_host}:${db_port}/${db_name} ${install_profile}"

echo $command
rm log.log
( $command ) 2> log.log
cat log.log
echo Created a new site directory called ${site_name}, and linked to it for use with multisites. Login as ${account_name}:${account_pass}

