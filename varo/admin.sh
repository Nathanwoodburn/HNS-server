#!/bin/bash

email=$1
echo "Making admin with email"
echo $email

# Add admin to database
mysql -p varo -e "UPDATE users SET admin=1 WHERE email=\"$email\";"