#!/usr/bin/env bash

kubectl --namespace kasten-io apply -f \
    https://raw.githubusercontent.com/kanisterio/kanister/0.63.0/examples/stable/mysql/blueprint-v2/mysql-blueprint.yaml

#kubectl --namespace mysql annotate statefulset/mysql-release \
#    kanister.kasten.io/blueprint=mysql-blueprint
kubectl --namespace wordpress-hostpath annotate statefulset/mysql-release \
    kanister.kasten.io/blueprint=mysql-blueprint
