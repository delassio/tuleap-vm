#!/bin/bash

# Abort on any error
set -e

if [ -f /etc/centos-release  ] && [ `awk '{print $3}' /etc/centos-release` == 6.10  ]; then

echo 'Going to stop service network for reboot...'
service network stop

else

echo 'Going to stop network for reboot...'
systemctl stop network

fi


echo 'Going to reboot without updated system...'
sudo shutdown -r now