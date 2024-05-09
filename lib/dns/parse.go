package dns

import (
	"bufio"
	"dns-server/lib/config"
	"fmt"
	"github.com/jollaman999/utils/iputil"
	"github.com/jollaman999/utils/logger"
	"github.com/miekg/dns"
	"os"
	"strings"
)

var records = make(map[string]string)

func parseHostsListFile() error {
	inFile, err := os.Open(config.DNSServerConfig.DNSServer.HostListFile)
	if err != nil {
		return err
	}
	defer func() {
		_ = inFile.Close()
	}()

	scanner := bufio.NewScanner(inFile)
	for scanner.Scan() {
		line := scanner.Text()
		sep := strings.Split(line, " ")
		if len(sep) == 2 {
			ip := iputil.CheckValidIP(sep[1])
			if ip == nil {
				logger.Println(logger.ERROR, false, "Wrong host IP address in host list file."+
					"("+line+")")
			}
			records[sep[0]+"."] = sep[1]
		} else {
			logger.Println(logger.ERROR, false, "Wrong host definition in host list file."+
				"("+line+")")
		}
	}

	return nil
}

func parseQuery(m *dns.Msg) {
	for _, q := range m.Question {
		switch q.Qtype {
		case dns.TypeA:
			logger.Println(logger.DEBUG, false, "Query for "+q.Name)
			ip := records[q.Name]
			if ip != "" {
				rr, err := dns.NewRR(fmt.Sprintf("%s A %s", q.Name, ip))
				if err == nil {
					m.Answer = append(m.Answer, rr)
				}
			} else {
				m.Rcode = dns.RcodeNameError
			}
		}
	}
}
