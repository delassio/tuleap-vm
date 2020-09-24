#!/bin/bash

# Abort on any error
set -e

# install NetworkManager To Fix Network ISSUE


if [ `awk '{print $3}' /etc/centos-release` = 6.10  ]; then

yum install -y NetworkManager

fi


echo "NetworkManager Installed..."