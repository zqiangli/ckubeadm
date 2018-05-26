# ckubeadm

## 1. 简介

ckubeadm是开始是基于k8s-v1.9源码构建，从k8s-v1.9源码提取kubeadm，更改默认镜像仓库并重新编译

目前kubeadm支持通过配置文件imageRepository指定镜像仓库地址，ckubeadm不再进行开发。开发过程中同步了一些k8s官方的安装包和镜像，写了一些自动部署的脚本，以便快速部署k8s集群，目前仍可使用

本文档详细介绍使用kubadm部署k8s集群完整步骤



## 2.依赖

#### 2.1 操作系统

支持Ubuntu 16.04，CentOS 7+，amd64，master节点配置2核2G以上，安装以下软件包

```shell
# CentOS
yum install ebtables ethtool iproute iptables socat util-linux wget

# Ubuntu
apt-get install ebtables ethtool iproute iptables socat util-linux wget
```

#### 2.2 安装docker，docker版本小于等于17

```shell
# CentOS7安装docker-ce-17.03
wget -O - https://raw.githubusercontent.com/cherryleo/scripts/master/centos7-install-docker.sh | sh

# Ubuntu16.04安装docker-ce-17.03
wget -O - https://raw.githubusercontent.com/cherryleo/scripts/master/ubuntu16.04-install-docker.sh | sh
```

#### 2.3 系统设置

```shell
# 关闭swap
swapoff -a

# 关闭防火墙，如果不关防火墙，确保8080，6443，10250端口开放
systemctl disable firewalld
systemctl stop firewalld

# 修改网络参数
sysctl net.bridge.bridge-nf-call-iptables=1

# 设置环境变量，k8s安装版本，1.9.0-1.9.7
export KUBERNETES_VERSION="1.9.7"
```

#### 2.4 安装kubeadm

```shell
wget -O - https://raw.githubusercontent.com/cherryleo/ckubeadm/master/sh/install-kubeadm-kubelet-cni.sh | bash
```

#### 2.5 配置kubeadm

##### 2.5.1 查看docker cgroup driver

```Shell
docker info | grep -i cgroup
```

##### 2.5.2 修改kubeadm配置文件 

```shell
# 配置文件路径 /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# 替换下面内容到10-kubeadm.conf文件中，注意修改cgroup参数与docker一致
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
```
##### 2.5.3 重新载入kubelet 

```shell
systemctl daemon-reload
systemctl stop kubelet
```



## 3. kubeadm安装k8s集群

#### 3.1 安装k8s master节点

##### 3.1.1 配置文件

```shell
# 创建master config.yaml文件，<ip>改为本机IP地址
cat >config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
api:
    advertiseAddress: <ip>
networking:
    podSubnet: 10.244.0.0/16
apiServerCertSANs:
- <ip>
imageRepository: ccr.ccs.tencentyun.com/k8s.io
kubernetesVersion: v${KUBERNETES_VERSION}
EOF
```

##### 3.1.2 安装

```shell
# 执行安装
kubeadm init --config=config.yaml
```

##### 3.1.3 配置kubectl

```shell
# 安装成功后，创建kubectl配置文件
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

##### 3.1.4 安装插件

```shell
# 网络插件安装，此处flannel网络
kubectl apply -f https://raw.githubusercontent.com/cherryleo/ckubeadm/master/addons/flannel.yaml

# dashboard安装
kubectl apply -f https://raw.githubusercontent.com/cherryleo/ckubeadm/master/addons/kubernetes-dashboard.yaml
# 创建admin用户
kubectl apply -f https://raw.githubusercontent.com/cherryleo/ckubeadm/master/addons/admin-user.yaml
```

##### 3.1.5 查看集群状态

```
[root@10-255-0-196 ~]# kubectl get nodes
NAME           STATUS    ROLES     AGE       VERSION
10-255-0-196   Ready     master    47m       v1.9.7

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

##### 3.1.6 访问dashboard

访问https://ip:30080进入登陆页面

![](https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/pic/k8s-dashboard-login.png)

```shell
# 获取token
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

![](https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/pic/k8s-dashboard-token.png)

![](https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/pic/k8s-dashboard.png)

#### 3.2 node节点安装

##### 3.2.1 node节点初始化

执行第二大步骤，进行node节点初始化

##### 3.2.2 获取token

```shell
# 在mster节点执行
[root@10-255-0-196 ~]# kubeadm token create --print-join-command
kubeadm join --token fddd11.35180a3132aa60b6 10.255.0.196:6443 --discovery-token-ca-cert-hash sha256:3c88d7639604c94304274bfe741e70039909c63da4c9db30229e987d7f443f34
```

##### 3.2.3 配置文件

```shell
# 创建node config.yaml文件，需要修改以下参数
# discoveryTokenAPIServers: 3.2.2步骤输出的第5个字段，master的地址
# token: 3.2.2步骤输出的第4个字段
# discoveryTokenCACertHashes: 3.2.2步骤输出的最后一个字段
cat >config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1alpha1
kind: NodeConfiguration
discoveryTokenAPIServers:
    - 10.255.0.196:6443
token: fddd11.35180a3132aa60b6
discoveryTokenCACertHashes:
    - sha256:3c88d7639604c94304274bfe741e70039909c63da4c9db30229e987d7f443f34
imageRepository: ccr.ccs.tencentyun.com/k8s.io
EOF
```

##### 3.2.4 加入集群

```shell
kubeadm join --config=config.yaml --ignore-preflight-errors=Hostname
```

##### 3.2.5 查看集群状态

```
# 在master节点执行指令
[root@10-255-0-196 ~]# kubectl get nodes
NAME           STATUS    ROLES     AGE       VERSION
10-255-0-196   Ready     master    47m       v1.9.7
10-255-0-252   Ready     <none>    2m        v1.9.7

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
