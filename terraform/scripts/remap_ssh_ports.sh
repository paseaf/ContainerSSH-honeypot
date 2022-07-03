#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# redirect 22 to 2222 for ContainerSSH
sudo iptables -t nat -I PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222

# Change SSHD port to 2333
echo "Port 2333" | sudo tee -a /etc/ssh/sshd_config

nohup bash -c "sleep 5 && sudo systemctl restart ssh" &

sleep 1
