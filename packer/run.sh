#!/bin/bash

set -euxo pipefail

packer validate .
packer fmt .
packer build -force .
