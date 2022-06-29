#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo docker run -d \
    -p 9091:9090 \
    -v "$HOME/prometheus.yml":/etc/prometheus/prometheus.yml \
    --name prometheus \
    prom/prometheus
