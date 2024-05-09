# Simple DNS Server written in Go

## Overview

Respond to A records based on host list file.

## How to run

* Create a host list file in ./conf/hosts. This file is similar to the /etc/hosts file.
   ```shell
   test.service 192.168.0.2
   test.domain 192.168.0.3
   some.test.domain 192.168.0.4
   ```

* Build and run binary
   ```shell
   make run
   ```

## About configuration file
- Configuration file name is 'dns-server.yaml'
- The configuration file must be placed in one of the following directories.
    - .dns-server/conf directory under user's home directory
    - 'conf' directory where running the binary
    - 'conf' directory where placed in the path of 'CMCICADA_ROOT' environment variable
- Configuration options
  - host_list_file : Path of the host list file.
  - listen
    - port : Listen port of the DNS server.
- Configuration file example
  ```yaml
  dns-server:
      host_list_file: ./conf/hosts
      listen:
          port: 53
  ```