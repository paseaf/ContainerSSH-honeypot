#!/bin/bash
set -euxo pipefail

cd /home/deployer/files
docker build -t containerssh-guest-image:latest .
