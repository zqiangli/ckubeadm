package dependence

import (
	"fmt"
	"testing"

	kubeadmapi "github.com/cherryleo/ckubeadm/app/apis/kubeadm"
)

func TestInstallKubelet(t *testing.T) {
	cfg := kubeadmapi.MasterConfiguration{KubernetesVersion: "1.9.1"}
	err := InstallKubelet(&cfg)
	if err != nil {
		fmt.Println(err.Error())
	}
}
