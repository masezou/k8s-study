#!/usr/bin/env bash

PGNAMESPACE=postgresql-app

kubectl create namespace ${PGNAMESPACE}
helm install --namespace ${PGNAMESPACE} postgres bitnami/postgresql --set volumePermissions.enabled=true

kubectl annotate statefulset postgres-postgresql kanister.kasten.io/blueprint='postgresql-hooks' \
     --namespace=${PGNAMESPACE}
