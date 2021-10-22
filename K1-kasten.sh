#!/usr/bin/env bash

### Install command check ####
if type "kubectl" > /dev/null 2>&1
then
    echo "kubectl was already installed"
else
    echo "kubectl was not found. Please install helm and re-run"
    exit 255
fi

if type "helm" > /dev/null 2>&1
then
    echo "helm was not found. Please install helm and re-run"
else
    echo "helm was not found"
    exit 255
fi

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

# htpasswd for basic auth
apt -y install apache2-utils

# Install K10-tools
TOOLSVER=4.0.13
if [ ! -f /usr/local/bin/k10tools ]; then
curl -OL https://github.com/kastenhq/external-tools/releases/download/${TOOLSVER}/k10tools_${TOOLSVER}_linux_${ARCH}
mv k10tools_${TOOLSVER}_linux_${ARCH} /usr/local/bin/k10tools
chmod +x /usr/local/bin/k10tools
fi

if [ ! -f /usr/local/bin/k10multicluster ]; then
curl -OL https://github.com/kastenhq/external-tools/releases/download/${TOOLSVER}/k10multicluster_${TOOLSVER}_linux_${ARCH}
mv k10multicluster_${TOOLSVER}_linux_${ARCH}  /usr/local/bin/k10multicluster
chmod +x /usr/local/bin/k10multicluster
fi

if [ ${ARCH} = "amd64" ]; then
KUBESTRVER=0.4.23
if [ ! -f /usr/local/bin/kubestr ]; then
mkdir temp
cd temp
curl -OL https://github.com/kastenhq/kubestr/releases/download/v${KUBESTRVER}/kubestr-v${KUBESTRVER}-linux-${ARCH}.tar.gz
tar xfz kubestr-v${KUBESTRVER}-linux-${ARCH}.tar.gz
rm kubestr-v${KUBESTRVER}-linux-${ARCH}.tar.gz
mv kubestr /usr/local/bin/kubestr
chmod +x /usr/local/bin/kubestr
cd ..
rm -rf temp
fi

# Pre-req Kasten
helm repo add kasten https://charts.kasten.io/
helm repo update

kubectl get volumesnapshotclass | grep csi-hostpath-snapclass
retval2=$?
if [ ${retval2} -eq 0 ]; then
kubectl annotate volumesnapshotclass csi-hostpath-snapclass \
    k10.kasten.io/is-snapshot-class=true
fi

kubectl get volumesnapshotclass | grep csi-rbdplugin-snapclass
retval3=$?
if [ ${retval3} -eq 0 ]; then
kubectl annotate volumesnapshotclass csi-rbdplugin-snapclass \
    k10.kasten.io/is-snapshot-class=true
fi

curl https://docs.kasten.io/tools/k10_primer.sh | bash
rm k10primer.yaml

# Install Kasten
kubectl create namespace kasten-io
helm install k10 kasten/k10 --namespace=kasten-io \
--set services.securityContext.runAsUser=0 \
--set services.securityContext.fsGroup=0 \
--set prometheus.server.securityContext.runAsUser=0 \
--set prometheus.server.securityContext.runAsGroup=0 \
--set prometheus.server.securityContext.runAsNonRoot=false \
--set prometheus.server.securityContext.fsGroup=0 \
--set global.persistence.size=40G \
--set global.persistence.storageClass=csi-hostpath-sc \
##--set injectKanisterSidecar.enabled=true \
--set auth.tokenAuth.enabled=true \
--set externalGateway.create=true \
--set ingress.create=true

# define NFS storage
kubectl get sc | grep nfs-csi
retval7=$?
if [ ${retval7} -eq 0 ]; then
cat <<EOF | kubectl apply -n kasten-io -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
   name: kastennfspvc01
spec:
   storageClassName: nfs-csi
   accessModes:
      - ReadWriteMany
   resources:
      requests:
         storage: 20Gi
EOF
fi

echo "Following is login token"
sa_secret=$(kubectl get serviceaccount k10-k10 -o jsonpath="{.secrets[0].name}" --namespace kasten-io)
kubectl get secret $sa_secret --namespace kasten-io -ojsonpath="{.data.token}{'\n'}" | base64 --decode > k10-k10.token
echo "" >> k10-k10.token
cat k10-k10.token
echo

EXTERNALIP=`kubectl -n kasten-io get ingress | awk '{print $4}' | tail -n 1`

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Confirm kasten is running with kubectl get pods --namespace kasten-io"
echo "kubectl --namespace kasten-io port-forward --address 0.0.0.0 service/gateway 8080:8000"
echo "Open your browser http://${LOCALIPADDR}:8080/k10/#/"
echo "or"
echo "Open http://${EXTERNALIP}/K10/# from local browser"
echo "then input login token"
echo "Note:"
echo 

else
	echo "kubestr: ${ARCH} is not supported"
	echo "Kasten-io: ${ARCH} is not supported"
fi
