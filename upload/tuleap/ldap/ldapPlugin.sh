#!/bin/bash

function customize_ldap_activedirectory {
        if [ -f '/etc/tuleap/plugins/ldap/etc/ActiveDirectory.inc' ]
        then 
        cp /etc/tuleap/plugins/ldap/etc/ActiveDirectory.inc /etc/tuleap/plugins/ldap/etc/ldap.inc && \
        sed -i -e "s|^\$sys_ldap_server\s=.*|\$sys_ldap_server = '$ldap_server';|"                     \
            -i -e "s/^\$sys_ldap_dn.*/\$sys_ldap_dn = '$ldap_dn';/"                                 \
            -i -e "s|^\//\$sys_ldap_bind_dn.*|\$sys_ldap_bind_dn = '$ldap_bind_dn';|"               \
            -i -e "s|^\//\$sys_ldap_bind_passwd.*|\$sys_ldap_bind_passwd = '$ldap_bind_passwd';|"   \
            -i -e "s/^\$sys_ldap_people_dn.*/\$sys_ldap_people_dn = '$ldap_people_dn';/"            \
            -i -e "s/^\$sys_ldap_grp_dn.*/\$sys_ldap_grp_dn = '$ldap_grp_dn';/" /etc/tuleap/plugins/ldap/etc/ldap.inc
        echo  "TULEAP: LDAP ActiveDirectory plugin properties file /etc/tuleap/plugins/ldap/etc/ldap.inc customized"
        else
        echo  "TULEAP: You should customize provided LDAP plugin properties file: /etc/tuleap/plugins/ldap/etc/ActiveDirectory.inc"
        fi   
}

function customize_ldap_openldap {
        if [ -f '/etc/tuleap/plugins/ldap/etc/OpenLDAP.inc' ]
        then 
        cp /etc/tuleap/plugins/ldap/etc/OpenLDAP.inc /etc/tuleap/plugins/ldap/etc/ldap.inc && \
        sed -i -e "s|^\$sys_ldap_server\s=.*|\$sys_ldap_server = '$ldap_server';|"                     \
            -i -e "s/^\$sys_ldap_dn.*/\$sys_ldap_dn = '$ldap_dn';/"                                 \
            -i -e "s|^\//\$sys_ldap_bind_dn.*|\$sys_ldap_bind_dn = '$ldap_bind_dn';|"               \
            -i -e "s|^\//\$sys_ldap_bind_passwd.*|\$sys_ldap_bind_passwd = '$ldap_bind_passwd';|"   \
            -i -e "s/^\$sys_ldap_people_dn.*/\$sys_ldap_people_dn = '$ldap_people_dn';/"            \
            -i -e "s/^\$sys_ldap_grp_dn.*/\$sys_ldap_grp_dn = '$ldap_grp_dn';/" /etc/tuleap/plugins/ldap/etc/ldap.inc
        echo  "TULEAP: LDAP OpenLDAP plugin properties file /etc/tuleap/plugins/ldap/etc/ldap.inc customized"
        else
        echo  "TULEAP: You should customize provided LDAP plugin properties file: /etc/tuleap/plugins/ldap/etc/OpenLDAP.inc"
        fi  
}


function enable_ldap {
if yum list installed tuleap-plugin-ldap >/dev/null 2>&1; then
# Enable LDAP plugin for Tuleap
su -l codendiadm -c "/usr/share/tuleap/src/utils/php-launcher.sh /usr/share/tuleap/tools/utils/admin/activate_plugin.php ldap" &&
echo  "TULEAP: Enable ldap plugin from php-launcher as codendiadm" &&
if [[ -d '/etc/tuleap/plugins/ldap/' ]]
then
jq -r '. | to_entries | .[] | .key + "=\"" + .value + "\""' /tmp/tuleap/ldap/ldap.json > /tmp/tuleap/ldap/ldapjson && source /tmp/tuleap/ldap/ldapjson
sed -i "s/_auth_type = 'codendi'/_auth_type = 'ldap'/" /etc/tuleap/conf/local.inc
case "$ldap_type" in
ActiveDirectory ) customize_ldap_activedirectory
;;
OpenLDAP ) customize_ldap_openldap
;;
esac
echo  "TULEAP: "\$sys_auth_type" variable in /etc/tuleap/conf/local.inc changed from codendi to ldap"

jq -r ".ldap_dn" < "/tmp/tuleap/ldap/ldap.json" > /tmp/tuleap/ldap/ldapdomain

sed -i -- 's/dc=/./g' /tmp/tuleap/ldap/ldapdomain

sed -i -- $'s/,//g' /tmp/tuleap/ldap/ldapdomain

sed -i -- 's/.//1' /tmp/tuleap/ldap/ldapdomain

ldap_domain=`cat /tmp/tuleap/ldap/ldapdomain`

echo  "TULEAP: LDAP $ldap_type Plugin Configured for domain: $ldap_domain"

else
echo  "TULEAP: $ldap_type Ldap Plugin not Configured :("
fi
else        
echo "TULEAP: $ldap_type Ldap Plugin not activated :("
fi
}

function install_ldap {
          # install the ldap RPM package
          if yum list installed tuleap-plugin-ldap >/dev/null 2>&1; then
                echo tuleap-plugin-ldap RPM already installed
          else
                yum install -y tuleap-plugin-ldap && \
                /usr/share/tuleap/tools/utils/php73/run.php --module=nginx && \
                systemctl reload nginx
          fi       
}


function check_ldap {
        ldap_type=$(jq -r ".ldap_type" < "/tmp/tuleap/ldap/ldap.json")
        if [[ ("$ldap_type" == "ActiveDirectory") || ("$ldap_type" == "OpenLDAP") ]]
        then
                echo  "TULEAP: $ldap_type LDAP plugin selected" && \
                jq -r '. | to_entries | .[] | .key + "=\"" + .value + "\""' /tmp/tuleap/ldap/ldap.json > /tmp/tuleap/ldap/ldapjson && source /tmp/tuleap/ldap/ldapjson
                install_ldap && \
                enable_ldap
        else
                echo  "TULEAP: Incorrect server type: '$ldap_type',  This can take one of two values 'OpenLDAP' or 'ActiveDirectory'."       
        fi
}


function load_json {

if [[ -z `jq -r '.ldap_type' /tmp/tuleap/ldap/ldap.json` ]]

then
        echo  "TULEAP: ldap_type empty, Please set a value /tmp/tuleap/ldap/ldap.json file"
        echo  "TULEAP: LDAP plugin not configured"
else    
        check_ldap 
fi

}

function check_json {

if [[ -f '/tmp/tuleap/ldap/ldap.json' ]]
then
echo "Loading Custom LDAP Properties"  
load_json
else
echo "Please copy ldap.json file into tmp directory to configure Ldap properly" 
fi 

}


if [[ -d '/etc/tuleap' ]]
        
then
        check_json
else
        echo  "TULEAP: Tuleap required to install LDAP plugin"
fi    