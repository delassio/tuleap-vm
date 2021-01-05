#!/bin/bash
#
# Description: Import user-defined dump for Oracle database software
# MAINTAINER: Oussama DELASSI

# Abort on any error
set -e

echo 'IMPORT DUMP: Started up'

# remove gitignore file from dump directory
rm -f /home/oracle/datapump/.gitignore
echo 'IMPORT DUMP: Cleanup gitignore file'

# run user-defined import dump scripts
echo 'IMPORT DUMP: Running import dump scripts'

for f in /home/oracle/datapump/*
  do
    case "${f,,}" in
      *.sh)
        	if  [ "${f,,}" ==  "/home/oracle/datapump/import.sh" ] ; then
		      echo "IMPORT DUMP: Ignoring Nested Script $f"
        	else
        	echo "IMPORT DUMP: Running $f"
        	su -l oracle -c ". \"$f\""
        	echo "IMPORT DUMP: Done running $f"
        	fi
        ;;
      *.sql)
        echo "IMPORT DUMP: Running $f"
        su -l oracle -c "echo 'exit' | sqlplus -s / as sysdba @\"$f\""
        echo "IMPORT DUMP: Done running $f"
        ;;
      /home/oracle/datapump/put_import_scripts_here.txt)
        :
        ;;
      *)
        echo "IMPORT DUMP: Ignoring $f"
        ;;
    esac
  done
  
  
  echo "IMPORT DUMP: import complete, database ready to use!";