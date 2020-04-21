#!/bin/bash

if [ -z "$hostname" ] 
then
hostname="localhost"
fi
if [ -z "$domainname" ] 
then
fqdn="$hostname.localdomain"
if [ `awk '{print $3}' /etc/centos-release` = 6.10  ]; then
hostname $fqdn
sed -i "s/^HOSTNAME=.*/HOSTNAME=`echo $fqdn`/g" /etc/sysconfig/network
else
hostnamectl set-hostname $fqdn --static
fi
echo "INSTALLER: FQDN: "$fqdn" will be used."
elif [ -n "$domainname" ]
then
fqdn="$hostname.$domainname"
if [ `awk '{print $3}' /etc/centos-release` = 6.10  ]; then
hostname $fqdn
sed -i "s/^HOSTNAME=.*/HOSTNAME=`echo $fqdn`/g" /etc/sysconfig/network
else
hostnamectl set-hostname $fqdn --static
fi
echo "INSTALLER: FQDN: "$fqdn" will be used."      
fi

if [ `awk '{print $3}' /etc/centos-release` = 6.10  ]; then
echo "INSTALLER: /etc/sysconfig/network: $(cat /etc/sysconfig/network)"
echo $(hostname -I) $(hostname) $(hostname -s) > /etc/hosts
else
echo "INSTALLER: /etc/hostname: $(cat /etc/hostname)"
echo $(hostname -I) $(hostname -f) $(hostname -s) > /etc/hosts
fi


echo "INSTALLER: /etc/hosts: $(cat /etc/hosts)"