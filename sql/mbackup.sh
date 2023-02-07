#!/bin/bash

# Generate random password
password=$(openssl rand -base64 32)

# Create backup user
mysql -e "CREATE USER 'pdnsbackup'@'%' IDENTIFIED BY '$password';"

# Grant privileges
mysql -e "GRANT REPLICATION SLAVE ON *.* TO 'pdnsbackup'@'%';"

# Flush privileges
mysql -e "FLUSH PRIVILEGES;"

# Show master status
SMS=/tmp/show_master_status.txt
mysql -ANe "SHOW MASTER STATUS" > ${SMS}
CURRENT_LOG=`cat ${SMS} | awk '{print $1}'`
CURRENT_POS=`cat ${SMS} | awk '{print $2}'`
echo "Retrieved LOG ${CURRENT_LOG}"
echo "Retrieved POS ${CURRENT_POS}"

echo "Backup user created with password: ${password}"

echo "Backup user created with password: ${password}" > backup_settings.txt
echo "Current log: ${CURRENT_LOG}" >> backup_settings.txt
echo "Current pos: ${CURRENT_POS}" >> backup_settings.txt

echo "If you forget these credentials, you can find them in backup_settings.txt"

echo "Exporting current database"
echo "You might need to enter the password for the database"
# Exporting all databases
mysqldump -p pdns > pdns.sql
mysqldump -p varo > varo.sql

echo "Copy pdns.sql and varo.sql files to slave server"