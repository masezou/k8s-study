#!/usr/bin/env bash

NAMESPACE=wordpress

#kubectl --namespace mysql annotate statefulset/mysql-release \
#    kanister.kasten.io/blueprint=mysql-blueprint
kubectl --namespace ${NAMESPACE} annotate statefulset/mysql-release \
    kanister.kasten.io/blueprint=mysql-blueprint
