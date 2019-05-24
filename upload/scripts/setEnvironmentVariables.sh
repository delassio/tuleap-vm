#!/bin/bash

# Check if the user supplied one argument.
if [[ $# -ne 3 ]]; then
  echo "Incorrect number of arguments!"
  echo "number of arguments: " $#
  #exit 1
fi
	# set environment variables
echo "export proxy=$1" >> /root/.bashrc && \
echo "export hostname=$2" >> /root/.bashrc && \
echo "export domainname=$3" >> /root/.bashrc   && \


echo 'INSTALLER: Environment variables set'