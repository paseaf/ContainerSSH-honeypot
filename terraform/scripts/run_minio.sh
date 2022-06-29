#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

USERNAME="ROOTNAME"
PASSWORD="CHANGEME123"

# start minio
mkdir -p ~/minio/data

sudo docker run -d \
   -p 9000:9000 \
   -p 9090:9090 \
   --name minIO \
   -v ~/minio/data:/data \
   -e "MINIO_ROOT_USER=$USERNAME" \
   -e "MINIO_ROOT_PASSWORD=$PASSWORD" \
   -e "MINIO_SITE_REGION=europe-west3" \
   quay.io/minio/minio server /data --console-address ":9090"

# install minio client for all users
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/mc

# configure local connection to local MinIO server
mc alias set local http://127.0.0.1:9000 $USERNAME $PASSWORD
# create a bucket
mc mb local/honeypot

sleep 1
