#!/usr/bin/env bash
NAMESPACE=wordpress-hostpath

kubectl create namespace ${NAMESPACE}
mkdir ${NAMESPACE}
cd  ${NAMESPACE}
cat <<EOF>wordpress-pv-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-pv-claim
  labels:
    app: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
EOF
cat <<EOF>mysql-pv-claim.yaml     
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
  labels:
    app: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
EOF
kubectl apply -f wordpress-pv-claim.yaml -n ${NAMESPACE}
kubectl apply -f mysql-pv-claim.yaml -n ${NAMESPACE}
kubectl get pvc -n ${NAMESPACE}
cat <<EOF> mysql-deployment.yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress
      tier: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress
        tier: mysql
    spec:
      containers:
      - image: mysql:5.6
        name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: password
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pv-claim
EOF
cat <<EOF> wordpress-deployment.yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress
      tier: frontend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress
        tier: frontend
    spec:
      containers:
      - image: wordpress:4.8-apache
        name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: wordpress-mysql
        - name: WORDPRESS_DB_PASSWORD
          value: password
        ports:
        - containerPort: 80
          name: wordpress
        volumeMounts:
        - name: wordpress-persistent-storage
          mountPath: /var/www/html
      volumes:
      - name: wordpress-persistent-storage
        persistentVolumeClaim:
          claimName: wp-pv-claim
EOF
kubectl apply -f mysql-deployment.yaml -n ${NAMESPACE}
kubectl apply -f wordpress-deployment.yaml -n ${NAMESPACE}
kubectl get pod -n ${NAMESPACE}
kubectl get deployment -n ${NAMESPACE}
cat <<EOF> mysql-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress-mysql
  labels:
    app: wordpress
spec:
  ports:
    - port: 3306
  selector:
    app: wordpress
    tier: mysql
EOF
cat <<EOF>wordpress-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  ports:
    - port: 80
  selector:
    app: wordpress
    tier: frontend
  type: LoadBalancer
EOF
kubectl apply -f mysql-service.yaml -n ${NAMESPACE}
kubectl apply -f wordpress-service.yaml  -n ${NAMESPACE}
kubectl get svc -n ${NAMESPACE}
cd ..
mv ${NAMESPACE} ${NAMESPACE}-`date "+%Y%m%d_%H%M%S"`

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Confirm wordpress pod and mysql pod are running with kubectl get pod -A"
echo "run kubectl -n ${NAMESPACE} get svc"
echo "Open your browser http://external ip)"
echo "You can test access with lynx  http://external ip)" 
echo "or"
echo "kubectl port-forward --address 0.0.0.0 svc/wordpress 8081:80 -n wordpress-hostpath"
echo "http://${LOCALIPADDR}:8081"


