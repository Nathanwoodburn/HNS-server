# Varo-Clone
[Backend](#backend)  
[Frontend](#frontend)  
[Add Varo Admin](#add-varo-admin)  
[Add a second nameserver](#replication)
[Updating Varo](#updating)


Outline of the setup process:
1. Set up a VPN tunnel between the backend and frontend (or use a shared network)
   1. You will need to setup a firewall to block all ports except 53, 22 for the backend and 80, 443 for the frontend
   2. I recommend tailscale VPN as it is super easy to setup and free
   3. Save the VPN IP address of Backend for use in step 3.1
2. Set up Backend
   1. Run the backend script (#backend)
   2. Save the LOCALPASS and APIPASS for use in step 3.1
   3. Test by ssh into the frontend and `curl <VPN IP>`
3. Set up Frontend
   1. Run the frontend script (#frontend) passing ICANN Domain, HNS Domain, LOCALPASS, APIPASS and VPN IP
   2. Fill in the config file with your website name, SMTP settings and stripe credentials
   3. Create an account and add yourself as an admin (#add-varo-admin) using the email you used to create the account
4. Optional set up a second nameserver
   1. Run the first master replication script (#replication) on the backend server you used in step 2
   2. Set up the vpn tunnel between on the second nameserver
   3. SFTP the varo.sql and pdns.sql files to the second nameserver
   4. In the same dirrectory as the sql files run the second master replication script (#replication) on the second nameserver using the vpn ip of the backend server and the output from step 4.1
5. Add records
   1. Create an account on the frontend and add the HNS domain to it
   2. Add these records to the blockchain records (replacing old records if they exist)
      1. Add a GLUE4 record for the HNS domain (eg. `ns1.yourtld`) to point it to the Backend Server and one the the second nameserver if you have one (eg. `ns2.yourtld`)
      2. Add the DS record as provided in the frontend
   3. Add an A record to the HNS domain on the frontend dashboard with the IP of the frontend server
   4. Add the TLSA record as provided in the frontend script (or use the [TLSA Script](https://github.com/nathanwoodburn/HNS-server#forgot-your-tlsa-record) to retrieve it)


Setup the backend first and use the output to setup the frontend.

## Backend
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/varo/mutual.sh`  
`sudo chmod +x mutual.sh`  
`sudo ./mutual.sh <HNS DOMAIN> <ICANN DOMAIN>`  

## Frontend
The frontend needs to be sent this information:  
IP of the backend  
LOCALPASS (generated and saved in /var/www/html/mutual/etc/password.txt)  
APIPASS (generated and saved in /var/www/html/mutual/etc/password.txt)  
ICANN Domain (Must have A record pointing to the frontend before running script or it will fail)  
HNS Domain  


`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/varo/dash.sh`  
`sudo chmod +x dash.sh`  
`sudo ./dash.sh <ICANN DOMAIN> <HNS DOMAIN> <LOCALPASS> <APIPASS> <IP OF BACKEND>`  

You need to edit the config file to add your websites name, SMTP settings (to send password resets) and stripe credentials (!This is needed to get the site working).  
`nano /var/www/html/dashboard/etc/config.php`  
Don't edit the passwords as they are generated and used by multiple processes.  

## Add Varo Admin

Add an admin to your varo installation.  
This gives them access to the admin panel.  
Run this script on the backend server.  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/varo/admin.sh`  
`sudo chmod +x admin.sh`  
`sudo ./admin.sh <user's email>`  

# Replication

## Master  
If this is the first slave to add to the master, run the following commands.  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/sql/mbackup.sh`  
`sudo chmod +x mbackup.sh`  
`sudo ./mbackup.sh`  

If you have already setup a slave, then run the following commands.  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/sql/addbackup.sh`  
`sudo chmod +x addbackup.sh`  
`sudo ./addbackup.sh`  

## Slave
First you need these config from the master setup  
+ Master IP (Internal VPN or shared network is most secure)
+ Generated Password
+ Log
+ Pos

You also need the two database exports (varo.sql and pdns.sql) in the directory you are when running the script.  
`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/sql/sbackup.sh`  
`sudo chmod +x sbackup.sh`  
`sudo ./sbackup.sh <MASTER IP> <PASSWORD> <LOG> <POS>`  


# Updating

To update the frontend run the following commands.

`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/varo/update-dash.sh`
`sudo chmod +x update-dash.sh`
`sudo ./update-dash.sh`

To update the backend run the following commands.

`wget https://raw.githubusercontent.com/Nathanwoodburn/HNS-server/main/varo/update-mutual.sh`
`sudo chmod +x update-mutual.sh`
`sudo ./update-mutual.sh`