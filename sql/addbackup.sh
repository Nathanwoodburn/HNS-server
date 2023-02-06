#!/bin/bash

# Show master status
SMS=/tmp/show_master_status.txt
mysql -ANe "SHOW MASTER STATUS" > ${SMS}
CURRENT_LOG=`cat ${SMS} | awk '{print $1}'`
CURRENT_POS=`cat ${SMS} | awk '{print $2}'`
echo "Retrieved LOG ${CURRENT_LOG}"
echo "Retrieved POS ${CURRENT_POS}"

echo "Exporting current database"
echo "You might need to enter the password for the database"
# Export all databases
mysqldump -p pdns > pdns.sql
mysqldump -p varo > varo.sql
echo "Copy pdns.sql and varo.sql files to slave server"
echo "Use password from first slave server command"