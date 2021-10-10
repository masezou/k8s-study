#!/usr/bin/env bash

PGNAMESPACE=postgresql-lb
helm repo update
kubectl create namespace ${PGNAMESPACE}
helm install --namespace ${PGNAMESPACE} postgres bitnami/postgresql --version 9.1.1 --set volumePermissions.enabled=true

kubectl --namespace ${PGNAMESPACE} annotate statefulset/postgres-postgresql \
    kanister.kasten.io/blueprint=postgres-bp
