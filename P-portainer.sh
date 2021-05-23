#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

#Install portainer
kubectl create namespace portainer
kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer.yaml
kubectl port-forward --address 0.0.0.0 svc/portainer 9001:9000 -n portainer
