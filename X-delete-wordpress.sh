#!/usr/bin/env bash

kubectl get pod,pv,pvc -n wordpress
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
 kubectl delete all --all -n wordpress
 kubectl delete pvc mysql-pvc -n wordpress
 kubectl delete pvc wordpress-pvc -n wordpress
 kubectl get pod,pv,pvc -n wordpress
 ;;
  *) echo "abort";;
esac

