package dns

import (
	"dns-server/lib/config"
	"github.com/jollaman999/utils/logger"
	"github.com/miekg/dns"
)

func Init() {
	dns.HandleFunc("service.", handleDNSRequest)

	err := parseHostsListFile()
	if err != nil {
		logger.Panic(logger.ERROR, true, "Failed to parse host list file: "+err.Error())
	}

	port := config.DNSServerConfig.DNSServer.Listen.Port
	server := &dns.Server{Addr: ":" + port, Net: "udp"}
	logger.Println(logger.INFO, false, "Starting at "+port+"/udp")
	err = server.ListenAndServe()
	defer func(server *dns.Server) {
		_ = server.Shutdown()
	}(server)
	if err != nil {
		logger.Panic(logger.ERROR, true, "Failed to start server: "+err.Error())
	}
}
