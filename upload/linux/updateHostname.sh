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
/etc/init.d/network restart
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
/etc/init.d/network restart
sed -i "s/^HOSTNAME=.*/HOSTNAME=`echo $fqdn`/g" /etc/sysconfig/network
else
hostnamectl set-hostname $fqdn --static
fi
echo "INSTALLER: FQDN: "$fqdn" will be used."      
fi

if [ `awk '{print $3}' /etc/centos-release` = 6.10  ]; then
echo "INSTALLER: /etc/sysconfig/network: $(cat /etc/sysconfig/network)"
else
echo "INSTALLER: /etc/hostname: $(cat /etc/hostname)"
fi


echo $(hostname -I) $(hostname) $(hostname -s) > /etc/hosts


echo "INSTALLER: /etc/hosts: $(cat /etc/hosts)"