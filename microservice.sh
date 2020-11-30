#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

# Install skaffold
if [ ! -f /usr/local/bin/skaffold ]; then
curl -Lo skaffold https://storage.googleapis.com/skaffold/builds/latest/skaffold-linux-amd64 && \
sudo install skaffold /usr/local/bin/
chmod +x /usr/local/bin/skaffold
skaffold completion bash > /etc/bash_completion.d/skaffold
fi

git clone https://github.com/GoogleCloudPlatform/microservices-demo.git -b release/v0.2.1 --depth 1
cd microservices-demo
kubectl create namespace microservice
skaffold -n microservice run

echo ""
echo "*************************************************************************************"
echo "If you faced error"
echo "re-run staffold run"
echo
echo "Next Step"
echo "kubectl port-forward --address 0.0.0.0 deployment/frontend 8081:8080"
echo "https://IPaddress:8081"
