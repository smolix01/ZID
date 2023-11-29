#!/bin/bash

# Set your domain
DOMAIN="team-metamask.us"

# Install Certbot
sudo yum install -y certbot python2-certbot-apache

# Request a certificate
sudo certbot certonly --standalone -d "$DOMAIN"

# Check if the certificate was successfully obtained
if [ $? -eq 0 ]; then
  # Certificate obtained successfully
  CERT_PATH="/etc/letsencrypt/live/$DOMAIN"
  
  # Configure Apache to use the certificate
  sudo sed -i "s|^SSLCertificateFile.*|SSLCertificateFile $CERT_PATH/fullchain.pem|" /etc/httpd/conf.d/ssl.conf
  sudo sed -i "s|^SSLCertificateKeyFile.*|SSLCertificateKeyFile $CERT_PATH/privkey.pem|" /etc/httpd/conf.d/ssl.conf

  # Test Apache configuration
  if sudo apachectl configtest; then
    # Restart Apache if the configuration test passes
    sudo systemctl restart httpd
    echo "SSL certificate has been successfully configured for $DOMAIN."
  else
    echo "Error: Apache configuration test failed. Please check your SSL configuration."
  fi
else
  echo "Error: Failed to obtain the SSL certificate for $DOMAIN."
fi
