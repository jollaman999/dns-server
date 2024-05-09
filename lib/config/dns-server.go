package config

import (
	"dns-server/common"
	"errors"
	"fmt"
	"github.com/jollaman999/utils/fileutil"
	"gopkg.in/yaml.v3"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type dnsServerConfig struct {
	DNSServer struct {
		HostListFile string `yaml:"host_list_file"`
		Listen       struct {
			Port string `yaml:"port"`
		} `yaml:"listen"`
	} `yaml:"dns-server"`
}

var DNSServerConfig dnsServerConfig
var dnsServerConfigFile = "dns-server.yaml"

func checkDNSServerConfigFile() error {
	if DNSServerConfig.DNSServer.HostListFile == "" {
		return errors.New("config error: dns-server.host_list_file is empty")
	}
	if !fileutil.IsExist(DNSServerConfig.DNSServer.HostListFile) {
		return errors.New("config error: Can't find host_list_file (" +
			DNSServerConfig.DNSServer.HostListFile + ")")
	}

	if DNSServerConfig.DNSServer.Listen.Port == "" {
		return errors.New("config error: dns-server.listen.port is empty")
	}
	port, err := strconv.Atoi(DNSServerConfig.DNSServer.Listen.Port)
	if err != nil || port < 1 || port > 65535 {
		return errors.New("config error: dns-server.listen.port has invalid value")
	}

	return nil
}

func readDNSServerConfigFile() error {
	common.RootPath = os.Getenv(common.ModuleROOT)
	if len(common.RootPath) == 0 {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return err
		}

		common.RootPath = homeDir + "/." + strings.ToLower(common.ModuleName)
	}

	err := fileutil.CreateDirIfNotExist(common.RootPath)
	if err != nil {
		return err
	}

	ex, err := os.Executable()
	if err != nil {
		return err
	}

	exPath := filepath.Dir(ex)
	configDir := exPath + "/conf"
	if !fileutil.IsExist(configDir) {
		configDir = common.RootPath + "/conf"
	}

	data, err := os.ReadFile(configDir + "/" + dnsServerConfigFile)
	if err != nil {
		return errors.New("can't find the config file (" + dnsServerConfigFile + ")" + fmt.Sprintln() +
			"Must be placed in '." + strings.ToLower(common.ModuleName) + "/conf' directory " +
			"under user's home directory or 'conf' directory where running the binary " +
			"or 'conf' directory where placed in the path of '" + common.ModuleROOT + "' environment variable")
	}

	err = yaml.Unmarshal(data, &DNSServerConfig)
	if err != nil {
		return err
	}

	err = checkDNSServerConfigFile()
	if err != nil {
		return err
	}

	return nil
}

func prepareDNSServerConfig() error {
	err := readDNSServerConfigFile()
	if err != nil {
		return err
	}

	return nil
}
