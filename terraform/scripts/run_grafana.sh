#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cd /home/deployer/grafana
sudo docker-compose up -d
