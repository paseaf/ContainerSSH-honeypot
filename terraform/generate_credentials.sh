#!/bin/bash
set -euo pipefail

###
# This file generates credentials locally used for our services
###

readonly TARGET_FILE="./credentials.txt"

# check for input options
force_write=0
if [ $# -ne 0 ]; then
   if [[ $1 == "-f" || $1 == "--force" ]]; then
      force_write=1
   fi
fi

# exit if file already exists
if [[ -f "$TARGET_FILE" && $force_write -eq 0 ]]; then
   echo "Skipped! File '$TARGET_FILE' already exists."
   echo "To overwrite the file, use '--force' or '-f'."
   exit 0
fi

# set and generate credentials for MinIO
MINIO_ROOT_USER="ROOTNAME"
MINIO_ROOT_PASSWORD=$(openssl rand -base64 32)

# set and generate credentials for Grafana
GRAFANA_ADMIN_USER="GRAFANAADMIN"
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 32)

# write credentials to a file
cat <<EOF > "$TARGET_FILE"
MINIO_ROOT_USER="$MINIO_ROOT_USER"
MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD"
GRAFANA_ADMIN_USER="$GRAFANA_ADMIN_USER"
GRAFANA_ADMIN_PASSWORD="$GRAFANA_ADMIN_PASSWORD"
EOF

echo "SUCCESS!"
echo "Credentials has been written to '$TARGET_FILE'"
