#!/bin/bash

set -euxo pipefail

packer validate .
packer fmt .

# Note: use `-force` to overwrite previously built image
packer build -force .
