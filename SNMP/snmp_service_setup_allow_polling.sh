#!/bin/bash

#######################
#  snmp_service_setup_allow_polling.sh
#  by sam wozencroft
#
#  version 1.0
#######################

OLDCONF=$(dpkg -l|grep "^rc"|awk '{print $2}')
CURKERNEL=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
LINUXPKG="linux-(image|headers|ubuntu-modules|restricted-modules)"
METALINUXPKG="linux-(image|headers|restricted-modules)-(generic|i386|server|common|rt|xen)"
OLDKERNELS=$(dpkg -l|awk '{print $2}'|grep -E $LINUXPKG |grep -vE $METALINUXPKG|grep -v $CURKERNEL)
YELLOW="\033[1;33m"
RED="\033[0;31m"
ENDCOLOR="\033[0m"

#Installing dependencies
echo -e $YELLOW"Installing dependencies..."$ENDCOLOR
apt update -y && sudo apt upgrade -y
	#RPI Update
apt install snmpd -y 
systemctl enable snmpd
systemctl start snmpd
