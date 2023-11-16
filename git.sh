#!/bin/bash

# This script is used to setup nginx for a static website using files from a git repository.
# Make sure the git repo has an `index.html` and `404.html` file.

# Usage ./git.sh [domain] [git repo url]
# Example ./git.sh nathan.woodburn https://github.com/Nathanwoodburn/Nathanwoodburn.github.io.git

# Variables
domain=$1
git_repo=$2

# Check if domain name is set
if [ -z "$1" ]
then
  echo "Domain name:"
  read domain
fi

# Check if git repo is set
if [ -z "$2" ]
then
  echo "Git repo:"
  read git_repo
fi

# Check if nginx is installed
if ! [ -x "$(command -v nginx)" ]; then
    sudo apt update
    sudo apt install nginx -y
fi

# Clone git repo
git clone $git_repo /var/www/$domain


# Setup NGINX config
printf "server {
  listen 80;
  listen [::]:80;
  root /var/www/$domain;
  index index.html;
  server_name $domain *.$domain;

    location / {
        try_files \$uri \$uri/ @htmlext;
    }

    location ~ \.html$ {
        try_files \$uri =404;
    }

    location @htmlext {
        rewrite ^(.*)$ \$1.html last;
    }
    error_page 404 /404.html;
    location = /404.html {
            internal;
    }
    location = /.well-known/wallets/HNS {
        add_header Cache-Control 'must-revalidate';
        add_header Content-Type text/plain;
    }
    listen 443 ssl;
    ssl_certificate /etc/ssl/$domain.crt;
    ssl_certificate_key /etc/ssl/$domain.key;
}
" > /etc/nginx/sites-available/$domain
sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain

#generate ssl certificate
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -keyout cert.key -out cert.crt -extensions ext  -config \
  <(echo "[req]";
    echo distinguished_name=req;
    echo "[ext]";
    echo "keyUsage=critical,digitalSignature,keyEncipherment";
    echo "extendedKeyUsage=serverAuth";
    echo "basicConstraints=critical,CA:FALSE";
    echo "subjectAltName=DNS:$domain,DNS:*.$domain";
    ) -subj "/CN=*.$domain"

TLSA=$(echo -n "3 1 1 " && openssl x509 -in cert.crt -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | xxd  -p -u -c 32)

echo "TLSA: $TLSA"

sudo mv cert.key /etc/ssl/$domain.key
sudo mv cert.crt /etc/ssl/$domain.crt

# Restart to apply config file
sudo systemctl restart nginx