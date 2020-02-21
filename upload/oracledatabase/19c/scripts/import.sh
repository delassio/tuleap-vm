#!/bin/bash
#
# Description: Import user-defined dump for Oracle database software
# MAINTAINER: Oussama DELASSI

# Abort on any error
set -e

# remove hidden file from dump directory
rm -rf /tmp/dump/.*
echo 'IMPORT: Cleanup dump directory'

# run user-defined import dump scripts
echo 'IMPORT: Running import dump scripts'

for f in /tmp/dump/*
  do
    case "${f,,}" in
      *.sh)
        echo "IMPORT: Running $f"
        su -l oracle -c ". \"$f\""
        echo "IMPORT: Done running $f"
        ;;
      *.sql)
        echo "IMPORT: Running $f"
        su -l oracle -c "echo 'exit' | sqlplus -s / as sysdba @\"$f\""
        echo "IMPORT: Done running $f"
        ;;
      /tmp/dump/put_import_scripts_here.txt)
        :
        ;;
      *)
        echo "IMPORT: Ignoring $f"
        ;;
    esac
  done