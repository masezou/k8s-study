#!/usr/bin/env bash

kubectl create namespace postgresql
helm install --namespace postgresql postgres bitnami/postgresql --version 10.4.2  --set volumePermissions.enabled=true
cat << EOF > postgresql-hooks.yaml
apiVersion: cr.kanister.io/v1alpha1
kind: Blueprint
metadata:
  name: postgresql-hooks
actions:
  backupPrehook:
    phases:
    - func: KubeExec
      name: makePGCheckPoint
      args:
        namespace: "{{ .StatefulSet.Namespace }}"
        pod: "{{ index .StatefulSet.Pods 0 }}"
        container: postgres-postgresql
        command:
        - bash
        - -o
        - errexit
        - -o
        - pipefail
        - -c
        - |
          PGPASSWORD=${POSTGRES_PASSWORD} psql -U $POSTGRES_USER -c "select pg_start_backup('app_cons');"
  backupPosthook:
    phases:
    - func: KubeExec
      name: afterPGBackup
      args:
        namespace: "{{ .StatefulSet.Namespace }}"
        pod: "{{ index .StatefulSet.Pods 0 }}"
        container: postgres-postgresql
        command:
        - bash
        - -o
        - errexit
        - -o
        - pipefail
        - -c
        - |
          PGPASSWORD=${POSTGRES_PASSWORD} psql -U $POSTGRES_USER -c "select pg_stop_backup();"
EOF
kubectl --namespace=kasten-io create -f postgresql-hooks.yaml
 kubectl annotate statefulset postgres-postgresql kanister.kasten.io/blueprint='postgresql-hooks' \
     --namespace=postgresql
