package dns

import "github.com/miekg/dns"

func handleDNSRequest(w dns.ResponseWriter, r *dns.Msg) {
	m := new(dns.Msg)
	m.SetReply(r)
	m.Compress = false
	m.RecursionDesired = true

	// Disable recursion to find next server from the client.
	m.RecursionAvailable = false

	switch r.Opcode {
	case dns.OpcodeQuery:
		parseQuery(m)
	}

	_ = w.WriteMsg(m)
}
