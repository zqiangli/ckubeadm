#!/bin/bash
# kubernetes version
KUBERNETES_VERSION="1.9.0"
ROLE="master"
Ubuntu=$(cat /etc/*elease | grep VERSION_CODENAME)
CentOS=$(cat /etc/*elease | grep CENTOS_MANTISBT_PROJECT_VERSION)

# entOS7+, Ubuntu16.04
function install() {
    if [[ ${Ubuntu##*=} =~ "xenial" ]]; then
        apt-get install -y wget
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubernetes-cni/kubernetes-cni_0.6.0-00_amd64.deb
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubelet/kubelet_${KUBERNETES_VERSION}-00_amd64.deb

        if [ "${ROLE}" = 'master' ]; then
            wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubectl/kubectl_${KUBERNETES_VERSION}-00_amd64.deb
            dpkg -i kubectl_${KUBERNETES_VERSION}-00_amd64.deb
        fi
        dpkg -i kubernetes-cni_0.6.0-00_amd64.deb kubelet_${KUBERNETES_VERSION}-00_amd64.deb
        systemctl enable kubelet.service
    elif [[ ${CentOS##*=} =~ "7" ]]; then
        yum install -y wget
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubernetes-cni/kubernetes-cni-0.6.0-0.x86_64.rpm
        wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubelet/kubelet-${KUBERNETES_VERSION}-0.x86_64.rpm

        if [ "${ROLE}" = 'master' ]; then
            wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubectl/kubectl-${KUBERNETES_VERSION}-0.x86_64.rpm
            yum install -y kubectl-${KUBERNETES_VERSION}-0.x86_64.rpm
        fi
        yum install -y kubernetes-cni-0.6.0-0.x86_64.rpm kubelet-${KUBERNETES_VERSION}-0.x86_64.rpm
        systemctl enable kubelet.service
    else
        echo "The current operating system version is not supported."
    fi
}

PS3='Select kubernetes version: '
options=(
    "1.9.0"
    "1.9.1"
    "1.9.2"
    "1.9.3"
    "1.9.4"
    "1.9.5"
    "1.9.6"
    "1.9.7"
)
select opt in "${options[@]}"
do
    case $opt in
        "1.9.0")
            KUBERNETES_VERSION="1.9.0"
            echo $KUBERNETES_VERSION
            break
            ;;
        "1.9.1")
            KUBERNETES_VERSION="1.9.1"
            echo $KUBERNETES_VERSION
            break
            ;;
        "1.9.2")
            KUBERNETES_VERSION="1.9.2"
            echo $KUBERNETES_VERSION
            break
            ;;
        "1.9.3")
            KUBERNETES_VERSION="1.9.3"
            echo $KUBERNETES_VERSION
            break
            ;;
        "1.9.4")
            KUBERNETES_VERSION="1.9.4"
            echo $KUBERNETES_VERSION
            break
            ;;
        "1.9.5")
            KUBERNETES_VERSION="1.9.5"
            echo $KUBERNETES_VERSION
            break
            ;;
        "1.9.6")
            KUBERNETES_VERSION="1.9.6"
            echo $KUBERNETES_VERSION
            break
            ;;
        "1.9.7")
            KUBERNETES_VERSION="1.9.7"
            echo $KUBERNETES_VERSION
            break
            ;;
        *) echo invalid option;;
    esac
done

while true; do
    read -p "Is this node master node? (y/n)" yn
    case $yn in
        [Yy]* ) 
            install
            break;;
        [Nn]* )
            ROLE="node"
            install
            exit;;
        * ) echo "Please answer yes or no.";;
    esac
done 