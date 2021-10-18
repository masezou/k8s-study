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

PGNAMESPACE=postgresql-lb
helm repo update
kubectl create namespace ${PGNAMESPACE}
helm install --namespace ${PGNAMESPACE} postgres bitnami/postgresql --version 9.1.1 --set volumePermissions.enabled=true

kubectl --namespace ${PGNAMESPACE} annotate statefulset/postgres-postgresql \
    kanister.kasten.io/blueprint=postgres-bp
