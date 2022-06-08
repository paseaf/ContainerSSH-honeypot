#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# source: https://devopscube.com/run-docker-in-docker/
sudo docker run -dit \
   --name docker_container \
   -v /var/run/docker.sock:/var/run/docker.sock \
   -v /srv/containerssh/:/srv/containerssh/ \
   docker
