# MariaDB-Instructions

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
