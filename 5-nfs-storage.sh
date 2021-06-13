#!/usr/bin/env bash

#NFSSVR=192.168.10.4
NFSSVR=`ip -f inet -o addr show ens160 |cut -d\  -f 7 | cut -d/ -f 1`
#NFSPATH=/k8s_sharedyn
NFSPATH=/nfsexport

# NFS Storage
apt -y install nfs-kernel-server
mkdir -p /nfsexport
chmod -R 777 /nfsexport
cat << EOF >> /etc/exports
/nfsexport 192.168.0.0/16(rw,async,no_root_squash)
/nfsexport 172.16.0.0/12(rw,async,no_root_squash)
/nfsexport 10.0.0.0/8(rw,async,no_root_squash)
EOF
systemctl restart nfs-server
systemctl enable nfs-server
showmount -e

#helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
#helm repo update
#helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
#    --set nfs.server=${NFSSVR} \
#    --set nfs.path=${NFSPATH}
#kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl create -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/example/nfs-provisioner/nfs-server.yaml
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/install-driver.sh | bash -s master --
wget  https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/example/storageclass-nfs.yaml
sed -i -e "s/nfs-server.default.svc.cluster.local/${NFSSVR}/g" storageclass-nfs.yaml
sed -i -e "s@share: /@share: ${NFSPATH}@g" storageclass-nfs.yaml
kubectl create -f storageclass-nfs.yaml
kubectl patch storageclass nfs-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl -n kube-system get pod -o wide -l app=csi-nfs-controller
kubectl -n kube-system get pod -o wide -l app=csi-nfs-node

# How to change default storage class from csi-hostpath-sc to nfs-client
# kubectl patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
# kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
# kubectl get sc

kubectl get all -A
kubectl get sc
#kubectl get VolumeSnapshotClass

echo ""
echo "*************************************************************************************"
echo "There is no more action. following your current storage class"
kubectl get storageclass
echo "NFS storage was configurd"

