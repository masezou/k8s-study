#!/usr/bin/env bash

MINIONAMESPACE=minio-demo

# Install Minio on Kubernetes
helm repo add minio https://helm.min.io/
helm repo update
kubectl create namespace ${MINIONAMESPACE}


# https://github.com/minio/charts
helm install --generate-name minio/minio --namespace=${MINIONAMESPACE} \
 --set accessKey=minioadminuser,secretKey=minioadminuser \
 --set persistence.size=100G \
 --set service.type=LoadBalancer \
 --set securityContext.enabled=false
SVCNAME=`kubectl -n ${MINIONAMESPACE} get service -o jsonpath='{.items[*].metadata.name}'`
#echo ${SVCNAME}

EXTERNALIP=`kubectl -n ${MINIONAMESPACE} get svc/${SVCNAME} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
ACCESS_KEY=$(kubectl get secret ${SVCNAME} --namespace ${MINIONAMESPACE} -o jsonpath="{.data.accesskey}" | base64 --decode)
SECRET_KEY=$(kubectl get secret ${SVCNAME} --namespace ${MINIONAMESPACE} -o jsonpath="{.data.secretkey}" | base64 --decode)

echo "External IP is ${EXTERNALIP}"
echo "Accesskey is ${ACCESS_KEY}"
echo "Secretkey is ${SECRET_KEY}"

kubectl -n ${MINIONAMESPACE} get pod
kubectl -n ${MINIONAMESPACE} get svc

mc alias set ${MINIONAMESPACE} http://${EXTERNALIP}:9000 "${ACCESS_KEY}" "${SECRET_KEY}" --api s3v4
mc admin info ${MINIONAMESPACE}

echo "Minio server  http://${EXTERNALIP}:9000"
echo "mc alias set ${MINIONAMESPACE} http://${EXTERNALIP}:9000 "$ACCESS_KEY" "$SECRET_KEY" --api s3v4"
echo "mc admin info ${MINIONAMESPACE}"
