TULEAP VM Builder (VMware Workstation)
===============================

Welcome to the packer build for tuleap vm.  
This will build a Tuleap ALM and configure Active Directory for users login.  Follow the download instructions to download the software to install and follow the build instructions to build the machine.  You will need around 3 Gb of space free to store the downloads and run the build.
For getting accees to enterprise internet you can use px server that support  ntlm auth. 

There are several directories which are used in the build

1. put_files_here - place ALL downloaded software here (centos iso)
2. upload - ldap customization files (json file)
3. scripts - This directory has all the install scripts for the tuleap setup and ldap plugin avtivation.
4. px - px server for windows ntlm proxy    

Mandatory Downloads
-------------------
**These two downloads are mandatory**.  If they are not here, the build will not start.

* CentOS-7-x86_64-Minimal-1810.iso (needs to be this exactly md5 checked)

* Px programm px.exe for ntlm proxy

Build Instructions
------------------
run Tuleap.ink shortcut 

or from cmd prompt run>  pwsh.exe -ExecutionPolicy Bypass -command ".\Build-Tuleap.ps1"


Build Structure
--------------------
 to be done 
