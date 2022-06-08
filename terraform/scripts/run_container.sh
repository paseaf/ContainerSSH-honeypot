#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo docker run -d \
   --name testContainer \
   ubuntu:jammy
