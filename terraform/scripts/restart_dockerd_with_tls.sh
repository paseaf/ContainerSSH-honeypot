#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Make docker daemon only accept connections with trusted certificate

TARGET_DIR=/lib/systemd/system/local.conf
mkdir -p "$TARGET_DIR"

# override default ExecStart
cat > "$TARGET_DIR" << EOF
[Service]
ExecStart= --tlsverify --tlscacert=/home/deployer/ca.pem \
  --tlskey=/home/deployer/server-key.pem \
  --tlscert=/home/deployer/server-cert.pem \
  -H=0.0.0.0:2376
EOF

systemctl daemon-reload
systemctl restart docker

sleep 1
