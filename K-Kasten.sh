#!/usr/bin/env bash

# Install K10-tools
TOOLSVER=4.0.4
TOOLSARCH=amd64
if [ ! -f /usr/local/bin/k10tools ]; then
curl -OL https://github.com/kastenhq/external-tools/releases/download/${TOOLSVER}/k10tools_${TOOLSVER}_linux_${TOOLSARCH}
mv k10tools_${TOOLSVER}_linux_${TOOLSARCH} /usr/local/bin/k10tools
chmod +x /usr/local/bin/k10tools
fi

if [ ! -f /usr/local/bin/k10multicluster ]; then
curl -OL https://github.com/kastenhq/external-tools/releases/download/${TOOLSVER}/k10multicluster_${TOOLSVER}_linux_${TOOLSARCH}
mv k10multicluster_${TOOLSVER}_linux_${TOOLSARCH}  /usr/local/bin/k10multicluster
chmod +x /usr/local/bin/k10multicluster
fi

KUBESTRVER=0.4.17
if [ ! -f /usr/local/bin/kubestr ]; then
curl -OL https://github.com/kastenhq/kubestr/releases/download/v${KUBESTRVER}/kubestr-v${KUBESTRVER}-linux-${TOOLSARCH}.tar.gz
tar xfz kubestr-v${KUBESTRVER}-linux-${TOOLSARCH}.tar.gz
rm kubestr-v${KUBESTRVER}-linux-${TOOLSARCH}.tar.gz
mv kubestr /usr/local/bin/kubestr
chmod +x /usr/local/bin/kubestr
fi

# Install Kasten
helm repo add kasten https://charts.kasten.io/
helm repo update

kubectl annotate volumesnapshotclass csi-hostpath-snapclass \
    k10.kasten.io/is-snapshot-class=true

curl https://docs.kasten.io/tools/k10_primer.sh | bash
rm k10primer.yaml
kubectl create namespace kasten-io
#helm install k10 kasten/k10 --namespace=kasten-io --set injectKanisterSidecar.enabled=true
#helm install k10 kasten/k10 --namespace=kasten-io --set injectKanisterSidecar.enabled=true --set auth.tokenAuth.enabled=true
helm install k10 kasten/k10 --namespace=kasten-io --set injectKanisterSidecar.enabled=true --set auth.tokenAuth.enabled=true --set externalGateway.create=true --set ingress.create=true

echo "Following is login token"
sa_secret=$(kubectl get serviceaccount k10-k10 -o jsonpath="{.secrets[0].name}" --namespace kasten-io)
kubectl get secret $sa_secret --namespace kasten-io -ojsonpath="{.data.token}{'\n'}" | base64 --decode > k10-k10.token
echo "" >> k10-k10.token
cat k10-k10.token
echo
LOCALIPADDR=`ip -f inet -o addr show ens160 |cut -d\  -f 7 | cut -d/ -f 1`

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Confirm wordpress kasten is running with kubectl get pods --namespace kasten-io"
echo "prometheus-server may be backoff off, but it can be ignoree for now."
echo "kubectl --namespace kasten-io port-forward --address 0.0.0.0 service/gateway 8080:8000"
echo "Open your browser https://${LOCALIPADDR}:8080/k10/#/"
echo "or"
echo "kubectl --namespace kasten-io get svc"
echo "Open your browser https://External-IP/k10"
echo "then input login token"
