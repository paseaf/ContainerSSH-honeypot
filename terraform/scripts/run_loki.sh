#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo docker run \
  --log-driver=loki \
  --log-opt loki-url="http://logger-vm:3100/loki/api/v1/push" \
  --log-opt loki-retries=0 \
  --name loki \
  -d -v $HOME/loki/:/mnt/config \
  -p 3100:3100 \
   grafana/loki:latest \
   -config.file=/mnt/config/loki-config.yaml
