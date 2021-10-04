#!/usr/bin/env bash


#Install blueprint

KANISTERVER=0.68.0

#    https://raw.githubusercontent.com/kanisterio/kanister/${KANISTERVER}/examples/stable/mongodb/blueprint-v2/mongo-blueprint.yaml
#    https://raw.githubusercontent.com/kanisterio/kanister/${KANISTERVER}/examples/stable/mysql/blueprint-v2/mysql-blueprint.yaml
#    https://raw.githubusercontent.com/kanisterio/kanister/${KANISTERVER}/examples/stable/postgresql/blueprint-v2/postgres-blueprint.yaml
kubectl --namespace kasten-io apply -f \
    https://raw.githubusercontent.com/kanisterio/kanister/master/examples/stable/mongodb/blueprint-v2/mongo-blueprint.yaml
kubectl --namespace kasten-io apply -f \
    https://raw.githubusercontent.com/kanisterio/kanister/master/examples/stable/mysql/blueprint-v2/mysql-blueprint.yaml
kubectl --namespace kasten-io apply -f \
    https://raw.githubusercontent.com/kanisterio/kanister/master/examples/stable/postgresql/blueprint-v2/postgres-blueprint.yaml
