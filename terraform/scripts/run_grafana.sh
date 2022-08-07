#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# source Grafana credentials
source /home/deployer/.env

# check if env vars sourced
if [ -z ${GRAFANA_ADMIN_USER+x} ]; then echo "GRAFANA_ADMIN_USER is unset. Exiting..."; exit 1; fi
if [ -z ${GRAFANA_ADMIN_PASSWORD+x} ]; then echo "GRAFANA_ADMIN_PASSWORD is unset. Exiting..."; exit 1; fi

sudo docker run \
  --log-driver=loki \
  --log-opt loki-url="http://logger-vm:3100/loki/api/v1/push" \
  --log-opt loki-retries=0 \
  --volume=grafana_data:/var/lib/grafana \
  --volume=/home/deployer/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources \
  --volume=/home/deployer/grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards \
  --env "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/etc/grafana/provisioning/dashboards/containerSSH.json" \
  --env "GF_SECURITY_ADMIN_USER=$GRAFANA_ADMIN_USER" \
  --env "GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD" \
  --publish=3000:3000 \
  --detach=true \
  --name=grafana \
  grafana/grafana
