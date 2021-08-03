#!/usr/bin/env bash

PGNAMESPACE=postgresql-lb

kubectl create namespace ${PGNAMESPACE}
helm install --namespace ${PGNAMESPACE} postgres bitnami/postgresqli --version 9.0.0 --set volumePermissions.enabled=true
kubectl --namespace kasten-io apply -f \
    https://raw.githubusercontent.com/kanisterio/kanister/0.63.0/examples/stable/postgresql/blueprint-v2/postgres-blueprint.yaml
kubectl --namespace ${PGNAMESPACE} annotate statefulset/postgres-postgresql \
    kanister.kasten.io/blueprint=postgres-bp
