#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

kubectl get node
kind get clusters
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
 kind delete cluster --name k10-demo
 kind delete cluster --name k10-demo-dr
 kind get clusters
 rm -rf Your_kubeconfig
 rm -rf dashboard.token
 rm -rf k10-k10.token
 rm -rf /nfsexport/*
 echo "you can re-create cluster with 1-buildk8s.sh"
 ;;
  *) echo "abort";;
esac

