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