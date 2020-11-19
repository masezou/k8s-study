#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

cd
mkdir -p /minio/data
chown minio-user:minio-user /minio
mkdir -p ~/.mini/certso
cd /minio
if [ ! -f /usr/local/bin/minio ]; then
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio  /usr/local/bin/
fi
apt install -y golang-go
curl -o  generate_cert.go "https://golang.org/src/crypto/tls/generate_cert.go?m=text"
IPADDR=`hostname -I | cut -d" " -f1`
go run generate_cert.go -ca --host $IPADDR
unset IPADDR
mv cert.pem ~/.minio/certs/public.crt
mv key.pem ~/.minio/certs/private.key
cd

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "MINIO_ACCESS_KEY=minioadmin MINIO_SECRET_KEY=minioadmin /usr/local/bin/minio server /minio/data"

