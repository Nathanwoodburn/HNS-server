# HNS-server
Instructions  
Run Installation script as below.  
Then add A record to point to your server and add the TLSA generated by the script to your DNS.  

Create a Linux server with TLD and SLD to one directory. This installs nginx as well as setup HNS domains
Change directory into the directory containing your website files.  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/new`  
`sudo chmod +x new`  
`sudo ./new <HNSDOMAIN>` # Use your TLD. This adds a wildcard so *.[HNSDOMAIN] will point to these files  

Add a new SLD (or dedicated TLD ONLY) to a previously setup Linux server. This uses the prexisting SSL Cert. So add the same TLSA as the previously generated one.  
Change directory into the directory containing your website files.  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/addsld`  
`sudo chmod +x addsld`  
`sudo ./addsld <HNSTLD> <HNSSLD>` #For example nathan.woodburn would be `sudo ./addsld woodburn nathan`  

TLD and SLD proxy to ICANN site. This installs nginx as well as setup HNS domains  

`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/proxy`  
`sudo chmod +x proxy`  
`sudo ./proxy <HNSDOMAIN> <target url>` # Use your TLD. This adds a wildcard so *.[HNSDOMAIN] will point to these files  
Example proxy *.3dprintingservice -> nathan3dprinting.au
`sudo ./proxy 3dprintingservice https://nathan3dprinting.au`

For a non wildcard use ./proxy-sld
Eg only proxy nathan.3dprintingservice
`sudo ./proxy-sld nathan.3dprintingservice https://nathan3dprinting.au`
