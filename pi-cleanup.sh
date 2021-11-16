#!/bin/bash

#######################
#  pi-cleanup.sh
#  by sam wozencroft
#
#  version 1
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
sudo apt install aptitude -y
	#RPI Update
	sudo apt-get install git-core
	sudo wget http://goo.gl/1BOfJ -O /usr/bin/rpi-update && sudo chmod +x /usr/bin/rpi-update
##sudo shutdown -r now

if [ $USER != root ]; then
echo -e $RED"Error: must be root"
echo -e $YELLOW"Exiting..."$ENDCOLOR
exit 0
fi

#Removing Default pi user
sudo deluser --remove-home pi

 #Cleaning apt cache
echo -e $YELLOW"Cleaning apt cache..."$ENDCOLOR
aptitude clean

#Removing old #conf
echo -e $YELLOW"Removing old config files..."$ENDCOLOR
sudo aptitude purge $OLDCONF

 #Removing old Kernels
echo -e $YELLOW"Removing old kernels..."$ENDCOLOR
sudo aptitude purge $OLDKERNELS

 #Recycle
echo -e $YELLOW"Emptying every trashes..."$ENDCOLOR
rm -rf /home/*/.local/share/Trash/*/** &> /dev/null
rm -rf /root/.local/share/Trash/*/** &> /dev/null

#Removing unused packages
apt-get purge --auto-remove scratch debian-reference-en dillo idle3 python3-tk idle python-pygame python-tk lightdm gnome-themes-standard gnome-icon-theme raspberrypi-artwork gvfs-backends gvfs-fuse desktop-base lxpolkit netsurf-gtk zenity xdg-utils mupdf gtk2-engines alsa-utils  lxde lxtask menu-xdg gksu midori xserver-xorg xinit xserver-xorg-video-fbdev libraspberrypi-dev libraspberrypi-doc dbus-x11 libx11-6 libx11-data libx11-xcb1 x11-common x11-utils lxde-icon-theme gconf-service gconf2-common

#Apt Get Clean
sudo apt-get --yes autoremove
sudo apt-get --yes autoclean
sudo apt-get --yes clean

#GPIO Removal
#sudo apt-get purge python-rpi.gpio

#Prompt User for update
echo -e $YELLOW"Do you wish to install this program?"$ENDCOLOR
while true; do
    read -p "" yn
    case $yn in
        [Yy]* ) sudo apt update -y && apt upgrade -y;;
        [Nn]* )
        * )
    esac
done



echo -e $YELLOW"Script Finished... Please reboot device."$ENDCOLOR
