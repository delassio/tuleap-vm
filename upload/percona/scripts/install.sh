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

passwd_file=/root/.percona_passwd

if [ ! -f "$passwd_file" ]; then
    echo `date` "[Note] mysql temporary root password:" `sed -n '2{p;q}' /var/log/mysqld.log | tail -c 13` >> $passwd_file
fi

TEMP_PWD=`sed '$!d' $passwd_file | tail -c 13`

echo `date` "[Note] mysql generated root password:" `cat /dev/urandom | tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?=' | fold -w 12 | head -1` >> $passwd_file

MYSQL_PWD=`sed '$!d' $passwd_file | tail -c 13`

mysql --connect-expired-password -uroot -p${TEMP_PWD} -e "alter user 'root'@'localhost' identified by \"${MYSQL_PWD}\";"

# run user-defined post-setup, import scripts
echo 'INSTALLER: Running user-defined scripts'

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
        MYSQL_PWD=`sed '$!d' $passwd_file | tail -c 13`
        echo 'quit' | mysql -uroot -p${MYSQL_PWD} -e "source $f"
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

echo 'INSTALLER: Done running user-defined scripts'

echo "MYSQL PASSWORD FOR root@localhost: $MYSQL_PWD";

echo "INSTALLER: Installation complete, database ready to use!";
