git clone https://github.com/storax/kubedoom
cd kubedoom
kubectl apply -f manifest/
cd ..
mv kubedoom kubedoom-`date "+%Y%m%d_%H%M%S"`

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "kubectl -n kubedoom port-forward --address 0.0.0.0 deployment/kubedoom 5900:5900"
echo "connect hostIP:5900 with vncviewer"
echo "Password is idbehold"
