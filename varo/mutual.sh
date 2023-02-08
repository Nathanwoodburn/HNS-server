#!/bin/bash

# Setup Nginx with php
sudo apt-get update -y
sudo apt-get install nginx -y
sudo apt-get install php8.1-fpm php-mysql -y

#php-curl

# Pull varodomains mutual
cd /var/www/html
git clone https://github.com/varodomains/mutual.git
cd mutual

# Add nginx server conf
printf "server {
    listen 80;
    listen [::]:80;
    root /var/www/html/mutual;
    index index.php index.html index.htm;
    server_name default_server;
    location / {
            # First attempt to serve request as file, then
            # as directory, then fall back to displaying a 404.
            try_files \$uri \$uri/ =404;
    }
    # pass PHP scripts to FastCGI server
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }
    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    location ~ /\.ht {
            deny all;
    }
}" > /etc/nginx/sites-available/default

# Restart nginx
sudo systemctl restart nginx

# Add read permission www dir
sudo chmod a+r /var/www/html

# Install mariadb
sudo apt-get install mariadb-server -y

# Generate random password
LOCALPASS=$(date +%s | sha256sum | base64 | head -c 32)

# Add local login
sudo mysql -e "CREATE USER 'mutual'@'localhost' IDENTIFIED BY '$LOCALPASS';"

# Create databases
sudo mysql -e "CREATE DATABASE pdns;"
sudo mysql -e "CREATE DATABASE varo;"

# Add tables to pdns database
sudo mysql pdns < /var/www/html/mutual/etc/tables.sql

# Wget varo sql tables
wget https://raw.githubusercontent.com/varodomains/dashboard/main/etc/tables.sql

# Add tables to varo database
sudo mysql varo < tables.sql
rm tables.sql

# Add perms
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'mutual'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Add remote user
sudo mysql -e "CREATE USER 'mutual'@'%' IDENTIFIED BY '$LOCALPASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'mutual'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Open port to public
oldbind="bind-address            = 127.0.0.1"
newbind="bind-address            = 0.0.0.0"
sudo sed -i "s/$oldbind/$newbind/g" /etc/mysql/mariadb.conf.d/50-server.cnf

# Add replication settings (for later use)
echo "server-id = 1" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "log_bin = /var/log/mysql/mysql-bin.log" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "log_bin_index =/var/log/mysql/mysql-bin.log.index" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "relay_log = /var/log/mysql/mysql-relay-bin" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "relay_log_index = /var/log/mysql/mysql-relay-bin.index" >> /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mariadb

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
chmod 777 -R /etc/powerdns
#chown pdns:pdns /etc/powerdns/pdns.d/pdns.local.gmysql.conf

# Restart pdns
systemctl restart pdns

# Save password to file
echo "LOCALPASS: $LOCALPASS" > /var/www/html/mutual/etc/password.txt
echo "Password saved to /var/www/html/mutual/etc/password.txt"

# Add cron
crontab -l > cron
printf "0 0 * * * /usr/bin/php /var/www/html/mutual/etc/tlds.php >/dev/null 2>&1
" > cron
crontab cron
rm cron

# Generate random password
APIPASS=$(date +%s | sha256sum | base64 | head -c 32)

# Create conf file
printf "<?php
        \$path = \"/var/www/html/mutual/\";

        \$GLOBALS[\"hnsHostname\"] = \"$1\";
        \$GLOBALS[\"icannHostname\"] = \"$2\";

        \$GLOBALS[\"localSqlHost\"] = \"localhost\";
        \$GLOBALS[\"localSqlUser\"] = \"mutual\";
        \$GLOBALS[\"localSqlPass\"] = \"$LOCALPASS\";
        \$GLOBALS[\"localSqlDatabase\"] = \"pdns\";

        \$GLOBALS[\"remoteSqlHost\"] = \"localhost\";
        \$GLOBALS[\"remoteSqlUser\"] = \"mutual\";
        \$GLOBALS[\"remoteSqlPass\"] = \"$LOCALPASS\";
        \$GLOBALS[\"remoteSqlDatabase\"] = \"pdns\";

        \$GLOBALS[\"pass\"] = \"$APIPASS\";

        \$GLOBALS[\"normalSOA\"] = \"ns1.\".\$GLOBALS[\"icannHostname\"].\" ops.\".\$GLOBALS[\"icannHostname\"].\" 1 10800 3600 604800 3600\";
        \$GLOBALS[\"normalNS1\"] = \"ns1.\".\$GLOBALS[\"icannHostname\"];
        \$GLOBALS[\"normalNS2\"] = \"ns2.\".\$GLOBALS[\"icannHostname\"];

        \$GLOBALS[\"handshakeSOA\"] = \"ns1.\".\$GLOBALS[\"hnsHostname\"].\" ops.\".\$GLOBALS[\"icannHostname\"].\" 1 10800 3600 604800 3600\";
        \$GLOBALS[\"handshakeNS1\"] = \"ns1.\".\$GLOBALS[\"hnsHostname\"].\".\";
        \$GLOBALS[\"handshakeNS2\"] = \"ns2.\".\$GLOBALS[\"hnsHostname\"].\".\";
?>" > /var/www/html/mutual/etc/config.php

# Save password to file
echo "APIPASS: $APIPASS" >> /var/www/html/mutual/etc/password.txt

# Add sudo to web user
printf "User_Alias WEBAPI = www-data
Cmnd_Alias PDNSUTIL = /usr/bin/pdnsutil
WEBAPI ALL=NOPASSWD: PDNSUTIL
" >> /etc/sudoers

# Run tlds.php
php /var/www/html/mutual/etc/tlds.php