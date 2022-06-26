#!/bin/bash
set -euxo pipefail
source /home/deployer/scripts/apt_get_wait_lock.sh
export DEBIAN_FRONTEND=noninteractive

# create user for node exporter
useradd -m node_exporter
#groupadd node_exporter
usermod -a -G node_exporter node_exporter

mv /home/deployer/node_exporter /usr/local/bin
bash -c 'cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
EOF'

# make node_exporter service run automatically
systemctl daemon-reload
systemctl enable node_exporter
