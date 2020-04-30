#!/bin/bash


# get up to date


sudo yum -y upgrade

echo "System Updated..."

echo 'Going to reboot to get updated system...'

if [ -f /etc/centos-release  ]; then

if [ `awk '{print $3}' /etc/centos-release` == 6.10  ]; then

service network stop

fi

fi

sudo shutdown -r now