#!/bin/bash

set -euxo pipefail

cd /home/tmp
tar -xvf ca_server.tar
rm -f ca_server.tar
mv *.pem /var/docker/
#mv daemon.json /etc/docker/