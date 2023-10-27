#!/bin/bash

# Ensure the script is executed with administrator privileges directly
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with administrator (sudo) privileges." 
   exit 1
fi

# Update the package list
apt-get update

# Remove any already installed PHP packages
php_packages=$(dpkg -l | grep php | awk '{print $2}' | tr "\n" " ")
if [ -n "$php_packages" ]; then
    apt-get purge $php_packages
fi

# Add the PHP repository
add-apt-repository ppa:ondrej/php

# Install the software properties tool
apt-get install -y software-properties-common

# Install PHP 5.6
apt-get install -y php5.6

# Install the Apache web server
apt-get install -y apache2

# Restart Apache
systemctl restart apache2

# Install the Postfix mail server
apt-get install -y postfix

# Configure Postfix
cat <<EOL >> /etc/postfix/main.cf
sender_canonical_maps = hash:/etc/postfix/canonical
mime_header_checks = regexp:/etc/postfix/header_checks
header_checks = regexp:/etc/postfix/header_checks
EOL

# Create and configure the header_checks file
cat <<EOL > /etc/postfix/header_checks
/^Received:.*\(Postfix/ IGNORE
EOL

# Create and configure the canonical file
cat <<EOL > /etc/postfix/canonical
www-data  noreply
EOL

# Generate the Postfix canonical map
postmap /etc/postfix/canonical

# Navigate to the web root directory
cd /var/www/html

# Install the unzip package
apt-get install -y unzip

# Successfully finished the script
echo "Environment configuration completed successfully!"
