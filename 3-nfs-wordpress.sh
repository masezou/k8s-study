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


mkdir wordpress-nfs
cd wordpress-nfs

kubectl create namespace wordpress-nfs
kubectl create secret generic mysql --from-literal=password=wordpress123@@@ -n wordpress-nfs

cat <<'EOF' > mysql-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
  labels:
    app: wordpress
    tier: mysql
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
kubectl get pvc
kubectl create -f mysql-pvc.yml -n wordpress-nfs
cat <<'EOF' > mysql.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - image: mysql:5.7
          name: mysql
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql
                  key: password
          ports:
            - containerPort: 3306
              name: mysql
          volumeMounts:
            - name: mysql-local-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-local-storage
          persistentVolumeClaim:
            claimName: mysql-pvc
EOF
kubectl create -f mysql.yml -n wordpress-nfs
kubectl get pod -l app=mysql -n wordpress-nfs
cat <<'EOF' > mysql-service.yml
apiVersion: v1
kind: Service
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  type: ClusterIP
  ports:
    - port: 3306
  selector:
    app: mysql
EOF
kubectl create -f mysql-service.yml -n wordpress-nfs
kubectl get service mysql -n wordpress-nfs


cat <<'EOF' > wordpress-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-pvc
  labels:
    app: wordpress
    tier: wordpress
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
kubectl create -f wordpress-pvc.yml -n wordpress-nfs
kubectl get pvc
cat <<'EOF' > wordpress.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
        - image: wordpress
          name: wordpress
          env:
          - name: WORDPRESS_DB_HOST
            value: mysql:3306
          - name: WORDPRESS_DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: mysql
                key: password
          ports:
            - containerPort: 80
              name: wordpress
          volumeMounts:
            - name: wordpress-local-storage
              mountPath: /var/www/html
      volumes:
        - name: wordpress-local-storage
          persistentVolumeClaim:
            claimName: wordpress-pvc
EOF
kubectl create -f wordpress.yml -n wordpress-nfs
kubectl get pod -l app=wordpress -n wordpress-nfs
cat <<'EOF' > wordpress-service.yml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: wordpress
  name: wordpress
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  selector:
    app: wordpress
EOF
apt -y install mysql-client
kubectl create -f wordpress-service.yml -n wordpress-nfs
kubectl get svc -l app=wordpress -n wordpress-nfs
kubectl get pod -n wordpress
cd ..
kubectl get pod,pvc -n wordpress-nfs
mv wordpress-nfs wordpress-nfs-`date "+%Y%m%d_%H%M%S"`
#apt-get install firefox firefox-locale-ja libgl1-mesa-glx

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Confirm wordpress pod and mysql pod are running with kubectl get pod -A"
echo "run kubectl port-forward --address 0.0.0.0 svc/wordpress 80:80 -n wordpress"
echo "Open your browser https://your Kind host ip(Ubuntu IP)"
