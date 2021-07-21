# k8s-study

This is sample KIND deployment. This project might not maintenance for now.

# Features

Kind deployment on Linux and Windows. This includes metallb and dashboard.

# Requirement

-Ubuntu Linux Server  20.04.2 4vCPU 8GB RAM 50GB above (Don't install any other extra packages) on vSphere

If you are using ESX VM and you would like to test CNI,Loadbalancer, Ingress, you can install Xwindow with desktop.sh. When you create VM, you can add VRAM, you can use Xwindow with high resolution.

-Windows 10 4vCPU 16GB RAM 50GB above
 - ubuntu Server 20.04 in MS Appstore 
 - Docker Desktop (https://hub.docker.com/editions/community/docker-ce-desktop-windows)
 - KIND (https://kind.sigs.k8s.io/docs/user/quick-start/)
 - external Minio / NFS Server (Option).

# Installation

git clone this.


# Usage (Linux)

* Linux
```bash
sudo -i
git clone https://github.com/masezou/k8s-study
cd k8s-study
./0-minio-lnx.sh ; ./1-buildk8s-lnx.sh ; ./2-tool.sh ; ./3-configk8s.sh ; ./4-csi-storage.sh
```

# Usage (Windows 10)

* Ubuntu on Windows 10
```bash
sudo -i
mkdir .kube
git clone git@github.com:masezou/k8s-study.git
cd k8s-study
cp 1-buildk8s-win.cmd /mnt/c/Users/[Username]/Desktop/
cp config.yml /mnt/c/Users/[Username]/Desktop/
```

Execute 1-buildk8s-win.cmd in Windows 10 native environment.

* Ubuntu on Windows 10

You need to modify NFSSVR/NFSPATH in ./4-nfs-storage.sh 

```bash
sudo -i
cp /mnt/c/Users/[Username]/.kube/config ~/.kube/
chmod -R go-wr ~/.kube
kubectl get node
cd k8s-study
sudo ./2-tool.sh
./3-configk8s.sh
./4-csi-storage.sh
````

# Note

* 0-minio-win.ps1, You need to edit administrator password in the script, before running the script.
* This environment is KIND environment. Metallb loadbalancer only affects to localhost. If you want to access from out of box. kubectl port-forward --address 0.0.0.0 service/hogehoge
