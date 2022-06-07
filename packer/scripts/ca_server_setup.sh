#!/bin/bash

set -euxo pipefail

cd /home/deployer
tar -xvf ca_server.tar
rm -f ca_server.tar
mv *.pem /var/docker/
mv daemon.json /etc/docker/

# fix for Unable to start docker after configuring hosts in daemon.json
# source: https://stackoverflow.com/questions/44052054/unable-to-start-docker-after-configuring-hosts-in-daemon-json
cp /lib/systemd/system/docker.service /etc/systemd/system/
sed -i 's/\ -H\ fd:\/\///g' /etc/systemd/system/docker.service
systemctl daemon-reload
service docker restart
