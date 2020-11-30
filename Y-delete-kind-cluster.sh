#!/usr/bin/env bash

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
 ;;
  *) echo "abort";;
esac

