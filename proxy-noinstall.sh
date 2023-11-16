#!/bin/bash
# Setup NGINX config
printf "server {
  listen 80;
  listen [::]:80;
  server_name $1 *.$1;
  proxy_ssl_server_name on;
  location / {
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_pass $2;
    }

    listen 443 ssl;
    ssl_certificate /etc/ssl/$1.crt;
    ssl_certificate_key /etc/ssl/$1.key;
}" > /etc/nginx/sites-available/$1
sudo ln -s /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled/$1

#generate ssl certificate
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -keyout cert.key -out cert.crt -extensions ext  -config \
  <(echo "[req]";
    echo distinguished_name=req;
    echo "[ext]";
    echo "keyUsage=critical,digitalSignature,keyEncipherment";
    echo "extendedKeyUsage=serverAuth";
    echo "basicConstraints=critical,CA:FALSE";
    echo "subjectAltName=DNS:$1,DNS:*.$1";
    ) -subj "/CN=*.$1"

# Print TLSA record and store in file in case of lost output
echo "Add this TLSA Record to your DNS for HNS domain $1:"
echo -n "3 1 1 " && openssl x509 -in cert.crt -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | xxd  -p -u -c 32
sudo mv cert.key /etc/ssl/$1.key
sudo mv cert.crt /etc/ssl/$1.crt