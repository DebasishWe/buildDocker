#!/bin/bash
# Wait for MySQL to start
until mysql -u root --protocol=tcp -e "SELECT 1"; do
  echo "Waiting for MySQL to start..."
  mysql.server start
  sleep 1
done

mysql -u root --protocol=tcp -e "CREATE DATABASE GOD";
# Attempt to set global validate_password policy, ignore if it fails
mysql -u root --protocol=tcp -e "SET GLOBAL validate_password.policy=LOW;" || echo "Setting validate_password.policy failed, continuing..."

# Alter root user password
mysql -u root --protocol=tcp -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'pastprod';"

# Flush privileges
mysql -u root -ppastprod -P3306 --protocol=tcp -e "FLUSH PRIVILEGES;"

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -ppastprod -P3306 --protocol=tcp mysql

sudo cp /usr/local/bin/my.cnf.template /etc/my.cnf

# sudo sed -i 's/^#\s*validate_password\.policy = LOW/validate_password.policy = LOW/' /etc/my.cnf

