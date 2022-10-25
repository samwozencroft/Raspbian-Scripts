!/bin/bash

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

#Checking For elevated
# if [ $USER != root ]; then
# echo -e $RED"Error: must be root"
# echo -e $YELLOW"Exiting..."$ENDCOLOR
# exit 0
# fi

#Installing dependencies
echo -e $YELLOW"Installing dependencies..."$ENDCOLOR
sudo apt update -y && sudo apt upgrade -y
	#RPI Update
	sudo apt-get install net-snmp
  sudo systemctl enable snmpd
  sudo systemctl start snmpd
