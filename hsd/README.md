# HSD Scripts

This directory contains scripts for HSD.

## update.sh
This script is used to send batch updates for a list of domains.
To use it, create a file called `domains.txt` with a list of domains to update.

Edit the `update.sh` script to set:
- `apikey` to your HSD API key
- `wallet` to the name of your HSD wallet containing the domains
- `dns` to the DNS records to update the domains with

Then run `./update.sh` to send the updates.

## Save domain info
These scripts are used to save the domain info from your wallet

Format options are
- name -> domain name
- expiry -> estimated expiry
- expiryBlock -> Block domain expires
- value -> Amount paid in auction (in HNS)
- maxBid -> Highest bid in auction (in HNS)
- openHeight -> Height the auction opened
- state -> Domain state (usually only `CLOSED`)

### Names only
This only saves the domain names in 1 domain per line format.

```sh
python3 domains.py --api-key <api-key> --wallet <wallet-name> --output-file domains.csv
```

### Names + , + expiry
This saves the domain names in 1 domain per line format with the expiry date in seconds since epoch.  
! WARNING  
Expiries are only estimates as it depends on how long each block is.  
Always renew well before the expiry.

```sh
python3 domains.py --api-key <api-key> --wallet <wallet-name> --output-file domains.csv --format '{name},{expiry}'
```

