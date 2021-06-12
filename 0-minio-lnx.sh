#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi


if [ ! -f /usr/local/bin/minio ]; then
mkdir -p /minio/data{1..4}
chmod -R 755 /minio/data{1..4}
mkdir -p ~/.minio/certs
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio  /usr/local/bin/
cd || exit
fi

if [ ! -f /usr/local/bin/mc ]; then
curl -OL https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin/
echo "complete -C /usr/local/bin/mc mc" > /etc/profile.d/mc.sh
mc >/dev/null
fi


if [ ! -f /usr/bin/go ]; then
apt -y install golang-go
export GOPATH=$HOME/go
echo "export GOPATH=$HOME/go" >>/etc/profile
echo "export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin" >>/etc/profile
export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin
#go get -u github.com/posener/complete/gocomplete
#$GOPATH/gocomplete -install -y  
cd || exit
fi

if [ -f ~/.minio/certs/public.crt ]; then
curl -s -o  generate_cert.go "https://golang.org/src/crypto/tls/generate_cert.go?m=text"
IPADDR=`hostname -I | cut -d" " -f1`
go run generate_cert.go -ca --host ${IPADDR}
rm generate_cert.go
mv cert.pem ~/.minio/certs/public.crt
chmod 600 ~/.minio/certs/public.crt
cp ~/.minio/certs/public.crt ~/.mc/certs/CAs/
mv key.pem ~/.minio/certs/private.key
chmod 600 ~/.minio/certs/private.key
cd || exit
fi

### add minio to systemctl
if [ ! -f /etc/systemd/system/minio.service ]; then

if [ ! -f /etc/default/minio ]; then
cat <<EOT > /etc/default/minio
# Volume to be used for MinIO server.
MINIO_VOLUMES="/minio/data{1-4}"
# Use if you want to run MinIO on a custom port.
MINIO_OPTS="--address :9000"
# Access Key of the server.
MINIO_ROOT_USER=minioadminuser
# Secret key of the server.
MINIO_ROOT_PASSWORD=KEY=minioadminuser
EOT
fi

( cd /etc/systemd/system/ || return ; curl -O https://raw.githubusercontent.com/minio/minio-service/master/linux-systemd/minio.service )
sed -i -e 's/minio-user/root/g' /etc/systemd/system/minio.service
systemctl enable --now minio.service
fi

systemctl status minio.service --no-pager
sleep 3
mc alias rm local
mc alias set local ${AWS_ENDPOINT} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} --api S3v4
mc admin info local/

echo ""
echo "*************************************************************************************"
echo "minio and bucket:backupkasten was created"
echo "Next Step"
echo "There is no action."
