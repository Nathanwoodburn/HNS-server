#!/bin/bash

ip=$1
password=$2
log=$3
pos=$4
backup=$5

apt-get install mariadb-server mariadb-client -y

# Replace old bind address with new bind address
sed -i "s/$oldbind/$newbind/g" /etc/mysql/mariadb.conf.d/50-server.cnf

# Add replication settings

#! Change server-id to be unique for each server
echo "server-id = 2" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "log_bin = /var/log/mysql/mysql-bin.log" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "log_bin_index =/var/log/mysql/mysql-bin.log.index" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "relay_log = /var/log/mysql/mysql-relay-bin" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "relay_log_index = /var/log/mysql/mysql-relay-bin.index" >> /etc/mysql/mariadb.conf.d/50-server.cnf

# Restart MySQL
systemctl restart mariadb

# Stop slave
mysql -e "STOP SLAVE;"

# Change master settings
mysql -e "CHANGE MASTER TO MASTER_HOST='$ip', MASTER_USER='pdnsbackup', MASTER_PASSWORD='$password', MASTER_LOG_FILE='$log', MASTER_LOG_POS=$pos;"

# start slave
mysql -e "START SLAVE;"

# Import database
mysql -p pdns < $backup