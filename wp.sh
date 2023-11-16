#!/bin/bash
# This script is used to install WordPress on your Linux server.
# It will install it in a docker container.
# Then it will create an NGINX reverse proxy to the container.

# USAGE:
# ./wp.sh [domain] [port offset]
# [domain] is the domain name you want to use for your WordPress site (e.g. docker.freeconcept)
# [port offset] is the offset you want to use for the port numbers.
# This is used if you want to run multiple instances of WordPress on the same server. (e.g. 0, 1, 2, 3, etc.)



# Variables
# Set the domain name

if [ -z "$1" ]
then
    echo "Please enter a domain name as the first argument."
    exit 1
fi

DOMAIN="$1"
echo "Setting up on domain name: $DOMAIN"

# Set port offset
# This is used to offset the port numbers so you can run multiple instances of WordPress on the same server.
if [ -z "$2" ]
then
    PORT_OFFSET=0
else
    PORT_OFFSET="$2"
fi


# Update the system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -y
sudo apt install docker-compose -y

mkdir wordpress-$DOMAIN
cd wordpress-$DOMAIN

# Generate passwords
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_PASSWORD=$(openssl rand -base64 32)

# Create port numbers
WORDPRESS_PORT=$((8000 + $PORT_OFFSET))

# Create the docker config file
echo """
version: \"3\"
services:
  ${DOMAIN}db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
      MYSQL_DATABASE: WordPressDatabase
      MYSQL_USER: WordPressUser
      MYSQL_PASSWORD: $MYSQL_PASSWORD
  wordpress:
    depends_on:
      - ${DOMAIN}db
    image: wordpress:latest
    restart: always
    ports:
      - \"${WORDPRESS_PORT}:80\"
    environment:
      WORDPRESS_DB_HOST: ${DOMAIN}db:3306
      WORDPRESS_DB_USER: WordPressUser
      WORDPRESS_DB_PASSWORD: $MYSQL_PASSWORD
      WORDPRESS_DB_NAME: WordPressDatabase
    volumes:
      [\"./:/var/www/html\"]
volumes:
  mysql: {}
""" > docker-compose.yml

# Start the containers
docker-compose up -d

# Create the NGINX
sudo apt install nginx -y

URL="http://localhost:$WORDPRESS_PORT"

# Setup NGINX config
printf "server {
  listen 80;
  listen [::]:80;
  server_name $DOMAIN;
  proxy_ssl_server_name on;
  location / {
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header Host \$http_host;
    proxy_set_header X-Forwarded-Host \$http_host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_pass $URL;
    }

    listen 443 ssl;
    ssl_certificate /etc/ssl/$DOMAIN.crt;
    ssl_certificate_key /etc/ssl/$DOMAIN.key;
}" > /etc/nginx/sites-available/$DOMAIN
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

#generate ssl certificate
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -keyout cert.key -out cert.crt -extensions ext  -config \
  <(echo "[req]";
    echo distinguished_name=req;
    echo "[ext]";
    echo "keyUsage=critical,digitalSignature,keyEncipherment";
    echo "extendedKeyUsage=serverAuth";
    echo "basicConstraints=critical,CA:FALSE";
    echo "subjectAltName=DNS:$DOMAIN,DNS:*.$DOMAIN";
    ) -subj "/CN=*.$DOMAIN"

# Print TLSA record and store in file in case of lost output
echo "Add this TLSA Record to your DNS:"
echo -n "3 1 1 " && openssl x509 -in cert.crt -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | xxd  -p -u -c 32

# Save TLSA to file
echo "Add this TLSA Record to your DNS:" > tlsa.txt
echo -n "3 1 1 " >> tlsa.txt
echo -n "" && openssl x509 -in cert.crt -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | xxd  -p -u -c 32 >> tlsa.txt

sudo mv cert.key /etc/ssl/$DOMAIN.key
sudo mv cert.crt /etc/ssl/$DOMAIN.crt

# Restart to apply config file
sudo systemctl restart nginx

cd ..