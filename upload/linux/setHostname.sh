#!/bin/bash

if [ -z "$hostname" ] 
then
hostname="localhost"
fi
if [ -z "$domainname" ] 
then
fqdn="$hostname.localdomain"
hostnamectl set-hostname $fqdn
echo "INSTALLER: FQDN: "$fqdn" will be used."
# /etc/init.d/network restart
elif [ -n "$domainname" ]
then
fqdn="$hostname.$domainname"
hostnamectl set-hostname $fqdn
echo "INSTALLER: FQDN: "$fqdn" will be used."      
fi

echo "HOSTNAME="$(hostname -A) > /etc/sysconfig/network
echo $(hostname -I) $(hostname -A) $(hostname -s) > /etc/hosts


echo "INSTALLER: /etc/hosts: $(cat /etc/hosts)" 


echo "INSTALLER: /etc/hostname: $(cat /etc/hostname)"


echo "INSTALLER: /etc/sysconfig/network: $(cat /etc/sysconfig/network)"  
