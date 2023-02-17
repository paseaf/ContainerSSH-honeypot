#!/bin/bash

set -euxo pipefail

PROJECT_ID=$(gcloud config get project)
packer validate -var "project_id=$PROJECT_ID" .
packer fmt .

# Note: use `-force` to overwrite previously built image
packer build -force -var "project_id=$PROJECT_ID" .
