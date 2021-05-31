# k8s-study

This is sample KIND deployment. This project might not maintenance for now.

# Features

Kind deployment on Linux and Windows. This includes metallb and dashboard.

# Requirement

Ubuntu Linux 20.04.2 or Windows 10 with ubuntu and docker.

# Installation

git clone this.



# Usage　（Linux)

* Linux
```bash
git clone https://github.com/masezou/k8s-study
cd k8s-study
./0-minio-lnx.sh ; ./1-buildk8s-lnx.sh ; ./2-tool.sh ; ./3-configk8s.sh ; ./4-nfs-storage.sh ; ./5-csi-storage.sh
```

# Usage　（Windows 10)

* Ubuntu on Windows 10
```bash
mkdir .kube
git clone git@github.com:masezou/k8s-study.git
cd k8s-study
cp 1-buildk8s-win.cmd /mnt/c/Users/[Username]/Desktop/
cp config.yml /mnt/c/Users/[Username]/Desktop/
```

Execute 1-buildk8s-win.cmd in Windows 10 native environment.

* Ubuntu on Windows 10
```bash
cp /mnt/c/Users/[Username]/.kube/config ~/.kube/
chmod -R go-wr ~/.kube
kubectl get node
cd k8s-study
./2-tool.sh ; ./3-configk8s.sh ; ./4-nfs-storage.sh ; ./5-csi-storage.sh
```

# Note

This environment is KIND environment. Metallb only affect localhost. If you want to access from out of box. kubectl port-forward --address 0.0.0.0 service/hogehoge
