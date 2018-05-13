# ckubeadm



## 1. 简介

ckubeadm基于kubeadm-v1.9.1源码构建，k8s组件镜像托管于腾讯云镜像仓库，解决国内使用kubeadm拉取镜像速度慢或无法访问的问题

本文档详细介绍使用ckubaadm部署k8s完整步骤

[k8s镜像及二进制文件下载地址](https://github.com/cherryleo/ckubeadm/blob/master/docs/镜像及二进制文件下载地址.md)



## 2.依赖

#### 2.1 操作系统

> Ubuntu 16.04+，CentOS 7，2核2G主机以上，安装以下软件

```shell
# CentOS
yum install ebtables ethtool iproute iptables socat util-linux

# Ubuntu
apt-get install ebtables ethtool iproute iptables socat util-linux
```



#### 2.2 安装kubelet，cni，kubectl

[自动安装kubelet，cni，kubctl脚本](https://github.com/cherryleo/ckubeadm/blob/master/docs/组件安装脚本.md)

```shell
# 下载自动安装脚本
wget https://raw.githubusercontent.com/cherryleo/ckubeadm/master/sh/ckubeadm_dependence.sh

# 执行安装脚本
sh ckubeadm_dependence.sh
```



## 3. ckubeadm安装k8s

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
Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=cgroupfs"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true"
Environment="KUBE_PAUSE=--pod-infra-container-image=ccr.ccs.tencentyun.com/k8s.io/pause-amd64:3.0"
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_CGROUP_ARGS $KUBELET_CADVISOR_ARGS $KUBELET_CERTIFICATE_ARGS $KUBE_PAUSE $KUBELET_EXTRA_ARGS

# 重新载入kubelet.service
systemctl daemon-reload
```



#### 3.2 安装ckubeadm

```shell
# 下载ckubeadm
wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/ckubeadm-1.9.1.tgz

# 解压ckubeadm
tar -zxvf ckubeadm-1.9.1.tgz -C /usr/local/bin
```



#### 3.3 系统设置

```shell
# 关闭swap
swapoff -a

# 关闭防火墙，如果不关防火墙，确保8080，6443，10250端口开放
systemctl disable firewalld
systemctl stop firewalld
```



#### 3.4 安装k8s

```shell
# 基础组件安装
ckubeadm init --pod-network-cidr=10.244.0.0/16

# 网络插件安装，此处flannel网络
sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f https://raw.githubusercontent.com/cherryleo/ckubeadm/master/addons/flannel.yaml
```



#### 3.5 查看集群状态

```
[root@centos7 ~]# kubectl get nodes
NAME          STATUS    ROLES     AGE       VERSION
k8s-centos7   Ready     master    5m        v1.9.1

[root@centos7 ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                  READY     STATUS    RESTARTS   AGE
kube-system   etcd-k8s-centos7                      1/1       Running   0          3m
kube-system   kube-apiserver-k8s-centos7            1/1       Running   2          4m
kube-system   kube-controller-manager-k8s-centos7   1/1       Running   0          4m
kube-system   kube-dns-7f5d7475f6-5gqv9             3/3       Running   0          3m
kube-system   kube-flannel-ds-h8927                 1/1       Running   0          3m
kube-system   kube-proxy-k7znq                      1/1       Running   0          3m
kube-system   kube-scheduler-k8s-centos7            1/1       Running   0          3m
```

