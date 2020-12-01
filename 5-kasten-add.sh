#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

#MySQL
#kubectl --namespace kasten-io apply -f https://raw.githubusercontent.com/kanisterio/kanister/0.43.0/examples/stable/mysql/mysql-blueprint.yaml
wget https://raw.githubusercontent.com/kanisterio/kanister/0.43.0/examples/stable/mysql/mysql-blueprint.yaml
kubectl --namespace kasten-io apply -f mysql-blueprint.yaml
#Postgresql
kubectl --namespace kasten-io apply -f https://raw.githubusercontent.com/kanisterio/kanister/0.43.0/examples/stable/postgresql/postgres-blueprint.yamlk

