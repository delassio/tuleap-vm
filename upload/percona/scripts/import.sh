#!/bin/bash
#
# Description: Import user-defined dump for Oracle database software
# MAINTAINER: Oussama DELASSI

# Abort on any error
set -e

echo 'IMPORT DUMP: Started up'

# remove gitignore file from dump directory
rm -f /tmp/percona/dump/.gitignore
echo 'IMPORT DUMP: Cleanup gitignore file'

# run user-defined import dump scripts
echo 'IMPORT DUMP: Running import dump scripts'


# Retrive root password
passwd_file=/root/.percona_passwd
MYSQL_PWD=`sed '$!d' $passwd_file | tail -c 13`

# run user-defined post-setup, import scripts
echo 'IMPORT DUMP: Running user-defined scripts'

for f in /tmp/percona/dump/*
  do
    case "${f,,}" in
      *.sh)
        echo "IMPORT DUMP: Running $f"
        . "$f"
        echo "IMPORT DUMP: Done running $f"
        ;;
      *.sql)
        echo "IMPORT DUMP: Running $f"
        MYSQL_PWD=`sed '$!d' $passwd_file | tail -c 13`
        echo 'quit' | mysql -uroot -p${MYSQL_PWD} -e "source $f"
        echo "IMPORT DUMP: Done running $f"
        ;;
      /tmp/percona/dump/put_import_scripts_here.txt)
        :
        ;;
      *)
        echo "IMPORT DUMP: Ignoring $f"
        ;;
    esac
  done

echo 'IMPORT DUMP: import complete, database ready to use!'