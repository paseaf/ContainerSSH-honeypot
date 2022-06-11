#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo mkdir -p /srv/containerssh/config/
sudo mkdir -p /srv/containerssh/audit/
