#!/usr/bin/env bash

MINIO_ROOT_USER=minioadminuser
MINIO_ROOT_PASSWORD=minioadminuser
MINIOSECRETKEY=miniosecretkey
LOCALHOSTNAME=`hostname`

#########################################################
### UID Check ###
if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

### Distribution Check ###
lsb_release -d | grep Ubuntu | grep 20.04
DISTVER=$?
if [ ${DISTVER} = 1 ]; then
    echo "only supports Ubuntu 20.04 server"
    exit 1
else
    echo "Ubuntu 20.04=OK"
fi

### ARCH Check ###
PARCH=`arch`
if [ ${PARCH} = aarch64 ]; then
  ARCH=arm64
  echo ${ARCH}
elif [ ${PARCH} = arm64 ]; then
  ARCH=arm64
  echo ${ARCH}
elif [ ${PARCH} = x86_64 ]; then
  ARCH=amd64
  echo ${ARCH}
else
  echo "${ARCH} platform is not supported"
  exit 1
fi

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

#########################################################

if [ ! -f /usr/local/bin/minio ]; then
mkdir -p /minio/data{1..4}
chmod -R 755 /minio/data*
mkdir -p ~/.minio/certs
curl -OL https://dl.min.io/server/minio/release/linux-${ARCH}/minio
mv minio  /usr/local/bin/
chmod +x /usr/local/bin/minio
fi

if [ ! -f /usr/local/bin/mc ]; then
curl -OL https://dl.min.io/client/mc/release/linux-${ARCH}/mc
mv mc /usr/local/bin/
chmod +x /usr/local/bin/mc
echo "complete -C /usr/local/bin/mc mc" > /etc/bash_completion.d/mc.sh
/usr/local/bin/mc >/dev/null
fi

if [ ! -f /root/.minio/certs/public.crt ]; then
cd /root/.minio/certs/
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
chmod 600 private.key
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
# Use Prometheus
MINIO_PROMETHEUS_AUTH_TYPE="public"
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

# Prometheus
 if [ ! -f /usr/local/prometheus/prometheus-server/prometheus-server ]; then
PROMETHEUSVER=2.28.0
mkdir -p /usr/local/prometheus
cd /usr/local/prometheus
curl -OL https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUSVER}/prometheus-${PROMETHEUSVER}.linux-${ARCH}.tar.gz
tar zxf prometheus-${PROMETHEUSVER}.linux-${ARCH}.tar.gz
mv prometheus-${PROMETHEUSVER}.linux-${ARCH} prometheus-server
cd prometheus-server
mv prometheus.yml prometheus.yml.org
cat << EOT > prometheus.yml
scrape_configs:
- job_name: minio-job
  metrics_path: /minio/v2/metrics/cluster
  scheme: https
  static_configs:
  - targets: ['${LOCALIPADDR}:9000']
  tls_config:
   insecure_skip_verify: true
EOT

cat << EOT > /usr/lib/systemd/system/prometheus.service
[Unit]
Description=Prometheus - Monitoring system and time series database
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/prometheus/prometheus-server/prometheus \
  --config.file=/usr/local/prometheus/prometheus-server/prometheus.yml \

[Install]
WantedBy=multi-user.target
EOT
systemctl enable --now prometheus.service
systemctl status prometheus.service --no-pager
fi


### Console install
if [ ! -f /usr/local/bin/console ]; then
curl -OL https://github.com/minio/console/releases/latest/download/console-linux-${ARCH}
mv console-linux-${ARCH}  /usr/local/bin/console
chmod +x /usr/local/bin/console
fi

echo -e "console\n${MINIOSECRETKEY}" | mc admin user add local/
cat > admin.json << EOF
{
	"Version": "2012-10-17",
	"Statement": [{
			"Action": [
				"admin:*"
			],
			"Effect": "Allow",
			"Sid": ""
		},
		{
			"Action": [
                "s3:*"
			],
			"Effect": "Allow",
			"Resource": [
				"arn:aws:s3:::*"
			],
			"Sid": ""
		}
	]
}
EOF
mc admin policy add local/ consoleAdmin admin.json
rm admin.json
mc admin policy set local/ consoleAdmin user=console

# For https connection
mkdir -p ~/.console/certs/CAs
cp -f ~/.minio/certs/public.crt ~/.console/certs/CAs

### add minio-console to systemctl
if [ ! -f /etc/systemd/system/minio-console.service ]; then

if [ ! -f /etc/default/minio-console ]; then
cat <<EOT >> /etc/default/minio-console
# Special opts
CONSOLE_OPTS="--port 9091"
# salt to encrypt JWT payload
CONSOLE_PBKDF_PASSPHRASE=SECRET
# required to encrypt JWT payload
CONSOLE_PBKDF_SALT=SECRET
# MinIO Endpoint
CONSOLE_MINIO_SERVER=https://${LOCALIPADDR}:9000
# Prometheus
CONSOLE_PROMETHEUS_URL=http://${LOCALIPADDR}:9090"
EOT
fi

( cd /etc/systemd/system/; curl -O https://raw.githubusercontent.com/minio/console/master/systemd/console.service )
sed -i -e 's/console-user/root/g' /etc/systemd/system/console.service
systemctl enable --now console.service
systemctl status console.service --no-pager
fi

echo ""
echo "*************************************************************************************"
echo "minio server is ${MINIO_ENDPOINT}"
echo "username: ${MINIO_ROOT_USER}"
echo "password: ${MINIO_ROOT_PASSWORD}"
echo "minio console is http://${LOCALIPADDR}:9091"
echo "Access key is console"
echo "Secret key is ${MINIOSECRETKEY}" 
echo "minio and mc was installed and configured successfully"
echo "Next Step"
echo "Execute in this console or re-login if you want to use mc completion"
echo "source /etc/bash_completion.d/mc.sh"
echo "For Test:"
echo "mc mb --with-lock local/test01"
echo "mc ls local/"
