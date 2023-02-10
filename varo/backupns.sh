# Generate random password
LOCALPASS=$(date +%s | sha256sum | base64 | head -c 32)

# Add local login
sudo mysql -e "CREATE USER 'mutual'@'localhost' IDENTIFIED BY '$LOCALPASS';"
# Add perms
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'mutual'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Stop default DNS resolver
systemctl disable --now systemd-resolved
rm -rf /etc/resolv.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Setup pdns with mariadb backend
sudo apt-get install pdns-server pdns-backend-mysql -y

# add gmysql config
printf "launch+=gmysql
gmysql-host=localhost
gmysql-port=3306
gmysql-user=mutual
gmysql-password=$LOCALPASS
gmysql-dbname=pdns
gmysql-dnssec=yes" > /etc/powerdns/pdns.d/pdns.local.gmysql.conf

# Make sure perms is correct
chown pdns:pdns /etc/powerdns/pdns.d/pdns.local.gmysql.conf
chmod 755 -R /etc/powerdns


# Restart pdns
systemctl restart pdns

# Save password to file
echo "LOCALPASS: $LOCALPASS" > /var/www/html/mutual/etc/password.txt
echo "Password saved to /var/www/html/mutual/etc/password.txt"