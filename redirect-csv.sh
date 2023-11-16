#!/bin/bash

FILE=$PWD/redirect-noinstall.sh
if [ -f "$FILE" ]; then
    echo "$FILE exists."
else 
    echo "$FILE does not exist. Downloading..."
    wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/redirect-noinstall.sh
    chmod +x redirect-noinstall.sh
fi

while IFS="," read -r domain url
do
  echo ""
  echo "Domain: $domain"
  echo "URL: $url"
  bash redirect-noinstall.sh $domain $url
done < <(tail -n +2 $1)


sudo systemctl restart nginx