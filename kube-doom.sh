git clone https://github.com/storax/kubedoom
cd kubedoom
kubectl apply -f manifest/
namespace/kubedoom created
deployment.apps/kubedoom created
serviceaccount/kubedoom created
clusterrolebinding.rbac.authorization.k8s.io/kubedoom created
mv kubedoom kubedoom-`date "+%Y%m%d_%H%M%S"`

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "kubectl -n kubedoom port-forward --address 0.0.0.0 deployment/kubedoom 5900:5900"
echo "connect hostIP:5900 with vncviewer"
echo "Password is idbehold"
