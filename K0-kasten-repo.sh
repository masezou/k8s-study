#!/usr/bin/env bash

### Install command check ####
if type "kubectl" > /dev/null 2>&1
then
    echo "kubectl was already installed"
else
    echo "kubectl was not found. Please install helm and re-run"
    exit 255
fi

if type "helm" > /dev/null 2>&1
then
    echo "helm was not found. Please install helm and re-run"
else
    echo "helm was not found"
    exit 255
fi

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

### ARCH Check ###
PARCH=`arch`
if [ ${PARCH} = aarch64 ]; then
  ARCH=arm64
  echo ${ARCH}
elif [ ${PARCH} = arm64 ]; then
  ARCH=arm64
  echo ${ARCH}
elif [ ${PARCH} = x86_64 ]; then
  ARCH=amd64
  echo ${ARCH}
else
  echo "${ARCH} platform is not supported"
  exit 1
fi

#########################################################

KASTENVER=4.5.2
docker run --rm -it gcr.io/kasten-images/k10offline:${KASTENVER} list-images
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
    gcr.io/kasten-images/k10offline:${KASTENVER} pull images
docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock \
    -v ${HOME}/.docker:/root/.docker \
    gcr.io/kasten-images/k10offline:${KASTENVER} pull images --newrepo localhost:5000

echo ""
echo "*************************************************************************************"
echo "Next Step"
