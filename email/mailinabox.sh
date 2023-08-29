#!/bin/bash
RESOLVER=152.69.186.119

# This script will patch the Mail-in-a-Box system to allow for the use of Handshake domains.

# Set dns resolver
echo "nameserver $RESOLVER" > /etc/resolv.conf
echo "nameserver $RESOLVER" > /var/spool/postfix/etc/resolv.conf

# Replace the old mailconfig file to allow hns tlds
mv mailinabox/management/mailconfig.py mailinabox/management/mailconfig.py.old
# Download the new mailconfig file
wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/email/mailconfig.py -P mailinabox/management/

systemctl stop mailinabox
systemctl start mailinabox
systemctl status mailinabox