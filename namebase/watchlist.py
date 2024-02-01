# This script will read a list of domains from a file and add them to the users NB watchlist.

import requests
import argparse
from datetime import datetime, timedelta
import json

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bulk add domains to watchlist in namebase")
    parser.add_argument("--token", required=True, help="Token for authentication")
    parser.add_argument("--file", required=True, help="File containing list of domains to add to watchlist")
    args = parser.parse_args()

    token = args.token
    filename = args.file

    headers = {
        "authority": "www.namebase.io",
        "accept": "application/json",
        "content-type": "application/json",
        "cookie": f"namebase-main={token}"
    }

    with open(filename) as f:
        domains = f.readlines()
    domains = [x.strip() for x in domains]

    for domain in domains:
        url = f"https://www.namebase.io/api/domains/watch/{domain}"
        
        response = requests.post(url, headers=headers, data=json.dumps({}))
        if response.status_code == 200:
            print(f"Added {domain} to watchlist")
        else:
            print(f"Error adding {domain} to watchlist")
            print(response.text)