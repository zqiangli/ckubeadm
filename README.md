# ckubeadm



## 1. 简介

ckubeadm基于kubeadm-v1.9.1源码构建，k8s组件镜像托管于腾讯云镜像仓库，解决国内使用kubeadm拉取镜像速度慢或无法访问的问题



## 2.依赖

#### 2.1 操作系统

> Ubuntu 16.04+，CentOS 7，2核2G主机以上，安装以下软件

```shell
# CentOS
yum install ebtables ethtool iproute iptables socat util-linux

# Ubuntu
apt-get install ebtables ethtool iproute iptables socat util-linux
```



#### 2.2 kubelet安装

```shell
# 下载kubelet
wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubelet-1.9.1-amd64.tgz

# 解压
tar -zxvf kubelet-1.9.1-amd64.tgz -C /usr/bin/

# 创建service
cat << EOF > /etc/systemd/system/kubelet.service
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=http://kubernetes.io/docs/

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 激活service
systemctl enable kubelet.service
```



#### 2.3 kubernetes-cni安装

```shell
# 下载kubernetes-cni
wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/cni-plugins-amd64-v0.6.0.tgz

# 解压
mkdir -p /opt/cni/bin
tar -zxvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin
```



#### 2.4 kubectl安装

```shell
# 下载kubectl
wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubectl-1.9.1-amd64.tgz

# 解压
tar -zxvf kubectl-1.9.1-amd64.tgz -C /usr/local/bin/
```



## 3. ckubeadm安装master

#### 3.1 创建kubeadm配置文件

```shell
# 创建kubeadm配置文件
mkdir -p /etc/systemd/system/kubelet.service.d
touch /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# 复制下面内容到10-kubeadm.conf文件中，注意修改cgroup参数与docker一致，使用docker info查看docker cgroup dirver
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
# Value should match Docker daemon settings.
# Defaults are "cgroupfs" for Debian/Ubuntu/OpenSUSE and "systemd" for Fedora/CentOS/RHEL
Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=systemd"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true"
Environment="KUBE_PAUSE=--pod-infra-container-image=ccr.ccs.tencentyun.com/k8s.io/pause-amd64:3.0"
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_CGROUP_ARGS $KUBELET_CADVISOR_ARGS $KUBELET_CERTIFICATE_ARGS $KUBE_PAUSE $KUBELET_EXTRA_ARGS

# 重新载入kubelet.service
systemctl daemon-reload
```

