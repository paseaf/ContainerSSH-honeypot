#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
REPO="google/cadvisor"
VERSION=$(curl --silent "https://api.github.com/repos/$REPO/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/')

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
  gcr.io/cadvisor/cadvisor:"$VERSION"
