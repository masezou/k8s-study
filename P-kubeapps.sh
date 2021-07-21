#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create namespace kubeapps
helm install kubeapps --namespace kubeapps bitnami/kubeapps --set frontend.service.type=LoadBalancer
kubectl create --namespace default serviceaccount kubeapps-operator
kubectl create clusterrolebinding kubeapps-operator --clusterrole=cluster-admin --serviceaccount=default:kubeapps-operator
kubectl get secret $(kubectl get serviceaccount kubeapps-operator -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep kubeapps-operator-token) -o jsonpath='{.data.token}' -o go-template='{{.data.token | base64decode}}' > kubeapps.token
echo "" >>kubeapps.token
cat kubeapps.token
EXTERNALIP=`kkubectl -n kubeapps get service kubeapps | awk '{print $4}' | tail -n 1`
echo ""
echo "*************************************************************************************"
echo "Access http://${EXTERNALIP}/ from your local browser"
echo "or"
echo "kubectl port-forward -n kubeapps svc/kubeapps 8081:80"
echo "or"
echo "kubectl port-forward -n kubeapps --address 0.0.0.0 svc/kubeapps 8081:80"
