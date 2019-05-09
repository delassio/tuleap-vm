#!/bin/bash

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


