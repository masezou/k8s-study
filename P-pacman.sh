#!/usr/bin/env bash

git clone git@github.com:saintdle/pacman-tanzu.git
cd pacman-tanzu/
bash ./pacman-install.sh
cd ..
chmod -x P-pacman.sh
