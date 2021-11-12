#!/bin/bash

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
sudo apt install aptitude -y
 
if [ $USER != root ]; then
echo -e $RED"Error: must be root"
echo -e $YELLOW"Exiting..."$ENDCOLOR
exit 0
fi
 
echo -e $YELLOW"Cleaning apt cache..."$ENDCOLOR
aptitude clean
 
echo -e $YELLOW"Removing old config files..."$ENDCOLOR
sudo aptitude purge $OLDCONF
 
echo -e $YELLOW"Removing old kernels..."$ENDCOLOR
sudo aptitude purge $OLDKERNELS
 
echo -e $YELLOW"Emptying every trashes..."$ENDCOLOR
rm -rf /home/*/.local/share/Trash/*/** &> /dev/null
rm -rf /root/.local/share/Trash/*/** &> /dev/null

#Apt Get Clean
sudo apt-get --yes autoremove
sudo apt-get --yes autoclean
sudo apt-get --yes clean

#GPIO Removal
#sudo apt-get purge python-rpi.gpio

#Regening ssh keys
#sudo rm /etc/ssh/ssh_host_* && sudo dpkg-reconfigure openssh-server

#RPI Update
sudo apt-get install git-core
sudo wget http://goo.gl/1BOfJ -O /usr/bin/rpi-update && sudo chmod +x /usr/bin/rpi-update
sudo rpi-update
#sudo shutdown -r now
 
echo -e $YELLOW"Script Finished...Please reboot device"$ENDCOLOR