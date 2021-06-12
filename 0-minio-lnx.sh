#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi
LOCALHOSTNAME=`hostname`
LOCALIPADDR=`hostname -I | cut -d" " -f1`
MINIO_ROOT_USER=minioadminuser
MINIO_ROOT_PASSWORD=minioadminuser

if [ ! -f /usr/local/bin/minio ]; then
mkdir -p /minio/data{1..4}
chmod -R 755 /minio/data*
mkdir -p ~/.minio/certs
curl -OL https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio  /usr/local/bin/
cd || exit
fi

if [ ! -f /usr/local/bin/mc ]; then
curl -OL https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin/
echo "complete -C /usr/local/bin/mc mc" > /etc/bash_completion.d/mc.sh
mc >/dev/null
fi

if [ ! -f ~/.minio/certs/public.crt ]; then
openssl genrsa -out private.key 2048
cat <<EOF> openssl.conf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = VA
L = Somewhere
O = MyOrg
OU = MyOU
CN = MyServerName

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = ${LOCALIPADDR}
DNS.1 = ${LOCALHOSTNAME}
EOF
openssl req -new -x509 -nodes -days 730 -key private.key -out public.crt -config openssl.conf
mv key.pem private.key
mv cert.pem public.crt
chmod 600 public.crt
cp public.crt ~/.mc/certs/CAs/
cd || exit
fi

### add minio to systemctl
if [ ! -f /etc/systemd/system/minio.service ]; then

if [ ! -f /etc/default/minio ]; then
cat <<EOT > /etc/default/minio
# Volume to be used for MinIO server.
MINIO_VOLUMES="/minio/data1 /minio/data2 /minio/data3 /minio/data4"
# Use if you want to run MinIO on a custom port.
MINIO_OPTS="--address :9000"
# Access Key of the server.
MINIO_ROOT_USER=${MINIO_ROOT_USER}
# Secret key of the server.
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
EOT
fi

( cd /etc/systemd/system/ || return ; curl -O https://raw.githubusercontent.com/minio/minio-service/master/linux-systemd/minio.service )
sed -i -e 's/minio-user/root/g' /etc/systemd/system/minio.service
systemctl enable --now minio.service
systemctl status minio.service --no-pager
fi
sleep 3
mc alias rm local
MINIO_ENDPOINT=https://${LOCALIPADDR}:9000
mc alias set local ${MINIO_ENDPOINT} ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD} --api S3v4
mc admin info local/

echo ""
echo "*************************************************************************************"
echo "minio server is ${MINIO_ENDPOINT}"
echo "username: ${MINIO_ROOT_USER}"
echo "password: ${MINIO_ROOT_PASSWORD}"
echo "minio and mc was installed and configured successfully"
echo "Next Step"
echo "Execute in this console or re-login if you want to use mc completion"
echo "source /etc/profile"
echo "For Test:"
echo "mc mb --with-lock local/test01"
echo "mc ls local/"
