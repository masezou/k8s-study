#!/bin/bash

# Install Minio on Kubernetes
helm repo add minio https://helm.min.io/
helm repo update
kubectl create namespace minio-demo
helm install --generate-name minio/minio --namespace=minio-demo \
 --set accessKey=minioadminuser,secretKey=minioadminuser \
 --set service.type=LoadBalancer \
 --set securityContext.enabled=false

ACCESS_KEY=$(kubectl get secret minio-1627866259 --namespace minio-demo -o jsonpath="{.data.accesskey}" | base64 --decode) 
SECRET_KEY=$(kubectl get secret minio-1627866259 --namespace minio-demo -o jsonpath="{.data.secretkey}" | base64 --decode)
echo "Accesskey is ${ACCESS_KEY}"
echo "Secretkey is ${SECRET_KEY}"

kubectl -n minio-demo get pod
kubectl -n minio-demo get svc

echo "Minio server  http://<External-IP>:9000"
echo "mc alias set minio-demo http://172.18.255.202:9000 "$ACCESS_KEY" "$SECRET_KEY" --api s3v4"
echo "mc admin info minio-demo"
