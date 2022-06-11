#!/bin/bash

set -euxo pipefail

mkdir -p /srv/containerssh/config/
mkdir -p /srv/containerssh/audit/
cd /srv/containerssh
openssl genrsa > ssh_host_rsa_key
