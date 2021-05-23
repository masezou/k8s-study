#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

git clone https://github.com/saintdle/pacman-tanzu.git
cd pacman-tanzu
bash ./pacman-install.sh
mv pacman-tanzu pacman-tanzu-`date "+%Y%m%d_%H%M%S"`
