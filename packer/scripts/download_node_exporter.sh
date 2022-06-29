#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

readonly VERSION=1.3.1

wget "https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz"

# untar the file to ~/node_exporter directory
mkdir -p /home/deployer/node_exporter && tar xf node_exporter-$VERSION.linux-amd64.tar.gz \
   -C /home/deployer/node_exporter --strip-components 1
