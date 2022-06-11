#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# source: https://devopscube.com/run-docker-in-docker/
sudo docker run --privileged -d \
   --name dind-container \
   -v /srv/containerssh/:/srv/containerssh/ \
   docker:dind
