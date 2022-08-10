#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo docker run \
  --name="$HOSTNAME-promtail" \
  -d \
  -v /var/lib/docker/containers:/var/lib/docker/containers/ \
  -v $HOME/promtail/promtail-config.yaml:/etc/promtail/docker-config.yml \
  -v $HOME/promtail/:/mnt/config \
  -v /var/log:/var/log \
  -p 9080:9080 \
   grafana/promtail:latest \
  -config.file=/mnt/config/promtail-config.yaml
