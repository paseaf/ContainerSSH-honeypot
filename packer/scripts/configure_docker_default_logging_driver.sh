#!/bin/bash
set -euxo pipefail
source /home/deployer/scripts/apt_get_wait_lock.sh
export DEBIAN_FRONTEND=noninteractive

cat <<EOF > "/etc/docker/daemon.json"
{
  "debug": true,
  "log-driver": "loki"
}
EOF
systemctl restart docker
