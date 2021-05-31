#!/usr/bin/env bash

NAMESPACE=wordpress-hostpath

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

kubectl get pod,pv,pvc -n ${NAMESPACE}
result=$?

echo
echo

read -p "Are you willing to delete? ok? (y/N): " yn
case "$yn" in
  [yY]*) 
 echo 
 echo 
 echo Wipeout.....
 echo 
 echo 
 kubectl delete all --all -n ${NAMESPACE}
 kubectl delete pvc mysql-pv-claim -n ${NAMESPACE}
 kubectl delete pvc wp-pv-claim -n ${NAMESPACE}
 kubectl get pod,pv,pvc -n ${NAMESPACE}
 ;;
  *) echo "abort";;
esac

