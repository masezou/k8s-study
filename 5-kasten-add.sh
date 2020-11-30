
#MySQL
#kubectl --namespace kasten-io apply -f https://raw.githubusercontent.com/kanisterio/kanister/0.43.0/examples/stable/mysql/mysql-blueprint.yaml
wget https://raw.githubusercontent.com/kanisterio/kanister/0.43.0/examples/stable/mysql/mysql-blueprint.yaml
kubectl --namespace kasten-io apply -f mysql-blueprint.yaml
#Postgresql
kubectl --namespace kasten-io apply -f https://raw.githubusercontent.com/kanisterio/kanister/0.43.0/examples/stable/postgresql/postgres-blueprint.yamlk

