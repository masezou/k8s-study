#!/usr/bin/env bash

# Install kubectl
if [ ! -f /usr/bin/kubectl ]; then
apt update
apt -y install docker.io apt-transport-https gnupg2 curl
systemctl enable --now docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
#apt -y install kubectl
apt-get install kubectl=1.19.11-00
kubectl completion bash >/etc/bash_completion.d/kubectl
source /etc/bash_completion.d/kubectl
echo 'export KUBE_EDITOR=vi' >>~/.bashrc
fi


SNAPSHOTTER_VERSION=v3.0.3

# Apply VolumeSnapshot CRDs
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

# Create Snapshot Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml

##Install the CSI Hostpath Driver
git clone https://github.com/kubernetes-csi/csi-driver-host-path.git  -b release-1.4
cd csi-driver-host-path
./deploy/kubernetes-1.18/deploy.sh
kubectl apply -f ./examples/csi-storageclass.yaml
kubectl patch storageclass standard \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass csi-hostpath-sc \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
cd ..
mv csi-driver-host-path csi-driver-host-path-`date "+%Y%m%d_%H%M%S"`
kubectl get sc

# NFS Storage 
apt -y install nfs-kernel-server
mkdir -p /nfsexport
cat << EOF >> /etc/exports
/nfsexport 192.168.0.0/16(rw,async,no_root_squash)
/nfsexport 172.16.0.0/12(rw,async,no_root_squash)
/nfsexport 10.0.0.0/8(rw,async,no_root_squash)
EOF
systemctl restart nfs-server
systemctl enable nfs-server
showmount -e

mkdir -p nfs-pv
cd nfs-pv

LOCALIPADDR=`ip -f inet -o addr show ens160 |cut -d\  -f 7 | cut -d/ -f 1`
cat << EOF > nfs-pv.yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    # - ReadWriteMany- Multiple node RW
    # - ReadWriteOnce - Single node RW)
    # - ReadOnlyMany - Multiple node R
    - ReadWriteMany
  persistentVolumeReclaimPolicy:
    # Retain data if pod was deleted
    Retain
  nfs:
    # NFS Server host and export
    path: /nfsexport
    server: ${LOCALIPADDR}
    readOnly: false
EOF

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=${LOCALIPADDR} \
    --set nfs.path=/nfsexport


echo ""
echo "*************************************************************************************"
echo "There is no more action. following your current storage class"
kubectl get storageclass
