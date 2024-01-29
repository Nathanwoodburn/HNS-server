# This script will automatically accept all pending transactions in your namebase account over a certain threshold.


import requests
import argparse
from datetime import datetime, timedelta
import json

def get_pending(token,page=0):
    url = f"https://www.namebase.io/api/v0/offers/received?offset={page}&sortKey=createdAt&sortDirection=asc&showHidden=true"
    headers = {
        "authority": "www.namebase.io",
        "accept": "application/json",
        "content-type": "application/json",
        "cookie": f"namebase-main={token}"
    }
    return requests.get(url, headers=headers).json()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bulk accept offers in namebase")
    parser.add_argument("--token", required=True, help="Token for authentication")
    parser.add_argument("--threshold", required=True, help="Threshold for accepting offers in HNS (default 1000)")
    args = parser.parse_args()

    token = args.token
    threshold = float(args.threshold)

    headers = {
        "authority": "www.namebase.io",
        "accept": "application/json",
        "content-type": "application/json",
        "cookie": f"namebase-main={token}"
    }

    pending = get_pending(token)
    if pending['success'] != True:
        print("Error getting pending offers")
        exit(1)

    print("Checking offers: " + str(pending['totalCount']))

    total = pending['totalCount']
    seen = 0
    while seen < total:
        for offer in pending['domains']:
            if float(offer['highestCurrentOffer']) >= threshold:
                # Get best non expired offer
                offers = requests.get(f"https://www.namebase.io/api/v0/offers/history?domainOwnerId={offer['domainOwnerId']}", headers=headers).json()
                bestValidBid = -1
                bestValidBidID = ""
                for o in offers['negotiations']:
                    for bid in o['history']['bids']:
                        if bid['isExpired']:
                            continue
                        amount = float(bid['amount'])
                        if amount > bestValidBid:
                            bestValidBid = amount
                            bestValidBidID = bid['bidId']

                if bestValidBid >= threshold:
                    acceptResponse = requests.post('https://www.namebase.io/api/v0/offers/bid',json={'bidId':bestValidBidID},headers=headers)
                    if acceptResponse.status_code == 200:
                        print(f"Accepted {offer['domain']} for {bestValidBid}")
                        

        seen += len(pending['domains'])
        if seen < total:
            pending = get_pending(token,seen)

        





    