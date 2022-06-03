#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo docker run -d \
    -p 9091:9090 \
    prom/prometheus
