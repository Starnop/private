# SETUP GOPATH
export GOROOT=/usr/local/go
export GOPATH=$HOME/gopath
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export PATH=$PATH:/usr/local/bin

# Kubeadm.conf
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
kubernetesVersion: 1.10.2
networking:
  podSubnet: 10.244.0.0/16
etcd:
  extraArgs:
    listen-peer-urls: http://127.0.0.1:2380


# bash completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "source <(helm completion bash)" >> ~/.bashrc

# kubeadm reset/init
kubeadm reset --ignore-preflight-errors=all --cri-socket=unix:///var/run/pouchcri.sock

kubeadm init --kubernetes-version=1.11.5 --ignore-preflight-errors=all --cri-socket=/var/run/pouchcri.sock --pod-network-cidr=10.244.0.0/16


# kubectl delete
NAMESPACE=default

kubectl get pods -n $NAMESPACE | grep Evicted | awk '{print $1}' | xargs kubectl delete pod -n $NAMESPACE
