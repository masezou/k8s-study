# k8s-study

This is sample KIND deployment. This project might not maintenance for now. 

<span style="font-size: 200%; color: red;">If you want to use this deployment, please use masezou/k8s-study-vanilla</span>

![image](https://user-images.githubusercontent.com/624501/126793662-60815904-cb7c-4897-a26c-cc6a684916dc.png)

![image](https://user-images.githubusercontent.com/624501/136640568-0594cdcf-667e-4b85-bd6c-885065ef2f7c.png)

# Features

Kind deployment on Linux and Windows. This includes metallb and dashboard.

# Requirement

-Ubuntu Linux Server 20.04.3 amd64 or arm64 4vCPU 16GB RAM 50GB above (Don't install any other extra packages) on vSphere VM.

If you are using ESX VM and you would like to test CNI, Loadbalancer, When you create VM, you can add VRAM, you can use Xwindow with high resolution.

![image](https://user-images.githubusercontent.com/624501/138623690-7a01b69b-b6ec-4f98-b178-055e649612ba.png)


-Windows 10 4vCPU 16GB RAM 50GB above
 - ubuntu Server 20.04 in MS Appstore 
 - Docker Desktop (https://hub.docker.com/editions/community/docker-ce-desktop-windows)
 - KIND (https://kind.sigs.k8s.io/docs/user/quick-start/)
 - external Minio / NFS Server (Option).

# Network Diagram
![Kind](https://user-images.githubusercontent.com/624501/140581204-673b5a2c-bd43-4260-b2ce-aef056d6b7dd.jpeg)


# Installation

Configure your clone with ssh key then git clone this.


# Usage (Linux)

* Linux
```bash
sudo -i
git clone https://github.com/masezou/k8s-study
cd k8s-study
./0-minio-lnx.sh ; ./1-buildk8s-lnx.sh ; ./2-tool.sh ; ./3-configk8s.sh ; ./4-csi-storage.sh ; ./5-desktop.sh
```

# Usage (Windows 10)

* Ubuntu on Windows 10 ... It is not tested well...
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

* Loadbalancer and ingress was configured but the magic is only in Kind/Docker network. You can play loadbalancer and ingress if you try to install desktop system. Easist way is executing P-desktop.sh.
* 0-minio-win.ps1, You need to edit administrator password in the script, before running the script.
* This environment is KIND environment. Metallb loadbalancer only affects to accessing from localhost. If you want to access from out of box. kubectl port-forward --address 0.0.0.0 service/hogehoge
* If you want use bitnami/helm, you may need to add "volumePermissions.enabled=true" because hostpath driver need to have root permission in PVC.
