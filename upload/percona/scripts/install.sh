#!/bin/bash
#

# MAINTAINER: Oussama DELASSI

# Abort on any error
set -e

echo 'INSTALLER: Started up'

# get up to date
yum upgrade -y

echo 'INSTALLER: System updated'

# Install the Percona repository
sudo yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm

echo 'INSTALLER: Percona repository complete'

# set system time zone
# sudo timedatectl set-timezone $SYSTEM_TIMEZONE
echo "INSTALLER: System time zone set to $SYSTEM_TIMEZONE"

# Enable the repository
sudo percona-release setup ps80

echo 'INSTALLER: Enable the repository complete'

#  install Percona Server for MySQL 
sudo yum install -y percona-server-server

echo 'INSTALLER:  install Percona Server for MySQL complete'


# Open Percona mysql listener port

sudo firewall-cmd --permanent --add-service=mysql

sudo firewall-cmd --reload

# Starting the service

sudo systemctl start mysqld

#  Reset MySQL temporary password for root@localhost

MYSQL_TEMP_PWD=$(sed -n '2{p;q}' /var/log/mysqld.log | tail -c 13)

MYSQL_PWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?=' | fold -w 15 | head -1)

echo "Mysql user (root) : $MYSQL_PWD" > .percona_passwd

mysql --connect-expired-password -uroot -p${MYSQL_TEMP_PWD} -e "alter user 'root'@'localhost' identified by \"${MYSQL_PWD}\";"


echo "MYSQL PASSWORD FOR root@localhost: $MYSQL_PWD";

echo "INSTALLER: Installation complete, database ready to use!";
