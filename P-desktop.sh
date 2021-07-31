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

apt -y install open-vm-tools-desktop gnome-session gnome-terminal xserver-xorg-core xinit gnome-control-center fonts-takao fonts-ipafont fonts-ipaexfont firefox
#apt -y install ubuntu-desktop-minimal open-vm-tools-desktop
fc-cache -fv
apt clean
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl enable open-vm-tools.service
systemctl restart open-vm-tools.service
init 5
