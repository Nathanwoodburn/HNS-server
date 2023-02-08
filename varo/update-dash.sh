#!/bin/bash

cd /var/www/html/dashboard
echo "Updating git repo"
git pull
cd etc
echo "Updating composer"
composer update
echo "Done"