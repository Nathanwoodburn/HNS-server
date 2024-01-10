import requests
import argparse
from datetime import datetime, timedelta

def get_domains(apikey, wallet):
    url = f"http://x:{apikey}@127.0.0.1:12039/wallet/{wallet}/name?own=true"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)
        return response.json()

    except requests.exceptions.RequestException as e:
        print(f"Error making the request: {e}")
        return []

def save_to_file(lines, output_file):
    with open(output_file, "w") as file:
        for line in lines:
            file.write(line+'\n')
        


def main():
    parser = argparse.ArgumentParser(description="Retrieve and save domain names from API")
    parser.add_argument("--api-key", required=True, help="API key for authentication")
    parser.add_argument("--wallet", default="default", help="Wallet name")
    parser.add_argument("--format", default="{name}", help="Format of file to output")
    parser.add_argument("--output-file", default="domains.csv", help="Output file for saving domains")
    args = parser.parse_args()

    apikey = args.api_key
    wallet = args.wallet
    format = str(args.format)

    domains = get_domains(apikey, wallet)
    lines = [format.replace("{","").replace("}","")]
    for domain in domains:
        line = format.replace("{name}",domain['name'])
        expiry = "N/A"
        expiryBlock = "N/A"
        if 'daysUntilExpire' in domain['stats']:
            days = domain['stats']['daysUntilExpire']
            # Convert to dateTime
            expiry = datetime.now() + timedelta(days=days)
            expiry = expiry.strftime("%d/%m/%Y %H:%M:%S")
            expiryBlock = str(domain['stats']['renewalPeriodEnd'])

        line = line.replace("{expiry}",expiry)
        line = line.replace("{state}",domain['state'])
        line = line.replace("{expiryBlock}",expiryBlock)
        line = line.replace("{value}",str(domain['value']/1000000))
        line = line.replace("{maxBid}",str(domain['highest']/1000000))
        line = line.replace("{openHeight}",str(domain['height']))
        lines.append(line)

    save_to_file(lines, args.output_file)

if __name__ == "__main__":
    main()
