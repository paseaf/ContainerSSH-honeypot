#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# create required directorieees
sudo mkdir -p /srv/containerssh/config/
sudo mkdir -p /srv/containerssh/audit/

# copy config file
sudo mv ~/containerssh_config.yaml /srv/containerssh/config.yaml
