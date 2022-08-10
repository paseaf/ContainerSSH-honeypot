#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo docker run \
  --name loki \
  -d -v $HOME/loki/:/mnt/config \
  -p 3100:3100 \
  grafana/loki:latest \
  -config.file=/mnt/config/loki-config.yaml
