package dependence

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"

	kubeadmapi "github.com/cherryleo/ckubeadm/app/apis/kubeadm"
)

const (
	// FileServer offer binary file download
	FileServer = "https://fileserver-1253732882.cos.ap-chongqing.myqcloud.com"
	// BinPath binary execute path
	BinPath = "/usr/local/bin"
	// CniPath kubernetes-cni binary path
	CniPath = "/opt/cni/bin"
)

// InstallKubelet download kubelet and create kubelet sercice
func InstallKubelet(cfg *kubeadmapi.MasterConfiguration) error {
	if err := installKube("kubelet", cfg.KubernetesVersion); err != nil {
		return fmt.Errorf("failed to install kubelet: %v", err)
	}

	kubeletService := []byte(`[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=http://kubernetes.io/docs/

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target`)
	if err := ioutil.WriteFile("/etc/systemd/system/kubelet.servic", kubeletService, 0755); err != nil {
		return fmt.Errorf("failed to write kubelet.service: %v", err)
	}

	return nil
}

// InstallKubectl download kubectl
func InstallKubectl(cfg *kubeadmapi.MasterConfiguration) error {
	if err := installKube("kubectl", cfg.KubernetesVersion); err != nil {
		return fmt.Errorf("failed to install kubectl: %v", err)
	}

	return nil
}

// InstallCni download kubernetes-cni and install it
func InstallCni() error {
	fileName := "cni-plugins-amd64-v0.6.0.tgz"
	if err := os.MkdirAll(CniPath, 755); err != nil {
		return fmt.Errorf("failed to create directory %q: %v", CniPath, err)
	}
	filePath := CniPath + "/" + fileName
	url := FileServer + "/" + fileName
	err := downloadFile(filePath, url)
	if err != nil {
		return fmt.Errorf("failure download %q: %v", fileName, err)
	}

	err = unzipFile(filePath, CniPath)
	if err != nil {
		return fmt.Errorf("failure unzip %q: %v", fileName, err)
	}
	return nil
}

func installKube(kubeName, kubeVersion string) error {
	fileName := kubeName + "-" + kubeVersion + "-" + "amd64.tgz"
	filePath := BinPath + "/" + fileName
	url := FileServer + "/" + fileName
	err := downloadFile(filePath, url)
	if err != nil {
		return err
	}

	err = unzipFile(filePath, BinPath)
	if err != nil {
		return err
	}
	return nil
}

func downloadFile(filePath, url string) error {
	out, err := os.Create(filePath)
	if err != nil {
		return err
	}
	defer out.Close()
	resp, err := http.Get(url)
	_, err = io.Copy(out, resp.Body)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	return nil
}

func unzipFile(srcPath, desPath string) error {
	cmd := exec.Command("tar", "-zxf", srcPath, "-C", desPath)
	err := cmd.Run()
	if err != nil {
		return err
	}
	return nil
}
