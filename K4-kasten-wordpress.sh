#!/usr/bin/env bash

#    https://raw.githubusercontent.com/kanisterio/kanister/0.65.0/examples/stable/mysql/blueprint-v2/mysql-blueprint.yaml
kubectl --namespace kasten-io apply -f \
     https://raw.githubusercontent.com/kanisterio/kanister/master/examples/stable/mysql/blueprint-v2/mysql-blueprint.yaml

#kubectl --namespace mysql annotate statefulset/mysql-release \
#    kanister.kasten.io/blueprint=mysql-blueprint
kubectl --namespace wordpress annotate statefulset/mysql-release \
    kanister.kasten.io/blueprint=mysql-blueprint
