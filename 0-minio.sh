#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

if [ ! -f /usr/local/bin/aws ]; then
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -s -o "awscliv2.zip"
apt update
apt -y install unzip
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
echo "complete -C '/usr/local/bin/aws_completer' aws">/etc/profile.d/awscli.sh
source /etc/bash_completion
cd
mkdir ~/.aws
cat <<'EOF' >>~/.aws/config
[profile minio]
region = us-east-1
output = json
EOF
cat <<'EOF' >>~/.aws/credentials
[minio]
aws_access_key_id= minioadmin
aws_secret_access_key= minioadmin
EOF
chmod 600 ~/.aws/*
cd
fi

if [ ! -f /usr/local/bin/minio ]; then
mkdir -p /minio/data
chown minio-user:minio-user /minio
mkdir -p ~/.minio/certs
cd /minio
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio  /usr/local/bin/
cd
fi

if [ ! -f /usr/bin/go ]; then
apt -y install golang-go
export GOPATH=$HOME/go
echo "export GOPATH=$HOME/go" >>/etc/profile
echo "export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin" >>/etc/profile
export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin
#go get -u github.com/posener/complete/gocomplete
#$GOPATH/gocomplete -install -y  
cd
fi

curl -s -o  generate_cert.go "https://golang.org/src/crypto/tls/generate_cert.go?m=text"
IPADDR=`hostname -I | cut -d" " -f1`
go run generate_cert.go -ca --host $IPADDR
rm generate_cert.go
unset IPADDR
mv cert.pem ~/.minio/certs/public.crt
chmod 600 ~/.minio/certs/public.crt
mv key.pem ~/.minio/certs/private.key
chmod 600 ~/.minio/certs/private.key
cd

### add minio to systemctl
if [ ! -f /etc/systemd/system/minio.service ]; then

if [ ! -f /etc/default/minio ]; then
cat <<EOT > /etc/default/minio
# Volume to be used for MinIO server.
MINIO_VOLUMES="/minio/data"
# Use if you want to run MinIO on a custom port.
MINIO_OPTS="--address :9000"
# Access Key of the server.
MINIO_ACCESS_KEY=minioadmin
# Secret key of the server.
MINIO_SECRET_KEY=minioadmin
EOT
fi

( cd /etc/systemd/system/; curl -O https://raw.githubusercontent.com/minio/minio-service/master/linux-systemd/minio.service )
sed -i -e 's/minio-user/root/g' /etc/systemd/system/minio.service
systemctl enable --now minio.service
#aws --profile minio --no-verify --endpoint-url https://localhost:9000 s3 mb s3://backupkasten
fi

systemctl status minio.service --no-pager
aws --profile minio --no-verify --endpoint-url https://localhost:9000 s3 ls

echo ""
echo "*************************************************************************************"
echo "minio and bucket:backupkasten was created"
echo "Next Step"
echo "There is no action."
