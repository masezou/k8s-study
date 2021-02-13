#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

kubectl port-forward --address 0.0.0.0 svc/portainer 9001:9000 -n portainer&
kubectl --namespace kasten-io port-forward --address 0.0.0.0 service/gateway 8080:8000 &
kubectl port-forward --address 0.0.0.0 svc/wordpress 80:80 -n wordpress &
kubectl -n kubedoom port-forward --address 0.0.0.0 deployment/kubedoom 5900:5900&


echo "https://your Kind host ip(Ubuntu IP)"
echo "https://your Kind host ip(Ubuntu IP):8080/k10/#/"
echo "connect hostIP:5900 with vncviewer"
