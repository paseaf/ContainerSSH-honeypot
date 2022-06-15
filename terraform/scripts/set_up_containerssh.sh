#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# This file configures containerssh

# create required directorieees
sudo mkdir -p /srv/containerssh/config/
sudo mkdir -p /srv/containerssh/audit/

# insert keys into config file
mkdir -p /tmp
sed 's/^/      /' ~/.docker/cert.pem > /tmp/cert.pem
sed '/cert: |/r /tmp/cert.pem' ~/config.yaml > /tmp/config.yaml

sed 's/^/      /' ~/.docker/key.pem > /tmp/key.pem
sed '/key: |/r /tmp/key.pem' ~/config.yaml > /tmp/config.yaml

sed 's/^/      /' ~/.docker/ca.pem > /tmp/ca.pem
sed '/cacert: |/r /tmp/ca.pem' ~/config.yaml > /tmp/config.yaml

# move config file to target location
sudo mv /tmp/config.yaml /srv/containerssh/config.yaml

# generate a private key
sudo bash -c "openssl genrsa  > /srv/containerssh/ssh_host_rsa_key"

# start 
sudo docker run -d --restart=always \
 -v /srv/containerssh/:/etc/containerssh/ \
 -v /srv/containerssh/audit/:/var/log/containerssh/audit/ \
 --net=host   containerssh/containerssh:0.4.1
