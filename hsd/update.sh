#!/bin/bash

apikey="changeme" #! change this to your api key
wallet="hot" #! change this to your wallet name

# Set your DNS here. Example:
dns="{\"type\": \"NS\",\"ns\": \"ns1.woodburn.\"},{\"type\": \"NS\",\"ns\": \"ns2.woodburn.\"}"


# Get domains from file domains.txt
while read -r line; do
    domains+=("$line")
done < domains.txt

# Generate param
for domain in "${domains[@]}"; do
    batch+=("[\"UPDATE\", \"$domain\", {\"records\":[$dns]}]")
done
batch="[$(IFS=,; echo "${batch[*]}")]"
echo "$batch"

# Unlock wallet
echo "Enter password for wallet $wallet"
read -s pass
hsw-cli unlock --id=$wallet $pass 120 --api-key=$apikey
hsw-rpc selectwallet $wallet --api-key=$apikey

# Send batch
hsw-rpc sendbatch "$batch" --api-key=$apikey

