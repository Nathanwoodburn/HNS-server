# Ask user from which domain he wants to get the certificate
echo "Please enter the domain name:"
read domain

if [ -z "$domain" ]
then
      echo "You did not enter a domain name"
      exit 1
fi

resolver=152.69.186.119

# Get the IP address of the domain
ip=$(dig @$resolver +short $domain)
echo "The IP address of $domain is $ip"


# Get the certificate from the server
openssl s_client -showcerts -connect $ip:443 -servername $domain < /dev/null 2>/dev/null | (while openssl x509 2>/dev/null; do true; done) > pub.crt
echo "The certificate is:"
cat pub.crt
echo "The certificate TLSA is:"
echo -n "3 1 1 " && openssl x509 -in pub.crt -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | xxd  -p -u -c 32