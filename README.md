# ckubeadm

## 1. 简介

ckubeadm是基于k8s-v1.9源码构建，从k8s-v1.9源码提取kubeadm，更改默认镜像仓库并重新编译，目的在于解决kubeadm访问gcr.io镜像仓库速度慢问题

目前kubeadm支持通过配置文件imageRepository指定镜像仓库地址，ckubeadm不再进行开发。开发过程中同步了一些k8s官方的安装包和镜像，写了一些自动部署的脚本，以便快速部署k8s集群，目前仍可使用



## 2. 基于kubeadm部署k8s集群

这篇文章详细介绍了使用kubeadm部署k8s集群的步骤，所有官方资源均有同步镜像，无需翻墙

https://cloud.tencent.com/developer/article/1136457

