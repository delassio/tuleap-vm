#!/bin/bash

# Abort on any error
set -e

# set system time zone centos 6
if [ -f /etc/centos-release  ] && [ `awk '{print $3}' /etc/centos-release` == 6.10  ]; then

rm -f /etc/localtime
ln -s /usr/share/zoneinfo/$SYSTEM_TIMEZONE /etc/localtime
echo "LINUX INSTALLER: System time" `cat /etc/sysconfig/clock | grep ZONE=` `date +"%Z %z"`

else

# set system time zone centos 7
sudo timedatectl set-timezone $SYSTEM_TIMEZONE
echo "LINUX INSTALLER: System" `timedatectl | grep "Time zone"`

fi