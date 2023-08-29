# HNS-server
+ [NGINX HNS](#nginx-hns)  
+ [NGINX ICANN](#nginx-icann)  
+ [Redirect/Mirror Automation](#automation)
+ [Varo Clone](varo)  
+ [MariaDB Replication (after Varo cloning)](sql)  
+ [Email Server](email)


# NGINX-HNS
Run Installation scripts as below.  
Then add A record to point to your server and add the TLSA generated by the script to your DNS.  
Running these scripts without arguments will start the interactive mode which will ask you for each variable.  
Variables should be in this format (changing as needed)  
Domain: `woodburn` or for slds `nathan.woodburn`  
Location: `/var/www/woodburn`  
URL: `https://nathan.woodburn.au` or `https://nathan.woodburn.au/about`  



## Standard HNS domain with HTML content (TLD and Wildcard SLD)
This creates a website with TLD and SLD pointing to one directory.  
This installs nginx as well as setup HNS domains.  
Change directory into the directory containing your website files.  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/new`  
`sudo chmod +x new`  
`sudo ./new <HNSDOMAIN>`  


## Standard HNS domain with HTML content (SLD only)
Same as above without wildcard.  
This uses the prexisting SSL Cert.  
So add the same TLSA DNS record as the previously generated one.  
Change directory into the directory containing your website files.  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/addsld`  
`sudo chmod +x addsld`  
`sudo ./addsld <HNSTLD> <HNSSLD>` #For example nathan.woodburn would be `sudo ./addsld woodburn nathan`  

## Proxy HNS domain to ICANN site (TLD and Wildcard SLD)
This will create a mirror of the ICANN site showing the Handshake domain in the url bar.

`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/proxy`  
`sudo chmod +x proxy`  
`sudo ./proxy <HNSDOMAIN> <target url>`  

Example proxy *.3dprintingservice -> nathan3dprinting.au  
`sudo ./proxy 3dprintingservice https://nathan3dprinting.au`  

## Proxy HNS domain to ICANN site (SLD or TLD only)
This will create a mirror of the ICANN site showing the Handshake domain in the url bar.  
This will only proxy the provided SLD or TLD.  
Eg only proxy nathan.3dprintingservice  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/proxy-sld`
`sudo chmod +x proxy-sld`
`sudo ./proxy-sld nathan.3dprintingservice https://nathan3dprinting.au`  

## Redirect HNS domain to ICANN site (TLD and Wildcard SLD)
Replace proxy with redirect to do a redirect instead of a mirror (proxy).  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/redirect`   
`sudo chmod +x redirect`  
`sudo ./redirect <HNSDOMAIN> <target url>`  



## Redirect HNS domain to ICANN site (SLD or TLD only)
Replace proxy with redirect to do a redirect instead of a mirror (proxy).  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/redirect-sld`  
`sudo chmod +x redirect-sld`  
`sudo ./redirect-sld nathan.3dprintingservice https://nathan3dprinting.au`  


## Forgot your TLSA record?  
This script will find the TLSA record for you.  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/tlsa`  
`sudo chmod +x tlsa`  
`./tlsa <HNSTLD>`

# NGINX-ICANN

## Standard ICANN domain with HTML content
First add A record to point to your server so Letsencrypt can generate you SSL cert.  
Then run this script  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/newicann`  
`sudo chmod +x newicann`  
`sudo ./newicann <DOMAIN>`  

## Proxy ICANN domain to another ICANN site
Eg proxy 3dprinting.woodburn.au -> nathan3dprinting.au  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/proxyicann`  
`sudo chmod +x proxyicann`  
`sudo ./proxyicann 3dprinting.woodburn.au https://nathan3dprinting.au`  

## Redirect ICANN domain to another ICANN site
Eg redirect 3dprinting.woodburn.au -> nathan3dprinting.au  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/redirecticann`  
`sudo chmod +x redirecticann`  
`sudo ./redirecticann 3dprinting.woodburn.au https://nathan3dprinting.au`  


# Wordpress
## Wordpress with HNS domain
```sh
wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/wp.sh
sudo chmod +x wp.sh
sudo ./wp.sh <HNSDOMAIN>
```

If you want to have multiple wordpress sites on the same server you can use the following command to create a new wordpress site. The port offset only affects the port used for the wordpress site. The port used for the HNS domain will always be 80 & 443.
```sh
sudo ./wp.sh <HNSDOMAIN> <PORT OFFSET>
```

# Static html site from Git repo
```sh
wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/git.sh
sudo chmod +x git.sh
sudo ./git.sh <HNSDOMAIN> <GIT REPO>
```



# Automation

## csv File Format
The csv file should be format  
`<HNSDOMAIN>,<TARGETURL>`  
Eg  
`3dprintingservice,https://nathan3dprinting.au`  
Please note you need a header row as this script will not use the first row of the csv file.

## Proxy HNS domain to ICANN site
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/proxy-csv.sh`  
`sudo chmod +x proxy-csv.sh`  
`sudo ./proxy-csv.sh <csv file>`  

## Redirect HNS domain to ICANN site
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/redirect-csv.sh`  
`sudo chmod +x redirect-csv.sh`  
`sudo ./redirect-csv.sh <csv file>`  