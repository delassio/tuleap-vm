#!/bin/bash


# get up to date


sudo yum -y upgrade

echo "System Updated..."

echo 'Going to reboot to get updated system...'

sudo shutdown -r now