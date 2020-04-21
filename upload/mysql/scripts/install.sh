#!/bin/bash
#

# MAINTAINER: Oussama DELASSI
# Install Legacy MySQL 5.1 On CentOS 6

# Abort on any error
set -e

echo 'INSTALLER: Started up'

# get up to date
yum upgrade -y

echo 'INSTALLER: System updated'


#  install  MySQL Server 5.1 On CentOS 6
sudo yum install -y mysql-server

echo 'INSTALLER:  install MySQL complete'

# Open  mysql listener port (firewall disabled)

# Starting the service

sudo service mysqld start

# Autostart MySQL on boot

chkconfig mysqld on

# Alternatively you can run: /usr/bin/mysql_secure_installation