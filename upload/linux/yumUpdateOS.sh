#!/bin/bash


# get up to date


sudo yum -y upgrade

echo "System Updated..."

echo 'Going to reboot to get updated system...'

if [ `awk '{print $3}' /etc/centos-release` = 6.10  ]; then

/etc/init.d/network stop


fi

sudo shutdown -r now