#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# This file configures containerssh

# create required directorieees
sudo mkdir -p /srv/containerssh/config/
sudo mkdir -p /srv/containerssh/audit/


# source MINIO credentials
source /home/deployer/.env
# check if env vars sourced
if [ -z ${MINIO_ROOT_USER+x} ]; then echo "MINIO_ROOT_USER is unset. Exiting..."; exit 1; fi
if [ -z ${MINIO_ROOT_PASSWORD+x} ]; then echo "MINIO_ROOT_PASSWORD is unset. Exiting..."; exit 1; fi

# insert keys into config file
mkdir -p /tmp

# append MinIO credentials to config.yaml
# write to tmp config
sed "/ s3:/a\
\ \ \  accessKey: $MINIO_ROOT_USER\n\
\ \ \  secretKey: $MINIO_ROOT_PASSWORD" \
~/config.yaml > /tmp/config.yaml

# create tmp files for indented keys (yaml requires indentation)
sed 's/^/      /' ~/.docker/cert.pem > /tmp/cert.pem
sed 's/^/      /' ~/.docker/key.pem > /tmp/key.pem
sed 's/^/      /' ~/.docker/ca.pem > /tmp/ca.pem
# append indented keys to temp config file
sed -i '/ cert: |/r /tmp/cert.pem' /tmp/config.yaml
sed -i '/ key: |/r /tmp/key.pem' /tmp/config.yaml
sed -i '/ cacert: |/r /tmp/ca.pem' /tmp/config.yaml


# move config file to target location
sudo mv /tmp/config.yaml /srv/containerssh/config.yaml

# generate a private key
sudo bash -c "openssl genrsa  > /srv/containerssh/ssh_host_rsa_key"

# give ContainerSSH access to the audit directory
sudo chown 1022:1022 /srv/containerssh/audit

# run ContainerSSH
sudo docker run -d \
  --restart=always --name containerssh \
  -v /srv/containerssh/:/etc/containerssh/ \
  -v /srv/containerssh/audit/:/var/log/containerssh/audit/ \
  --net=host   containerssh/containerssh:0.4.1

# run auth & config servers
sudo docker run -d \
  --restart=always \
  -p 127.0.0.1:8080:8080 \
  -e CONTAINERSSH_ALLOW_ALL=1 \
  --name authconfig \
  containerssh/containerssh-test-authconfig:0.4.1
