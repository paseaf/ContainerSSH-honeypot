#!/bin/bash
set -euxo pipefail

TARGET_FILE="./scripts/export_credentials.sh"
MINIO_ROOT_USER="ROOTNAME"
MINIO_ROOT_PASSWORD=$(openssl rand -base64 32)

echo "#!/bin/bash" >> "$TARGET_FILE"
echo "set -euxo pipefail" >> "$TARGET_FILE"
echo "MINIO_ROOT_USER=$MINIO_ROOT_USER" >> "$TARGET_FILE"
echo "MINIO_ROOT_PASSWORD=\"$MINIO_ROOT_PASSWORD\"" >> "$TARGET_FILE"
