#!/bin/bash

# Prompt the user to enter the new domain name
read -p "Enter the new domain name: " DOMAIN
read -p "Enter SELECTOR: " SELECTOR
read -p "Enter your email address (for Let's Encrypt): " EMAIL_ADDRESS

# Set the new domain name as the hostname
sudo hostname $DOMAIN
sudo sed -i "s/HOSTNAME=.*/HOSTNAME=$DOMAIN/g" /etc/sysconfig/network
sudo service network restart

# Display a message confirming the change
echo "Hostname has been set to: $DOMAIN"

# Install required packages
sudo yum install -y epel-release
sudo yum install -y httpd php56w php56w-opcache php56w-mysql php56w-mbstring php56w-mcrypt php56w-devel php56w-xml php56w-json php56w-fpm php56w-gd

# Start and enable the Apache HTTP server
sudo systemctl start httpd
sudo systemctl enable httpd

# Install Postfix
sudo yum install -y postfix
sudo systemctl start postfix
sudo systemctl enable postfix

# Install Dovecot (for IMAP and POP3)
sudo yum install -y dovecot

# Install OpenDKIM
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/latest.rpm
sudo yum install -y opendkim opendkim-tools

# Generate DKIM keys
sudo opendkim-genkey -b 2048 -h rsa-sha256 -r -s "$SELECTOR" -d "$DOMAIN"

# Configure OpenDKIM
sudo mkdir -p /etc/opendkim/keys/${DOMAIN}
sudo mv "${SELECTOR}.private" "/etc/opendkim/keys/${DOMAIN}/${SELECTOR}.private"
sudo chown opendkim:opendkim "/etc/opendkim/keys/${DOMAIN}/${SELECTOR}.private"
sudo chmod 400 "/etc/opendkim/keys/${DOMAIN}/${SELECTOR}.private"

# Add the DKIM configuration to OpenDKIM configuration file
echo "Domain *.$DOMAIN" | sudo tee -a /etc/opendkim.conf
echo "KeyFile /etc/opendkim/keys/${DOMAIN}/${SELECTOR}.private" | sudo tee -a /etc/opendkim.conf
echo "Selector ${SELECTOR}" | sudo tee -a /etc/opendkim.conf
echo "SOCKET=\"inet:8891@localhost\"" | sudo tee -a /etc/opendkim.conf

# Update Postfix configuration to use OpenDKIM
sudo postconf -e "smtpd_milters = inet:localhost:8891"
sudo postconf -e "non_smtpd_milters = inet:localhost:8891"
sudo postconf -e "milter_default_action = accept"

# Install Certbot (Let's Encrypt client)
sudo yum install -y certbot python2-certbot-apache

# Obtain and install SSL certificate for your domain
sudo certbot --apache -d $DOMAIN -m $EMAIL_ADDRESS --agree-tos --no-eff-email

# Create a welcome page
sudo mkdir -p /var/www/html
echo "<html><body><h1>Welcome to my website!</h1></body></html>" | sudo tee /var/www/html/index.html

# Restart services
sudo systemctl restart opendkim
sudo systemctl restart postfix
sudo systemctl restart httpd
sudo systemctl restart dovecot

echo "DKIM and SSL setup completed for $DOMAIN."

# Install additional packages
sudo yum install -y unzip
