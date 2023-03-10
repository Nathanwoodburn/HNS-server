#!/bin/bash

# Do some checks

# Check if root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check that 5 arguments are passed
if [ "$#" -ne 5 ]; then
	echo "Illegal number of parameters"
	exit
fi

# Set variable
ICANN=$1
HANDSHAKE=$2
LOCALPASS=$3
APIPASS=$4
IP=$5

echo "Checking for ICANN DNS"
# Check that ICANN DNS is set
# Get public IP
PUBLICIP=$(curl -s https://api.ipify.org)

# Dig Cloudflare for ICANN DNS
ICANNIP=$(dig +short $ICANN @1.1.1.1 | head -n 1)

# Check if IP matches
if [ "$PUBLICIP" != "$ICANNIP" ]; then
	echo "ICANN DNS is not set to $PUBLICIP"
	exit
fi


echo "Checks passed."
echo "Installing a ton of stuff"
# Update repo
sudo apt-get update -y

# Install a ton of things
sudo apt-get install apache2 php php-mysql certbot python3-certbot-apache php-curl php-intl composer npm git -y
sudo a2enmod rewrite ssl headers


# Generate textonly password
HSDAPI=$(date +%s | sha256sum | base64 | head -c 32)
echo $HSDAPI > hsdapikey.txt

echo "Pulling git repo"

# Pull varodomains dashboard
cd /var/www/html
git clone https://github.com/varodomains/dashboard
cd dashboard

echo "Building from git repo"

export COMPOSER_ALLOW_SUPERUSER=1;
cd etc
composer install
cd ..

echo "Generating Handshake SSL"

# Generate SSL cert
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -keyout cert.key -out cert.crt -extensions ext  -config \
  <(echo "[req]";
    echo distinguished_name=req;
    echo "[ext]";
    echo "keyUsage=critical,digitalSignature,keyEncipherment";
    echo "extendedKeyUsage=serverAuth";
    echo "basicConstraints=critical,CA:FALSE";
    echo "subjectAltName=DNS:$HANDSHAKE,DNS:*.$HANDSHAKE";
    ) -subj "/CN=*.$HANDSHAKE"

mv cert.crt /etc/ssl/$HANDSHAKE.crt
mv cert.key /etc/ssl/$HANDSHAKE.key

# Give read permission to www dir
sudo chmod 755 -R /var/www/html

echo "Adding apache config"

# Add apache2 server conf
echo "<VirtualHost *:80>" > /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        ServerName $ICANN" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        ServerAdmin admin@$ICANN" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        DocumentRoot /var/www/html/dashboard" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        ErrorLog \${APACHE_LOG_DIR}/error.log" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        CustomLog \${APACHE_LOG_DIR}/access.log combined" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        Include conf-available/serve-cgi-bin.conf" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        DirectoryIndex index.html index.php" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        RewriteEngine on" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        RewriteCond %{SERVER_PORT} \!^443\$" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "        RewriteRule ^/(.*) https://%{HTTP_HOST}/\$1 [NC,R,L]" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "    ServerName $HANDSHAKE" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "    DocumentRoot /var/www/html/dashboard" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/$HANDSHAKE.conf

# Remove \ (for some reason it adds \ instead of escaping ! but without ! it causes errors)
sed -i 's/\\//g' /etc/apache2/sites-available/$HANDSHAKE.conf

# Enable site and restart apache
echo "Applying apache config"
sudo a2ensite $HANDSHAKE.conf
systemctl restart apache2

# Add LetsEncrypt cert
echo "Adding LetsEncrypt cert"
sudo certbot --apache -d $ICANN

# Add Handshake SSL config
echo "Adding Handshake SSL config"

echo "<VirtualHost *:443>" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "    ServerName $HANDSHAKE" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "    DocumentRoot /var/www/html/dashboard" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "    SSLEngine on" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "    SSLCertificateFile /etc/ssl/$HANDSHAKE.crt" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "    SSLCertificateKeyFile /etc/ssl/$HANDSHAKE.key" >> /etc/apache2/sites-available/$HANDSHAKE.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/$HANDSHAKE.conf
systemctl restart apache2

# Adding varo config and setting variables
echo "Autofilling Varo config"

printf "<?php
	\$GLOBALS[\"path\"] = \"/var/www/html/dashboard\";
	\$GLOBALS[\"branch\"] = \"main\";

	\$GLOBALS[\"siteName\"] = \"varo\";

	\$GLOBALS[\"hnsHostname\"] = \"$HANDSHAKE\";
	\$GLOBALS[\"icannHostname\"] = \"$ICANN\";
	\$GLOBALS[\"betaHostname\"] = \"beta.$HANDSHAKE\";

	\$GLOBALS[\"sqlHost\"] = \"$IP\";
	\$GLOBALS[\"sqlUser\"] = \"mutual\";
	\$GLOBALS[\"sqlPass\"] = \"$LOCALPASS\";
	\$GLOBALS[\"sqlDatabase\"] = \"varo\";
	\$GLOBALS[\"sqlDatabaseDNS\"] = \"pdns\";

	\$GLOBALS[\"smtpHost\"] = \"host\";
	\$GLOBALS[\"smtpUser\"] = \"username\";
	\$GLOBALS[\"smtpPass\"] = \"password\";
	\$GLOBALS[\"fromName\"] = \"varo/\";
	\$GLOBALS[\"fromEmail\"] = \"noreply@varo.domains\";

	\$GLOBALS[\"tweetSales\"] = false;
	\$GLOBALS[\"discordLink\"] = \"https://discord.gg/5KdtCVsGes\";

	\$GLOBALS[\"hsdKey\"] = \"$HSDAPI\";

	\$GLOBALS[\"pdnsApiHost\"] = \"$IP\";
	\$GLOBALS[\"pdnsApiPass\"] = \"$APIPASS\";

	\$GLOBALS[\"recordTypes\"] = [\"A\", \"AAAA\", \"ALIAS\", \"CNAME\", \"DS\", \"MX\", \"NS\", \"PTR\", \"SPF\", \"TLSA\", \"TXT\"];

	\$GLOBALS[\"currency\"] = \"usd\";
	\$GLOBALS[\"stripeSecretKey\"] = \"your-stripe-secret-here\";
	\$GLOBALS[\"stripePublicKey\"] = \"your-stripe-public-here\";

	\$GLOBALS[\"sldFee\"] = 15;
	\$GLOBALS[\"salesRowsPerPage\"] = 20;
	\$GLOBALS[\"maxRegistrationYears\"] = 10;
	\$GLOBALS[\"purchaseTypes\"] = [\"register\", \"renew\"];

	\$GLOBALS[\"normalSOA\"] = \"ns1.\".\$GLOBALS[\"icannHostname\"].\" ops.\".\$GLOBALS[\"icannHostname\"].\" 1 10800 3600 604800 3600\";
	\$GLOBALS[\"normalNS1\"] = \"ns1.\".\$GLOBALS[\"icannHostname\"];
	\$GLOBALS[\"normalNS2\"] = \"ns2.\".\$GLOBALS[\"icannHostname\"];
	
	\$GLOBALS[\"handshakeSOA\"] = \"ns1.\".\$GLOBALS[\"hnsHostname\"].\" ops.\".\$GLOBALS[\"icannHostname\"].\" 1 10800 3600 604800 3600\";
	\$GLOBALS[\"handshakeNS1\"] = \"ns1.\".\$GLOBALS[\"hnsHostname\"].\".\";
	\$GLOBALS[\"handshakeNS2\"] = \"ns2.\".\$GLOBALS[\"hnsHostname\"].\".\";

	\$GLOBALS[\"walletName\"] = \"primary\";
	\$GLOBALS[\"accountName\"] = \"default\";

	\$GLOBALS[\"invoiceExpiration\"] = 7200;

	\$GLOBALS[\"ipWhitelist\"] = [\"192.168.1.0/24\"];

	\$GLOBALS[\"themes\"] = [\"black\", \"dark\", \"light\", \"the_shake\"];
?>" > /var/www/html/dashboard/etc/config.php


# Add cronjob
echo "Creating cronjob"
crontab -l > cron
printf "*/1 * * * * /usr/bin/php /var/www/html/dashboard/etc/cron.php >/dev/null 2>&1
" > cron
crontab cron
rm cron

# Fix apache conf
echo "Editing apache conf"
rm /etc/apache2/apache2.conf
wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/varo/apache2.conf -O /etc/apache2/apache2.conf
systemctl restart apache2
sudo ufw allow 'Apache Full'


# Install HSD
echo "Installing HSD"
cd etc
git clone --depth 1 --branch latest https://github.com/handshake-org/hsd.git
cd hsd
npm install --omit=dev
screen -dmS HSD ./bin/hsd --spv --api-key=$APIKEY
echo "Started HSD use screen -r to view it"

# Echo TLSA record
echo "TLSA record:"
echo -n "3 1 1 " && openssl x509 -in /etc/ssl/$HANDSHAKE.crt -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | xxd  -p -u -c 32