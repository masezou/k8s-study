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

#MINIOIP=192.168.1.130
#MINIOIP=192.168.10.4
#BUCKETNAME=kastenbackup-multi1
MINIOIP=${LOCALIPADDR}
BUCKETNAME=`hostname`

if [ ! -f /usr/local/bin/mc ]; then
curl -OL https://dl.min.io/client/mc/release/linux-${ARCH}/mc
mv mc /usr/local/bin/
chmod +x /usr/local/bin/mc
echo "complete -C /usr/local/bin/mc mc" > /etc/bash_completion.d/mc.sh
/usr/local/bin/mc >/dev/null
fi

mc alias rm local
MINIO_ENDPOINT=https://${MINIOIP}:9000
mc alias set local ${MINIO_ENDPOINT} minioadminuser minioadminuser --api S3v4

# Configure local minio setup
AWS_ACCESS_KEY_ID=` echo -n "minioadminuser" | base64`
AWS_SECRET_ACCESS_KEY_ID=` echo -n "minioadminuser" | base64`

cat << EOF | kubectl -n kasten-io create -f -
apiVersion: v1
data:
  aws_access_key_id: ${AWS_ACCESS_KEY_ID}
  aws_secret_access_key: ${AWS_SECRET_ACCESS_KEY_ID}
kind: Secret
metadata:
  name: k10-s3-secret
  namespace: kasten-io
type: secrets.kanister.io/aws
EOF
cat <<EOF | kubectl -n kasten-io create -f -
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
      name: ${BUCKETNAME}
      objectStoreType: S3
      endpoint: 'https://${MINIOIP}:9000'
      skipSSLVerify: true
      region: us-east-1
EOF
sleep 10
kubectl -n kasten-io get profiles.config.kio.kasten.io
echo ""
echo "Minio was configured"
echo ""

chmod -x ./K2-kasten-minio.sh
