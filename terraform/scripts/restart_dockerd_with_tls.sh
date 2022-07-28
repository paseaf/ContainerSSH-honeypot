#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Make docker daemon only accept connections with trusted certificate

TARGET_DIR=/lib/systemd/system/docker.service.d
mkdir -p "$TARGET_DIR"

# override default ExecStart
cat > "$TARGET_DIR/local.conf" << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock \
  --tlsverify --tlscacert=/home/deployer/ca.pem \
  --tlskey=/home/deployer/server-key.pem \
  --tlscert=/home/deployer/server-cert.pem \
  -H=0.0.0.0:2376
EOF

systemctl daemon-reload
systemctl restart docker

sleep 1
