#!/usr/bin/env bash

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

#########################################################
BASEPWD=`pwd`

SNAPSHOTTER_VERSION=v4.1.1

# Apply VolumeSnapshot CRDs
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

# Create Snapshot Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml

##Install the CSI Hostpath Driver
git clone --depth 1 https://github.com/kubernetes-csi/csi-driver-host-path.git
cd csi-driver-host-path
./deploy/kubernetes-1.21/deploy.sh
kubectl apply -f ./examples/csi-storageclass.yaml
kubectl patch storageclass csi-hostpath-sc \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass standard \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
cd ..
mv csi-driver-host-path csi-driver-host-path-`date "+%Y%m%d_%H%M%S"`

kubectl get all -A
kubectl get sc
kubectl get VolumeSnapshotClass

echo ""
echo "*************************************************************************************"
echo "There is no more action. following your current storage class"
kubectl get storageclass

cd ${BASEPWD}
chmod -x ./4-csi-storage.sh
