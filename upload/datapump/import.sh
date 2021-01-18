#!/bin/bash
#
# Description: Import user-defined dump for Oracle database software
# MAINTAINER: Oussama DELASSI

# Abort on any error
set -e

echo 'ORACLE DATAPUMP: Started up'

# remove gitignore file from dump directory
rm -f /home/oracle/datapump/.gitignore
echo 'ORACLE DATAPUMP: Cleanup gitignore file'

# run user-defined ORACLE DATAPUMP scripts
echo 'ORACLE DATAPUMP: Running ORACLE DATAPUMP scripts'

for f in /home/oracle/datapump/*
  do
    case "${f,,}" in
      *.sh)
        	if  [ "${f,,}" ==  "/home/oracle/datapump/import.sh" ] ; then
		      echo "ORACLE DATAPUMP: Ignoring Nested Script $f"
        	else
        	echo "ORACLE DATAPUMP: Running $f"
        	su -l oracle -c ". \"$f\""
        	echo "ORACLE DATAPUMP: Done running $f"
        	fi
        ;;
      *.sql)
        echo "ORACLE DATAPUMP: Running $f"
        su -l oracle -c "echo 'exit' | sqlplus -s / as sysdba @\"$f\""
        echo "ORACLE DATAPUMP: Done running $f"
        ;;
      /home/oracle/datapump/put_import_scripts_here.txt)
        :
        ;;
      *)
        echo "ORACLE DATAPUMP: Ignoring $f"
        ;;
    esac
  done
  
  
  echo "ORACLE DATAPUMP: import complete, database ready to use!";