#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# This file configures containerssh

# create required directorieees
sudo mkdir -p /srv/containerssh/config/
sudo mkdir -p /srv/containerssh/audit/

# insert keys into config file
mkdir -p /tmp
cp ~/config.yaml /tmp/config.yaml
sed 's/^/      /' ~/.docker/cert.pem > /tmp/cert.pem
sed 's/^/      /' ~/.docker/key.pem > /tmp/key.pem
sed 's/^/      /' ~/.docker/ca.pem > /tmp/ca.pem

sed -i '/ cert: |/r /tmp/cert.pem' /tmp/config.yaml
sed -i '/ key: |/r /tmp/key.pem' /tmp/config.yaml
sed -i '/ cacert: |/r /tmp/ca.pem' /tmp/config.yaml

# move config file to target location
sudo mv /tmp/config.yaml /srv/containerssh/config.yaml

# generate a private key
sudo bash -c "openssl genrsa  > /srv/containerssh/ssh_host_rsa_key"

# run ContainerSSH
sudo docker run -d --restart=always \
 -v /srv/containerssh/:/etc/containerssh/ \
 -v /srv/containerssh/audit/:/var/log/containerssh/audit/ \
 --net=host   containerssh/containerssh:0.4.1

# run auth & config servers
sudo docker run -d \
  --restart=always \
  -p 127.0.0.1:8080:8080 \
  -e CONTAINERSSH_ALLOW_ALL=1 \
  containerssh/containerssh-test-authconfig:0.4.1

# redirect port
# will prevent us from logging into the vm. uncomment after everything is set up
# sudo iptables -t nat -I PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
