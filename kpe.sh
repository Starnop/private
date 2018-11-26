#!/bin/bash

# This file allows you to init kuberenete master node with pouch containers available.
# Ubuntu and CentOS supported.

set -o errexit
set -o nounset

echo "----------------------------------"
echo "Whether to configure CNI config ?"
echo "(Y/y) Y"
echo "(N/n) N"
echo "(0) exit"
echo "----------------------------------"
read input
case $input in
	Y | y )
	CONFIG_CNI="true";;
	N | n)
	CONFIG_CNI="false";;
	0)
	exit;;
esac
echo "CONFIG_CNI:"$CONFIG_CNI

echo "----------------------------------"
echo "Is it the master node ?"
echo "(Y/y) Y"
echo "(N/n) N"
echo "(0) exit"
echo "----------------------------------"
read input
case $input in
	Y | y )
	MASTER_NODE="true";;
	N | n)
	MASTER_NODE="false";;
	0)
	exit;;
esac
echo "MASTER_NODE:"$MASTER_NODE

update_pouch="false"
cri_test="false"
e2e_test="false"
k8s_cluster="true"
e2e_focus="should report resource usage through the stats api"

KUBERNETES_VERSION="release-1.10"
KUBERNETES_VERSION_UBUNTU="1.10.2-00"
KUBERNETES_VERSION_CENTOS="1.10.2-0.x86_64"
MASTER_CIDR="10.244.0.0/16"
pouchd_log="pouchd.log"
pouch_github="https://github.com/alibaba/pouch.git"
pouch_github_branch="master"
cri_version="v1alpha2"
kubeadm_log="kubeadm.log"
cri_tools_rlease="1.10"
cri_shim="/var/run/pouchcri.sock"
cri_validation_log="crivalidation.log"


# preparation
install_tools_ubuntu() {
	apt-get update
	apt-get install -y wget
	apt-get install -y make
	apt-get install -y gcc
	apt-get install -y git  
	apt-get install -y socat      
}

install_tools(){
	yum -y install wget
	yum -y install make
	yum -y install gcc
	yum -y install git
}

# public

install_go(){
	wget  https://dl.google.com/go/go1.10.2.linux-amd64.tar.gz
	tar -C /usr/local -xzf go1.10.2.linux-amd64.tar.gz        
} 

setup_path(){
	export GOROOT=/usr/local/go
        export GOPATH=$HOME/gopath
        export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
        export PATH=$PATH:/usr/local/bin
}

install_ginkgo(){
	go get -u github.com/onsi/ginkgo/ginkgo
}

# update_pouch
stop_pouch(){
	COUNT=$(ps -ef |grep pouch |grep -v "grep" |wc -l)
	echo $COUNT
	if [ $COUNT -eq 0 ]; then
		echo NOT RUN
	else
		ps -ef | grep pouch | grep -v grep | awk '{print $2}' | xargs kill -9 
	fi        
}

# cri-tools validation
install_cri_tools(){
	wget https://github.com/kubernetes-incubator/cri-tools/releases/download/v1.0.0-beta.0/critest-v1.0.0-beta.0-linux-amd64.tar.gz
	sudo tar zxvf critest-v1.0.0-beta.0-linux-amd64.tar.gz -C /usr/local/bin
	rm -f critest-v1.0.0-beta.0-linux-amd64.tar.gz
}

download_cri_tools(){
	rm -rf /root/gopath/src/github.com/kubernetes-incubator/cri-tools
	git clone https://github.com/kubernetes-incubator/cri-tools -b release-$cri_tools_rlease $GOPATH/src/github.com/kubernetes-incubator/cri-tools
}

run_cri_validation(){
	cd
	critest --runtime-endpoint $cri_shim --image-endpoint $cri_shim > $cri_validation_log 2>&1 &
}

# e2e test
install_etcd(){
	wget https://github.com/coreos/etcd/releases/download/v3.3.5/etcd-v3.3.5-linux-amd64.tar.gz
	tar -xzvf etcd-v3.3.5-linux-amd64.tar.gz -C /usr/local
	export PATH=$PATH:/usr/local/etcd-v3.3.5-linux-amd64
}

get_kubernetes(){
	rm -rf $GOPATH/src/k8s.io/kubernetes
	go get k8s.io/kubernetes
}

start_e2e_test(){        
	cd $GOPATH/src/k8s.io/kubernetes/
	git checkout $KUBERNETES_VERSION
	make test-e2e-node RUNTIME=remote FOCUS="should report resource usage through the stats api" CONTAINER_RUNTIME_ENDPOINT=unix:///var/run/pouchcri.sock
}


install_containerd(){
	wget https://github.com/containerd/containerd/releases/download/v1.0.3/containerd-1.0.3.linux-amd64.tar.gz
	tar -xzvf containerd-1.0.3.linux-amd64.tar.gz -C /usr/local 
}

install_runc(){
	wget https://github.com/opencontainers/runc/releases/download/v1.0.0-rc4/runc.amd64 -P /usr/local/bin
	chmod +x /usr/local/bin/runc.amd64
	mv /usr/local/bin/runc.amd64 /usr/local/bin/runc
}



