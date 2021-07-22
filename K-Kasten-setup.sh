#!/usr/bin/env bash

#### LOCALIP #########
ip address show ens160 >/dev/null
retval=$?
if [ ${retval} -eq 0 ]; then
        LOCALIPADDR=`ip -f inet -o addr show ens160 |cut -d\  -f 7 | cut -d/ -f 1`
else
  ip address show ens192 >/dev/null
  retval2=$?
  if [ ${retval2} -eq 0 ]; then
        LOCALIPADDR=`ip -f inet -o addr show ens192 |cut -d\  -f 7 | cut -d/ -f 1`
  else
        LOCALIPADDR=`ip -f inet -o addr show eth0 |cut -d\  -f 7 | cut -d/ -f 1`
  fi
fi
echo ${LOCALIPADDR}

cat << EOF > minio-cred.yaml
apiVersion: v1
data:
  aws_access_key_id: bWluaW9hZG1pbnVzZXI=
  aws_secret_access_key: bWluaW9hZG1pbnVzZXI=
kind: Secret
metadata:
  name: k10-s3-secret
  namespace: kasten-io
type: secrets.kanister.io/aws
EOF
cat << EOF > minio-profile.yaml
apiVersion: config.kio.kasten.io/v1alpha1
kind: Profile
metadata:
  name: minio-profile
  namespace: kasten-io
spec:
  type: Location
  locationSpec:
    credential:
      secretType: AwsAccessKey
      secret:
        apiVersion: v1
        kind: Secret
        name: k10-s3-secret
        namespace: kasten-io
    type: ObjectStore
    objectStore:
      name: miniobucket
      objectStoreType: S3
      endpoint: 'https://${LOCALIPADDR}:9000'
      skipSSLVerify: true
      region: us-east-1
EOF
kubectl -n kasten-io create -f minio-cred.yaml
kubectl -n kasten-io create -f minio-profile.yaml
sleep 10
kubectl -n kasten-io get profiles.config.kio.kasten.io

