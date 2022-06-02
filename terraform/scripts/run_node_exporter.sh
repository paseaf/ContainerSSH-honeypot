#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

readonly VERSION=1.3.1

wget "https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz"
tar xvfz node_exporter-$VERSION.linux-amd64.tar.gz
cd node_exporter-$VERSION.linux-amd64

nohup ./node_exporter &

