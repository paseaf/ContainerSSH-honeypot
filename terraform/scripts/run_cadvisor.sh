#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8088:8080 \
  --detach=true \
  --name="$HOSTNAME-cadvisor" \
  --privileged \
  --device=/dev/kmsg \
  cadvisor:latest # image pre-pulled in Packer
