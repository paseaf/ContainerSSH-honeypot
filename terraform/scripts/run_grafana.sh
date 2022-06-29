#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo docker run \
  --volume=grafana_data:/var/lib/grafana \
  --volume=/home/deployer/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources \
  --volume=/home/deployer/grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards \
  --publish=3000:3000 \
  --detach=true \
  --name=grafana \
  grafana/grafana
