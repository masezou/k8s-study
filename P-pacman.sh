#!/usr/bin/env bash

### Install command check ####
if type "kubectl" > /dev/null 2>&1
then
    echo "kubectl was already installed"
else
    echo "kubectl was not found. Please install helm and re-run"
    exit 255
fi

#### LOCALIP #########
ip address show ens160 >/dev/null
retval=$?
if [ ${retval} -eq 0 ]; then
        LOCALIPADDR=`ip -f inet -o addr show ens160 |cut -d\  -f 7 | cut -d/ -f 1`
else
  ip address show ens192 >/dev/null
  retval2=$?
  if [ ${retval2} -eq 0 ]; then
        LOCALIPADDR=`ip -f inet -o addr show ens192 |cut -d\  -f 7 | cut -d/ -f 1`
  else
        LOCALIPADDR=`ip -f inet -o addr show eth0 |cut -d\  -f 7 | cut -d/ -f 1`
  fi
fi
echo ${LOCALIPADDR}

git clone --depth 1 git@github.com:saintdle/pacman-tanzu.git
cd pacman-tanzu/
bash ./pacman-install.sh
cd ..

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "kubectl -n pacman port-forward --address 0.0.0.0 svc/pacman 8082:80 &"
echo "http://${LOCALIPADDR}:8082"
echo ""

chmod -x P-pacman.sh
