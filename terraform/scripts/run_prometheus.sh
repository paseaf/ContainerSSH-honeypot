#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Prometheus
sudo docker run -d \
    --log-driver=loki \
    --log-opt loki-url="http://logger-vm:3100/loki/api/v1/push" \
    --log-opt loki-retries=0 \
    -p 9091:9090 \
    -v "$HOME/prometheus.yml":/etc/prometheus/prometheus.yml \
    --name prometheus \
    prom/prometheus


# Set credentials for 19091->9091 reverse proxy
# make path to prometheus password accessible by nginx
sudo chmod +x /home /home/deployer
source "/home/deployer/.env"
# generate password file (path defined in /etc/nginx/nginx.conf)
htpasswd -b -c /home/deployer/prometheus_htpasswd "$PROMETHEUS_USER" "$PROMETHEUS_PASSWORD"
