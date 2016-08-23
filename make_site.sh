#!/bin/bash

export site=$1
export platform=drupal7.gizmo
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
echo "DROP DATABASE $db;" | mysql -u root -pswordfish ;
echo "CREATE DATABASE $db; GRANT ALL ON $db.* to phpuser" | mysql -u root -pswordfish ;

echo Created a new site directory called $site, and linked to it for use with multisites.

## Hints for HOSTNAME setup.
#
# To genuinely be able to just invent local websites on the fly, 
# You also need DNS to be co-operating.
# If this were a live hostname, you can set DNS to wildcard *.hostname and win.
# But for local devs, it's trickier.
# Option A: Hand-edit /etc/hosts all the time. Boo.
# Option B: run you own local, limited DNS server and wildcard your own computer name.
# To do B.
# On OSX Yosemite. (ndsmasq also works on other systems, but the install steps are different)
#
#   hostname='gizmo'; # Name this whatever suits you. My sites will be on *.gizmo
#   brew tap homebrew/services
#   brew install -v dnsmasq
#   echo "address=/.${hostname}/127.0.0.1" > $(brew --prefix)/etc/dnsmasq.conf
#   echo "listen-address=127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
#   echo 'port=35353' >> $(brew --prefix)/etc/dnsmasq.conf
#   brew services start dnsmasq
#   sudo mkdir -v /etc/resolver 
#   sudo bash -c "echo 'nameserver 127.0.0.1' > /etc/resolver/${hostname}"
#   sudo bash -c "echo 'port 35353' >> /etc/resolver/${hostname}"
# Now restart your network (eg disable wireless and re-anable it)
#   ping -c 3 mynewwildcard.${hostname}
# And you should see 127.0.0.1
#
# This quickstart is distilled from process I developed on Ubuntu with Vagrant, then OSX,
# Updated 2015 thanks to some OSX10 updates from ALAN IVEY
# https://echo.co/blog/os-x-1010-yosemite-local-development-environment-apache-php-and-mysql-homebrew
#
