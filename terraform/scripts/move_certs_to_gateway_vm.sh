#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# create a temp folder for key files
mkdir -p /tmp/ca

# download key files from sacrificial VM
gcloud compute scp --recurse deployer@sacrificial-vm:~/{ca,cert,key}.pem /tmp/ca/

# upload key files to gateway VM
gcloud compute scp --recurse /tmp/ca deployer@gateway-vm:~/.docker

# clean up temp files
rm -rfv /tmp/ca
