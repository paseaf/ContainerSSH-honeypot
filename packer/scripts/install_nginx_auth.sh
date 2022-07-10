#!/bin/bash
# NGINX for authenticating Prometheus
set -euxo pipefail
source /home/deployer/scripts/apt_get_wait_lock.sh
export DEBIAN_FRONTEND=noninteractive

apt-get install -y nginx
# for generating crendentials in terraform
apt-get install -y apache2-utils

# redirect 9091 -> 19091 with authentication
# password file will be generated during terraform apply
cat <<EOF > "/etc/nginx/nginx.conf"
http {
  server {
    listen 19091;
    location / {
      proxy_pass http://0.0.0.0:9091;

      auth_basic "Prometheus";
      auth_basic_user_file "/home/deployer/prometheus_htpasswd";
    }
  }
}
events {
}
EOF
