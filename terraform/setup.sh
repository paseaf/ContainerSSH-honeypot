#!/bin/bash

cat > terraform.tfvars <<EOF
project_id = "$(gcloud config get project)"
EOF
