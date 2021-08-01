#!/usr/bin/env bash

#########################################################
### UID Check ###
if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

### Distribution Check ###
lsb_release -d | grep Ubuntu | grep 20.04
DISTVER=$?
if [ ${DISTVER} = 1 ]; then
    echo "only supports Ubuntu 20.04 server"
    exit 1
else
    echo "Ubuntu 20.04=OK"
fi


lspci | grep VGA |grep VMware >/dev/null
retvalvga=$?

if [ ${retvalvga} -eq 0 ]; then
 # VMware VM
 apt -y --no-install-recommends install xinit gdm3 xserver-xorg-video-vmware gnome-session gnome-terminal gnome-control-center fonts-takao fonts-ipafont fonts-ipaexfont firefox
 echo "VMware VGA was configgured"
else
# Non VMware
 apt -y install xinit
 apt -y --no-install-recommends install gnome-session gnome-terminal gnome-control-center fonts-takao fonts-ipafont fonts-ipaexfont firefox
 systemctl disable NetworkManager
 systemctl stop NetworkManager
 echo "NON-VMware VGA was configgured"
fi
fc-cache -fv
apt -y install open-vm-tools-desktop
apt clean
systemctl enable open-vm-tools.service
systemctl restart open-vm-tools.service
init 5
