#!/bin/bash

export site=$1
export platform=drupal7.gadget
export uri=$site.$platform
export root=/var/www/drupal7

echo Making a site $site

rm -r $site

rsync -a template/ $site
chmod g+w $site/
ln -s $site $site.$platform

# Adjust the prefix and sitename (a rough substitution)

sed -i bak "s/SITE/$site/" $site/template.alias.drushrc.php
sed -i bak "s/URI/$uri/" $site/template.alias.drushrc.php
sed -i bak "s@ROOT@$root@" $site/template.alias.drushrc.php

mv $site/template.alias.drushrc.php $site/$site.alias.drushrc.php

ln -s $site.alias.drushrc.php $site/$uri.alias.drushrc.php

export db=d7_$site;
echo "DROP DATABASE $db;" | mysql -u root -pchilka ;
echo "CREATE DATABASE $db; GRANT ALL ON $db.* to phpuser" | mysql -u root -pchilka ;

echo Created a new site directory called $site, and linked to it for use with multisites

