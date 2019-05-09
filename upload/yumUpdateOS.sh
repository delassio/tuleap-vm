#!/bin/bash

echo 'INSTALLER: Update OS...' && \

# get up to date
yum upgrade -y && \

echo 'INSTALLER: System updated' && \

# reboot to new kernel 
echo 'INSTALLER: System Reboot' && \

shutdown -r now