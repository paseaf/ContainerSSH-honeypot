#!/bin/bash

# solves apt lock issue
# https://github.com/geerlingguy/packer-boxes/issues/7#issuecomment-425641793
function apt-get() { 
  while fuser -s /var/lib/apt/lists/lock;
  do echo 'apt-get is waiting for the lock release ...';
      sleep 1;
  done;
  /usr/bin/apt-get "$@";
}

export DEBIAN_FRONTEND=noninteractive

set -euxo pipefail

apt-get update
apt-get upgrade -y
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# set up a stable repo
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

