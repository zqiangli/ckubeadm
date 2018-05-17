# ckubeadm



## 1. 简介

ckubeadm基于kubeadm-v1.9.1源码构建，k8s组件镜像托管于腾讯云镜像仓库，解决国内使用kubeadm拉取镜像速度慢或无法访问的问题

本文档详细介绍使用ckubaadm部署k8s集群完整步骤



## 2.依赖

#### 2.1 操作系统

Ubuntu 16.04+，CentOS 7+，master节点配置2核2G以上，安装以下软件包

```shell
# CentOS
yum install ebtables ethtool iproute iptables socat util-linux

# Ubuntu
apt-get install ebtables ethtool iproute iptables socat util-linux
```



#### 2.2 运行环境

安装docker，docker版本小于等于17

```shell
# CentOS7安装docker-ce-17.03
wget https://raw.githubusercontent.com/cherryleo/scripts/master/docker-centos7.sh

# 执行安装脚本
sh docker-centos7.sh
```



#### 2.3 安装kubelet，cni，kubectl

```shell
# 下载自动安装脚本
wget https://raw.githubusercontent.com/cherryleo/ckubeadm/master/sh/install-kubelet-kubectl-cni.sh

# 执行安装脚本
sh install-kubelet-kubectl-cni.sh
```



## 3. ckubeadm安装k8s集群

#### 3.1 创建kubeadm配置文件

```shell
# 创建kubeadm配置文件
mkdir -p /etc/systemd/system/kubelet.service.d
touch /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# 查看docker cgroup driver
docker info | grep -i cgroup

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

# 修改网络参数
sysctl net.bridge.bridge-nf-call-iptables=1
```



#### 3.4 安装k8s master节点

```shell
# 基础组件安装
ckubeadm init --pod-network-cidr=10.244.0.0/16

# 安装成功后，创建kubectl配置文件
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 网络插件安装，此处flannel网络
kubectl apply -f https://raw.githubusercontent.com/cherryleo/ckubeadm/master/addons/flannel.yaml
```



#### 3.5 查看集群状态

```
[root@10-255-0-196 ~]# kubectl get nodes
NAME           STATUS    ROLES     AGE       VERSION
10-255-0-196   Ready     master    47m       v1.9.1

[root@10-255-0-196 ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                   READY     STATUS    RESTARTS   AGE
kube-system   etcd-10-255-0-196                      1/1       Running   0          15m
kube-system   kube-apiserver-10-255-0-196            1/1       Running   0          15m
kube-system   kube-controller-manager-10-255-0-196   1/1       Running   0          15m
kube-system   kube-dns-7f5d7475f6-chfqz              3/3       Running   0          15m
kube-system   kube-flannel-ds-gjppn                  1/1       Running   0          10m
kube-system   kube-proxy-bbt6k                       1/1       Running   0          15m
kube-system   kube-scheduler-10-255-0-196            1/1       Running   0          15m
```



#### 3.6 node节点安装

```shell
# 在node节点执行3.1-3.3步骤

# 添加node节点到集群，集群token相关在master初始化成功后有显示
ckubeadm join --token 0bcee8.d432bc378d7eb6a1 10.255.0.196:6443 --discovery-token-ca-cert-hash sha256:48e4ad18e026d2bc7d7c990d618bbbda2026727d4f5e9991ed87be424d5af5be
```



#### 3.7 查看集群状态

```
[root@10-255-0-196 ~]# kubectl get nodes
NAME           STATUS    ROLES     AGE       VERSION
10-255-0-196   Ready     master    47m       v1.9.1
10-255-0-252   Ready     <none>    2m        v1.9.1

[root@10-255-0-196 ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                                   READY     STATUS    RESTARTS   AGE
kube-system   etcd-10-255-0-196                      1/1       Running   0          47m
kube-system   kube-apiserver-10-255-0-196            1/1       Running   0          46m
kube-system   kube-controller-manager-10-255-0-196   1/1       Running   0          47m
kube-system   kube-dns-7f5d7475f6-chfqz              3/3       Running   0          47m
kube-system   kube-flannel-ds-gjppn                  1/1       Running   0          42m
kube-system   kube-flannel-ds-qbxzg                  1/1       Running   2          2m
kube-system   kube-proxy-bbt6k                       1/1       Running   0          47m
kube-system   kube-proxy-j9pks                       1/1       Running   0          2m
kube-system   kube-scheduler-10-255-0-196            1/1       Running   0          47m
```



## 4. 相关文档

- [k8s镜像及二进制文件下载地址](https://github.com/cherryleo/ckubeadm/blob/master/docs/镜像及二进制文件下载地址.md)
- [kubelet，cni，kubctl安装脚本简介](https://github.com/cherryleo/ckubeadm/blob/master/docs/组件安装脚本.md)

