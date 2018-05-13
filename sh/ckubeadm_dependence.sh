# install ckubeadm dependence
KUBERNETES_VERSION="1.9.1"

# install kubelet and create kubelet.service
function install_kubelet() {
    # 下载kubelet
    wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubelet-${KUBERNETES_VERSION}-amd64.tgz
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
}

# install kubectl
function install_kubectl() {
    # 下载kubectl
    wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/kubectl-${KUBERNETES_VERSION}-amd64.tgz
    # 解压
    tar -zxvf kubectl-1.9.1-amd64.tgz -C /usr/local/bin/
}

# install kubernetes-cni
function install_cin() {
    # 下载kubernetes-cni
    wget https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com/cni-plugins-amd64-v0.6.0.tgz
    # 解压
    mkdir -p /opt/cni/bin
    tar -zxvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin
}

# master节点安装kubelet，kubectl，cni
# node节点安装kubele，cni
while true; do
    read -p "Is this node is master node?" yn
    case $yn in
        [Yy]* ) 
            install_kubelet;
            install_kubectl;
            install_cin;
            break;;
        [Nn]* ) 
            install_kubelet;
            install_cin;
            exit;;
        * ) echo "Please answer yes or no.";;
    esac
done 