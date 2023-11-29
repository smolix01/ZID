#!/bin/bash

# Set your domain, email, selector, and IP address
DOMAIN="team-metamask.us"
EMAIL="no-reply@team-metamask.us"
SELECTOR="dkim"
IP_ADDRESS="223.165.77.229"

# Ensure the OpenDKIM package is installed
sudo yum install -y opendkim

# Generate DKIM keys
sudo opendkim-genkey -b 2048 -h rsa-sha256 -r -s "$SELECTOR" -d "$DOMAIN"

# Move and set permissions for DKIM keys
sudo mv "$SELECTOR.private" "/etc/opendkim/keys/$DOMAIN/"
sudo chown opendkim:opendkim "/etc/opendkim/keys/$DOMAIN/$SELECTOR.private"
sudo chmod 400 "/etc/opendkim/keys/$DOMAIN/$SELECTOR.private"

# Extract the public key
sudo opendkim-genkey -t -s "$SELECTOR" -d "$DOMAIN"
mv "$SELECTOR.txt" "/etc/opendkim/keys/$DOMAIN/"

# Configure OpenDKIM
sudo bash -c 'cat <<EOF > /etc/opendkim.conf
Domain $DOMAIN
KeyFile /etc/opendkim/keys/$DOMAIN/$SELECTOR.private
Selector $SELECTOR
EOF'

# Edit the KeyTable
sudo bash -c 'cat <<EOF > /etc/opendkim/KeyTable
$SELECTOR._domainkey.$DOMAIN $DOMAIN:$SELECTOR:/etc/opendkim/keys/$DOMAIN/$SELECTOR.private
EOF'

# Edit the SigningTable
sudo bash -c 'cat <<EOF > /etc/opendkim/SigningTable
*$DOMAIN $SELECTOR._domainkey.$DOMAIN
EOF'

# Edit the TrustedHosts
sudo bash -c 'cat <<EOF > /etc/opendkim/TrustedHosts
127.0.0.1
$IP_ADDRESS
$DOMAIN
EOF'

# Edit Postfix Configuration
sudo bash -c "echo 'smtpd_milters = inet:127.0.0.1:8891' >> /etc/postfix/main.cf"
sudo bash -c "echo 'non_smtpd_milters = \$smtpd_milters' >> /etc/postfix/main.cf"
sudo bash -c "echo 'milter_default_action = accept' >> /etc/postfix/main.cf"

# Restart Services
sudo hash -r
sudo systemctl start opendkim
sudo systemctl enable opendkim
sudo systemctl restart postfix

# Output instructions for DNS TXT record update
echo "To complete DKIM setup, update the DNS TXT record for your domain with the following value:"
cat "/etc/opendkim/keys/$DOMAIN/$SELECTOR.txt"
