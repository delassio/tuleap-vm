#!/bin/bash


function checkProxySSL {


# Check proxy connectivity 
until [[ $(curl -x $proxy -I --silent -o /dev/null -w %{http_code} http://www.httpvshttps.com) = 200  ]] ;do
    printf '.'
    sleep 5
done
#Verify if ssl yum curl 60 error exist in
# yum check-update -e 0 --quiet or curl -x $myproxy $myurl
if [[ $(curl -x $proxy https://www.httpvshttps.com 2>&1 | grep -c 60) = 1 ]]
then
echo "sslverify=false" >> /etc/yum.conf
# or yum-config-manager --save --setopt=*.sslverify=false
echo 'INSTALLER: SSL verification disabled for yum.conf'
else
echo 'INSTALLER: yum verify SSL OK'
fi
}

function disableYumOption {

if [ -f /etc/centos-release  ]; then

    echo 'INSTALLER: Disable yum fatestmirror plugin, mirrorlist' && \

    sed -i -e "s|enabled=1|enabled=0|"  /etc/yum/pluginconf.d/fastestmirror.conf

    sed -i -e "s|mirrorlist=|#mirrorlist=|"  /etc/yum.repos.d/CentOS-Base.repo

    sed -i -e "s|#baseurl=|baseurl=|"  /etc/yum.repos.d/CentOS-Base.repo
fi

}

function configYumProxy {
# set proxy configuration 
if [[ -n "$proxy" ]]
then
echo "proxy="$proxy >> /etc/yum.conf
echo "INSTALLER: Proxy settings: "$proxy" will be used for yum.conf."
checkProxySSL
disableYumOption
else
echo "INSTALLER: No Proxy settings will be used for yum.conf."     
fi    
}

configYumProxy