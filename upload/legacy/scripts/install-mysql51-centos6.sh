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

# Autostart MySQL on boot (chkconfig --list mysqld)

chkconfig mysqld on

# Alternatively you can run: /usr/bin/mysql_secure_installation

# Install MyDumper
# yum install -y https://github.com/maxbube/mydumper/releases/download/v0.9.5/mydumper-0.9.5-2.el6.x86_64.rpm