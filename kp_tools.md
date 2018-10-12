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

  
