#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cd ~/node_exporter

nohup ./node_exporter >> ./node_exporter.log &

# wait some time until `./node_exporter` is fully up
# Otherwise, Terraform may kill the session too early
# Increase the sleep time if it doesn't work
sleep 5
