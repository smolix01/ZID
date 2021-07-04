#!/bin/bash

sudo apt-get purge `dpkg -l | grep php| awk '{print $2}' |tr "\n" " "`

sudo add-apt-repository ppa:ondrej/php

sudo apt-get install software-properties-common

sudo apt-get update

sudo apt-get install php5.6

apt-get install apache2

service apache2 restart

apt-get install postfix


echo sender_canonical_maps = hash:/etc/postfix/canonical >> /etc/postfix/main.cf;
echo mime_header_checks = regexp:/etc/postfix/header_checks >> /etc/postfix/main.cf;
echo header_checks = regexp:/etc/postfix/header_checks >> /etc/postfix/main.cf;

echo "Postfix config ok Done !!!"

cat > /etc/postfix/header_checks << EOF
/^Received:.*\(Postfix/ IGNORE
EOF
echo "header Checks Done !!!"


cat > /etc/postfix/canonical << EOF
www-data  noreply
EOF
echo "Canonical Done !!!"

sudo postmap /etc/postfix/canonical


cd /var/www/html

sudo apt install unzip 



