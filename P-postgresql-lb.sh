#!/usr/bin/env bash

PGNAMESPACE=postgresql-lb
helm repo update
kubectl create namespace ${PGNAMESPACE}
helm install --namespace ${PGNAMESPACE} postgres bitnami/postgresql --version 9.1.1 --set volumePermissions.enabled=true
kubectl --namespace kasten-io apply -f \
#    https://raw.githubusercontent.com/kanisterio/kanister/0.65.0/examples/stable/postgresql/blueprint-v2/postgres-blueprint.yaml
     https://raw.githubusercontent.com/kanisterio/kanister/master/examples/stable/postgresql/blueprint-v2/postgres-blueprint.yaml
kubectl --namespace ${PGNAMESPACE} annotate statefulset/postgres-postgresql \
    kanister.kasten.io/blueprint=postgres-bp
