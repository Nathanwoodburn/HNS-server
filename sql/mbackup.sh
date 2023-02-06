oldbind="bind-address            = 127.0.0.1"
newbind="bind-address            = 0.0.0.0"

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