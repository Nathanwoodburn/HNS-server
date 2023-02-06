#!/bin/bash
oldbind="bind-address            = 127.0.0.1"
newbind="bind-address            = 0.0.0.0"

# Check if file already changed
if grep -q "$newbind" "/etc/mysql/mariadb.conf.d/50-server.cnf"; then
    echo "File already changed"
    exit 0
fi

# Replace old bind address with new bind address
sed -i "s/$oldbind/$newbind/g" /etc/mysql/mariadb.conf.d/50-server.cnf

# Add replication settings
echo "server-id = 1" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "log_bin = /var/log/mysql/mysql-bin.log" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "log_bin_index =/var/log/mysql/mysql-bin.log.index" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "relay_log = /var/log/mysql/mysql-relay-bin" >> /etc/mysql/mariadb.conf.d/50-server.cnf
echo "relay_log_index = /var/log/mysql/mysql-relay-bin.index" >> /etc/mysql/mariadb.conf.d/50-server.cnf

# Restart MySQL
systemctl restart mysql

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

# Exporting current database
mysqldump -u root -p pdns > database.sql