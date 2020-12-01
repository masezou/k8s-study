# k8s-study
kubernates learning with single machine

(This is development tree....)

These scriput is use KIND simple K8s environment. I have tested only Linux environment.

How to use....

Prepare following environment
Ubuntu 20.04.1 amd64 with 2vCPU 8GB RAM 30GB HDD with Internet Connection

login ubuntu server

sudo -i

git clone this

run scripts 0-minio.sh: Minio Object Storage environment run MINIO_ACCESS_KEY=minioadmin MINIO_SECRET_KEY=minioadmin /usr/local/bin/minio server /minio/data&

1-buildk8s.sh: Building KIND cluster

2-storage.sh: Install CSI hostpath environment

3-wordpress.sh: Deploy wordpress blog site run kubectl port-forward --address 0.0.0.0 svc/wordpress 80:80 -n wordpres&

4-kasten.sh: Deploy K10 run kubectl --namespace kasten-io port-forward --address 0.0.0.0 service/gateway 8080:8000&

If you want to wipeout wordpress, run X-delete-wordpress.sh. If you want to delete KIND cluster, run Y-delete-kind-cluster.sh. You can re-start from 1-buildk8s.sh

Additional Note:
 multi-node.yaml: KIND configuration with 3 docker node. This release is deploy 3 node
 kube-doom.sh: Doom on Kind/Kubernates (https://github.com/storax/kubedoom)
 microservice.sh: Microservice demo site (https://github.com/GoogleCloudPlatform/microservices-demo/tree/release/v0.2.1)


Note: Application backup was implemented in mysqldump
