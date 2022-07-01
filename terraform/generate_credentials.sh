#!/bin/bash
set -euo pipefail

TARGET_FILE="./scripts/export_credentials.sh"

# exit if file already exists
if [ -f "$TARGET_FILE" ]; then
   echo "[Error] file '$TARGET_FILE' already exists!" >&2
   echo "[Error] Remove the file if you want to regenerate credentials" >&2
   exit 1
fi

# set and generate credentials
MINIO_ROOT_USER="ROOTNAME"
MINIO_ROOT_PASSWORD=$(openssl rand -base64 32)

# write to file
cat <<EOF >> "$TARGET_FILE"
#!/bin/bash
set -euxo pipefail

export MINIO_ROOT_USER=$MINIO_ROOT_USER
export MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD"
EOF
