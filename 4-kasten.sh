#!/usr/bin/env bash

# Install kubectl
if [ ! -f /usr/bin/kubectl ]; then
apt update
apt -y install docker.io apt-transport-https gnupg2 curl
systemctl enable --now docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt update
#apt -y install kubectl
apt-get install kubectl=1.19.11-00
kubectl completion bash >/etc/bash_completion.d/kubectl
source /etc/bash_completion.d/kubectl
echo 'export KUBE_EDITOR=vi' >>~/.bashrc
fi

# Install Helm
if [ ! -f /usr/local/bin/helm ]; then
curl -O https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
bash ./get-helm-3
helm version
fi
# Install K10-tools
TOOLSVER=4.0.2
TOOLSARCH=linux_amd64
if [ ! -f /usr/local/bin/k10tools ]; then
curl -OL https://github.com/kastenhq/external-tools/releases/download/${TOOLSVER}/k10multicluster_${TOOLSVER}_${TOOLSARCH}
mv k10tools_${TOOLSVER}_${TOOLSARCH} /usr/local/bin/k10tools
chmod +x /usr/local/bin/k10tools
fi

if [ ! -f /usr/local/bin/k10multicluster ]; then
curl -OL https://github.com/kastenhq/external-tools/releases/download/${TOOLSVER}/k10tools_${TOOLSVER}_${TOOLSARCH}
mv k10multicluster_${TOOLSVER}_${TOOLSARCH}  /usr/local/bin/k10multicluster
chmod +x /usr/local/bin/k10multicluster
fi

KUBESTRVER=0.4.16
if [ ! -f /usr/local/bin/kubestr ]; then
curl -OL https://github.com/kastenhq/kubestr/releases/download/v${KUBESTRVER}/kubestr-v${KUBESTRVER}-${TOOLSARCH}.tar.gz
tar xfz kubestr-v${KUBESTRVER}-${TOOLSARCH}.tar.gz
rm kubestr-v${KUBESTRVER}-${TOOLSARCH}.tar.gz
mv kubestr /usr/local/bin/kubestr
chmod +x /usr/local/bin/kubestr
fi

# Install Kasten
helm repo add kasten https://charts.kasten.io/
helm repo update

kubectl annotate volumesnapshotclass csi-hostpath-snapclass \
    k10.kasten.io/is-snapshot-class=true

curl https://docs.kasten.io/tools/k10_primer.sh | bash
rm k10primer.yaml
kubectl create namespace kasten-io
helm install k10 kasten/k10 --namespace=kasten-io --set injectKanisterSidecar.enabled=true

# define NFS storage
apt -y install nfs-common
cat <<'EOF'> nfs-pv.yml
apiVersion: v1
kind: PersistentVolume
metadata:
   name: test-pv
spec:
   capacity:
      storage: 10Gi
   volumeMode: Filesystem
   accessModes:
      - ReadWriteMany
   persistentVolumeReclaimPolicy: Recycle
   storageClassName: nfs
   mountOptions:
      - hard
      - nfsvers=4.0
   nfs:
      path: /Share/kasten_nfs
      server: 192.168.10.4
EOF
#kubectl apply -f nfs-pv.yml

cat <<'EOF'> nfs-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
   name: test-pvc
spec:
   storageClassName: nfs
   accessModes:
      - ReadWriteMany
   resources:
      requests:
         storage: 10Gi
EOF
#kubectl apply -f nfs-pvc.yml

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Confirm wordpress kasten is running with kubectl get pods --namespace kasten-io"
echo "kubectl --namespace kasten-io port-forward --address 0.0.0.0 service/gateway 8080:8000"
echo "Open your browser https://your Kind host ip(Ubuntu IP):8080/k10/#/"
