#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

cd ~/node_exporter

nohup ./node_exporter >> ./node_exporter.log &

nohup ./node_exporter &

