#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Make docker daemon only accept connections with trusted certificate

TARGET_DIR=/lib/systemd/system/docker.service.d
sudo mkdir -p "$TARGET_DIR"

# override default ExecStart
sudo bash -c 'cat << EOF > $TARGET_DIR/local.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock \
  --tlsverify --tlscacert=/home/deployer/ca.pem \
  --tlskey=/home/deployer/server-key.pem \
  --tlscert=/home/deployer/server-cert.pem \
  -H=0.0.0.0:2376
EOF'

sudo systemctl daemon-reload
sudo systemctl restart docker

sleep 1
