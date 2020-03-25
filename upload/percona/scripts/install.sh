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
sudo yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm

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


#  MySQL root password

grep "temporary password" /var/log/mysqld.log

# Starting the service

sudo systemctl start mysqld

# run user-defined post-setup scripts
echo 'INSTALLER: Running user-defined post-setup scripts'

for f in /tmp/userscripts/*
  do
    case "${f,,}" in
      *.sh)
        echo "INSTALLER: Running $f"
        . "$f"
        echo "INSTALLER: Done running $f"
        ;;
      *.sql)
        echo "INSTALLER: Running $f"
        su -l oracle -c "echo 'exit' | sqlplus -s / as sysdba @\"$f\""
        echo "INSTALLER: Done running $f"
        ;;
      /tmp/userscripts/put_custom_scripts_here.txt)
        :
        ;;
      *)
        echo "INSTALLER: Ignoring $f"
        ;;
    esac
  done

echo 'INSTALLER: Done running user-defined post-setup scripts'

echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD";

echo "INSTALLER: Installation complete, database ready to use!";
