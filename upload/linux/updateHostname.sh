#!/bin/bash

if [ -z "$hostname" ]; then

hostname="localhost"
echo "INSTALLER: Empty hostname Variable : localhost will be used."

fi

if [ -z "$domainname" ]; then

fqdn="$hostname.localdomain"

if [ -f /etc/centos-release  ] && [ `awk '{print $3}' /etc/centos-release` == 6.10  ]; then
hostname $fqdn
sed -i "s/^HOSTNAME=.*/HOSTNAME=`echo $fqdn`/g" /etc/sysconfig/network
echo "INSTALLER(CentOS 6): FQDN : "$fqdn" will be used."
else
hostnamectl set-hostname $fqdn --static
sudo systemctl restart systemd-hostnamed
echo "INSTALLER: FQDN: "$fqdn" will be used."
fi


elif [ -n "$domainname" ]; then

fqdn="$hostname.$domainname"

if [ -f /etc/centos-release  ] && [ `awk '{print $3}' /etc/centos-release` == 6.10  ]; then
hostname $fqdn
sed -i "s/^HOSTNAME=.*/HOSTNAME=`echo $fqdn`/g" /etc/sysconfig/network
echo "INSTALLER(CentOS 6): FQDN : "$fqdn" will be used."
else
hostnamectl set-hostname $fqdn --static
sudo systemctl restart systemd-hostnamed
echo "INSTALLER: FQDN: "$fqdn" will be used."    
fi

  
fi

if [ -f /etc/centos-release  ] && [ `awk '{print $3}' /etc/centos-release` == 6.10  ]; then
echo "INSTALLER(CentOS 6): /etc/sysconfig/network: $(cat /etc/sysconfig/network)"
echo $(hostname -I) $(hostname) $(hostname -s) > /etc/hosts
echo "INSTALLER(CentOS 6): /etc/hosts: $(cat /etc/hosts)"
else
echo "INSTALLER: /etc/hostname: $(cat /etc/hostname)"
echo $(hostname -I) $(hostname) $(hostname -s) > /etc/hosts
echo "INSTALLER: /etc/hosts: $(cat /etc/hosts)"
fi