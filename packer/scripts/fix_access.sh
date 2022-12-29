#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

chown -R deployer:deployer /home/deployer
