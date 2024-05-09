package config

func PrepareConfigs() error {
	err := prepareDNSServerConfig()
	if err != nil {
		return err
	}

	return nil
}
