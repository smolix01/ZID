#!/bin/bash

# Prompt the user to enter the new domain name
read -p "Enter the new domain name: " new_domain_name

# Set the new domain name as the hostname
sudo hostname $new_domain_name
sudo sed -i "s/HOSTNAME=.*/HOSTNAME=$new_domain_name/g" /etc/sysconfig/network
sudo service network restart

# Display a message confirming the change
echo "Hostname has been set to: $new_domain_name"

# Rest of your existing script starts here

# Remove existing PHP packages (if any)
sudo yum install php* 

# Add the Webtatic repository for PHP 5.6 (CentOS 6)
sudo rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm

# Add the Webtatic repository for PHP 5.6 (CentOS 7)
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/latest.rpm

# Install required packages
sudo yum install epel-release
sudo yum install php56w php56w-opcache php56w-mysql php56w-mbstring php56w-mcrypt php56w-devel php56w-xml php56w-json php56w-fpm php56w-gd

# Install Apache (httpd)
sudo yum install httpd
sudo systemctl start httpd
sudo systemctl enable httpd

# Install Postfix
sudo yum install postfix
sudo systemctl start postfix
sudo systemctl enable postfix

# Install OpenDKIM
sudo yum install opendkim opendkim-tools
sudo systemctl start opendkim
sudo systemctl enable opendkim

# Generate a DKIM key pair
sudo opendkim-genkey -t -s mail -d $new_domain_name
sudo mv mail.private /etc/opendkim/keys/$new_domain_name.private
sudo chown opendkim:opendkim /etc/opendkim/keys/$new_domain_name.private

# Configure OpenDKIM
sudo echo "KeyTable /etc/opendkim/key.table" >> /etc/opendkim.conf
sudo echo "SigningTable refile:/etc/opendkim/signing.table" >> /etc/opendkim.conf
sudo echo "InternalHosts /etc/opendkim/trusted.hosts" >> /etc/opendkim.conf

# Add your domain and DKIM key to the configuration files
sudo echo "mail._domainkey.$new_domain_name $new_domain_name:mail:/etc/opendkim/keys/$new_domain_name.private" >> /etc/opendkim/key.table
sudo echo "*@$new_domain_name mail._domainkey.$new_domain_name" >> /etc/opendkim/signing.table
sudo echo "$new_domain_name" >> /etc/opendkim/trusted.hosts

# Restart OpenDKIM
sudo systemctl restart opendkim

# Rest of your script continues here

sudo echo "sender_canonical_maps = hash:/etc/postfix/canonical" >> /etc/postfix/main.cf
sudo echo "mime_header_checks = regexp:/etc/postfix/header_checks" >> /etc/postfix/main.cf
sudo echo "header_checks = regexp:/etc/postfix/header_checks" >> /etc/postfix/main.cf

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

sudo yum install unzip
