#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# cAdvisor
REPO="google/cadvisor"
VERSION=$(curl --silent "https://api.github.com/repos/$REPO/releases/latest" \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/')

docker pull gcr.io/cadvisor/cadvisor:"$VERSION"
# rename for docker run later
docker image tag gcr.io/cadvisor/cadvisor:"$VERSION" cadvisor:latest

# Grafana, Loki and Promtail
docker pull grafana/grafana
docker pull grafana/loki
docker pull grafana/promtail

# MinIO
docker pull quay.io/minio/minio

# Prometheus
docker pull prom/prometheus

# ContainerSSH
docker pull containerssh/containerssh:0.4.1
docker pull containerssh/containerssh-test-authconfig:0.4.1
