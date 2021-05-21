# k8s-study
kubernates learning with single machine

These scriput is use KIND simple K8s environment. I have tested only Linux environment.

How to use....

Prepare following environment
Ubuntu 20.04.1 above amd64 with 2vCPU 8GB RAM 100GB HDD with Internet Connection

login ubuntu server

sudo -i

git clone this

run following scripts

0-minio.sh: Minio Object Storage environment (If you don't have object storage and starting minio with systemd)

1-buildk8s.sh: Building KIND cluster (This script will deploy single node KIND cluster)

2-storage.sh: Install CSI hostpath and dynamic nfs pvc environment  (This script will deploy CSI hostpath driver)

3-wordpress.sh: Deploy wordpress blog site to host path

3-nfs-wordpress.sh: Deploy wordpress blog site to nfs pv

4-kasten.sh: Deploy K10 run kubectl --namespace kasten-io port-forward --address 0.0.0.0 service/gateway 8080:8000&

S-service.sh: port-forearding wordpress and kasten.

kube-doom.sh: Doom on Kubernates.



Minio

 http://your Kind host ip(Ubuntu IP):9000

Portainer

http://your Kind host ip(Ubuntu IP):9001

Wordpress

http://your Kind host ip(Ubuntu IP)/

Kasten

https://your Kind host ip(Ubuntu IP):8080/k10/#/



Delete environment:

If you want to wipeout wordpress, run X-delete-wordpress.sh. 

If you want to delete KIND cluster, run Y-delete-kind-cluster.sh. You can re-start from 1-buildk8s.sh

Note:MySQL Application consistance is not supported in this branch for now.

