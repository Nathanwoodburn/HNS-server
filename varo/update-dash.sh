#!/bin/bash

cd /var/www/html/dashboard
echo "Updating git repo"
git stash
git pull
export COMPOSER_ALLOW_SUPERUSER=1;
cd etc
composer install
cd ..