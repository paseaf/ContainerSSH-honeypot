#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Make docker daemon only accept connections with trusted certificate
sudo systemctl stop docker.socket
nohup sudo dockerd \
   -H unix:///var/run/docker.sock \
   --tlsverify \
   --tlscacert=ca.pem \
   --tlscert=server-cert.pem \
   --tlskey=server-key.pem \
   -H=0.0.0.0:2376 \
   &> dockerd.log &

sleep 1
