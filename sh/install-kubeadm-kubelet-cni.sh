#!/bin/bash
KUBERNETES_VERSION=${KUBERNETES_VERSION:-"1.9.7"}
Ubuntu=$(cat /etc/*elease | grep VERSION_CODENAME)
CentOS=$(cat /etc/*elease | grep CENTOS_MANTISBT_PROJECT_VERSION)

# CentOS7+, Ubuntu16.04
function install() {
    if [[ ${Ubuntu##*=} =~ "xenial" ]]; then
        apt-get install -y wget
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubernetes-cni/kubernetes-cni_0.6.0-00_amd64.deb
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubelet/kubelet_${KUBERNETES_VERSION}-00_amd64.deb
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubeadm/kubeadm_${KUBERNETES_VERSION}-00_amd64.deb
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubectl/kubectl_${KUBERNETES_VERSION}-00_amd64.deb
        dpkg -i kubernetes-cni_0.6.0-00_amd64.deb kubelet_${KUBERNETES_VERSION}-00_amd64.deb kubeadm_${KUBERNETES_VERSION}-00_amd64.deb kubectl_${KUBERNETES_VERSION}-00_amd64.deb
        systemctl enable kubelet.service
    elif [[ ${CentOS##*=} =~ "7" ]]; then
        yum install -y wget
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubernetes-cni/kubernetes-cni-0.6.0-0.x86_64.rpm
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubelet/kubelet-${KUBERNETES_VERSION}-0.x86_64.rpm
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubeadm/kubeadm-${KUBERNETES_VERSION}-0.x86_64.rpm
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubectl/kubectl-${KUBERNETES_VERSION}-0.x86_64.rpm
        yum install -y kubernetes-cni-0.6.0-0.x86_64.rpm kubelet-${KUBERNETES_VERSION}-0.x86_64.rpm kubeadm-${KUBERNETES_VERSION}-0.x86_64.rpm kubectl-${KUBERNETES_VERSION}-0.x86_64.rpm
        systemctl enable kubelet.service
    else
        echo "The current operating system version is not supported."
    fi
}

install