#pouch
install_pouch_source(){        
	mkdir -p $GOPATH/src/github.com/alibaba/
	cd $GOPATH/src/github.com/alibaba/
	rm -rf pouch
	git clone $pouch_github
	cd pouch
	git fetch --all
	git checkout $pouch_github_branch
	make build
	make install
	swapoff -a
	free -m
}

start_pouch(){
	cd
	systemctl daemon-reload
	pouchd --enable-cri --cri-version $cri_version > $pouchd_log  2>&1  &
	# pouchd --enable-cri --server-tls --tlskey server.key --tlscert server.crt --tlscacert ca.crt> pouchd.log  2>&1  &
}

#kubernetes
setup_repo_ubuntu(){
	apt-get update && apt-get install -y apt-transport-https
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
	cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
	apt-get update
}

install_kubelet_ubuntu() {        
	apt-get install -y kubelet=$KUBERNETES_VERSION_UBUNTU kubeadm=$KUBERNETES_VERSION_UBUNTU kubectl=$KUBERNETES_VERSION_UBUNTU
}

setup_repo_centos(){
	cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
	   https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
}

install_kubelet_centos() {        
	yum install -y kubelet-$KUBERNETES_VERSION_CENTOS kubeadm-$KUBERNETES_VERSION_CENTOS kubectl-$KUBERNETES_VERSION_CENTOS
	systemctl disable firewalld && systemctl stop firewalld
	systemctl enable kubelet
}

install_cni_ubuntu() {
	apt-get install -y kubernetes-cni
}

install_cni_centos() {
	setenforce 0
	yum install -y kubernetes-cni
}

config_kubelet() {
	cat > /etc/systemd/system/kubelet.service.d/0-pouch.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///var/run/pouchcri.sock --image-service-endpoint=unix:///var/run/pouchcri.sock"
EOF
	systemctl daemon-reload	
}

config_cni() {
	mkdir -p /etc/cni/net.d
	cat >/etc/cni/net.d/10-mynet.conf <<-EOF
{
	"cniVersion": "0.3.0",
	"name": "mynet",
	"type": "bridge",
	"bridge": "cni0",
	"isGateway": true,
	"ipMasq": true,
	"ipam": {
		"type": "host-local",
		"subnet": "10.244.1.0/24",
		"routes": [
			{ "dst": "0.0.0.0/0"  }
		]
	}
}
EOF
	cat >/etc/cni/net.d/99-loopback.conf <<-EOF
{
	"cniVersion": "0.3.0",
	"type": "loopback"
}
EOF
}

setup_master() {
	kubeadm init --ignore-preflight-errors=all        
	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config
	# enable schedule pods on the master node
	kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-
}

command_exists() {
		command -v "$@" > /dev/null 2>&1
}

lsb_dist=''
if command_exists lsb_release; then
	lsb_dist="$(lsb_release -si)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
	lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/centos-release ]; then
	lsb_dist='centos'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/redhat-release ]; then
	lsb_dist='redhat'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
	lsb_dist="$(. /etc/os-release && echo "$ID")"
fi

lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

case "$lsb_dist" in

	ubuntu)
		if $update_pouch; then
			stop_pouch
		else
			install_tools_ubuntu
			install_containerd
			install_runc
			install_go
		fi
		setup_path
		install_pouch_source
		start_pouch   
		if $e2e_test || $cri_test; then
			setup_repo_ubuntu 
			install_cni_ubuntu
			config_cni
			setup_path
			install_ginkgo 
		fi
		if $e2e_test; then
			install_etcd
			get_kubernetes
			start_e2e_test
		fi
		if $cri_test; then
			install_cri_tools              
			download_cri_tools
			run_cri_validation
		fi 
		if $k8s_cluster; then
			setup_repo_ubuntu            
			install_kubelet_ubuntu
			install_cni_ubuntu
			if $CONFIG_CNI; then
				config_cni
			fi
			config_kubelet        
			if $MASTER_NODE; then
			  setup_master
			fi 
		fi
	;;

	fedora|centos|redhat)
		if $update_pouch; then
			stop_pouch
		else
			install_tools
			install_containerd
			install_runc
			install_go
		fi
		setup_path
		install_pouch_source
		start_pouch
		if $e2e_test || $cri_test; then
			setup_repo_centos 
			install_cni_centos
			config_cni
			setup_path
			install_ginkgo 
		fi
		if $e2e_test; then
			install_etcd
			get_kubernetes
			start_e2e_test
		fi
		if $cri_test; then
			install_cri_tools              
			download_cri_tools
			run_cri_validation
		fi 
		if $k8s_cluster; then
			setup_repo_centos
			install_kubelet_centos
			install_cni_centos
			if $CONFIG_CNI; then
				config_cni
			fi
			config_kubelet  
			if $MASTER_NODE; then
			  setup_master
			fi     
		fi      
	;;

	*)
		echo "$lsb_dist is not supported (not in centos|ubuntu)"
	;;

esac


