#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# source MINIO credentials
source /home/deployer/.env

# check if env vars sourced
if [ -z ${MINIO_ROOT_USER+x} ]; then echo "MINIO_ROOT_USER is unset. Exiting..."; exit 1; fi
if [ -z ${MINIO_ROOT_PASSWORD+x} ]; then echo "MINIO_ROOT_PASSWORD is unset. Exiting..."; exit 1; fi

# start minio
mkdir -p ~/minio/data

sudo docker run -d \
   -p 9000:9000 \
   -p 9090:9090 \
   --name minIO \
   -v ~/minio/data:/data \
   -e "MINIO_ROOT_USER=$MINIO_ROOT_USER" \
   -e "MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD" \
   -e "MINIO_SITE_REGION=europe-west3" \
   quay.io/minio/minio server /data --console-address ":9090"

# install minio client for all users
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/mc

# configure local connection to local MinIO server
mc alias set local http://127.0.0.1:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
# create a bucket
mc mb local/honeypot

sleep 1
