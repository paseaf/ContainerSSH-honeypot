#!/bin/bash
set -euxo pipefail
source /home/deployer/scripts/apt_get_wait_lock.sh
export DEBIAN_FRONTEND=noninteractive

bash -c 'cat <<EOF > /etc/docker/daemon.json
{
    "debug" : true,
    "log-driver": "loki",
    "log-opts": {
        "loki-url": "https://logger-vm:3100/loki/api/v1/push",
        "loki-batch-size": "400"
    }
}
EOF'

systemctl restart docker
