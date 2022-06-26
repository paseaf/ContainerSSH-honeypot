#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

VERSION=v0.39.3 # use the latest release version from https://github.com/google/cadvisor/releases
sudo docker run -d \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8088:8080 \
  --detach=true \
  --name=$HOSTNAME-cadvisor \
  gcr.io/cadvisor/cadvisor:$VERSION
