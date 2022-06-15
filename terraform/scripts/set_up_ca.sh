#!/bin/bash

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive


# 1. Preparation and set env variables
HOST=$(hostname)
echo "1234567" > ./passphrase # passphrase for ssl key gen

openssl genrsa -aes256 -passout file:passphrase -out ca-key.pem 4096

cat > ./openssl.conf << EOF
[ req ]
prompt                 = no
days                   = 365
distinguished_name     = req_distinguished_name


[ req_distinguished_name ]
countryName            = DE
stateOrProvinceName    = Germany
localityName           = Berlin
organizationName       = TU Berlin
organizationalUnitName = NAP
commonName             = sacrificial-vm
emailAddress           = emailaddress@myemail.com
EOF


# 2. Generate CA keys
# generate a CA public key
openssl req -new -x509 -days 365 -key ca-key.pem -config openssl.conf -passin file:passphrase -sha256 -out ca.pem
# generate a server key
openssl genrsa -out server-key.pem 4096
# generate a certificate signing request (CSR)
openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr


# 3. Sign the public key with CA
# specify allowed host IPs for others to connect
echo "subjectAltName = DNS:$HOST,IP:$(hostname -i),IP:127.0.0.1" >> extfile.cnf
# only use key for server authentication
echo extendedKeyUsage = serverAuth >> extfile.cnf
# generate the signed certificate
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -passin file:passphrase -CAcreateserial -out server-cert.pem -extfile extfile.cnf


# 4. Generate client keys
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth > extfile-client.cnf

openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -passin file:passphrase -CAcreateserial -out cert.pem -extfile extfile-client.cnf


# 5. Clean up
rm -v client.csr server.csr extfile.cnf extfile-client.cnf
chmod -v 0400 ca-key.pem key.pem server-key.pem
chmod -v 0444 ca.pem server-cert.pem cert.pem


# 6. Make docker daemon only accept connections with trusted certificate
sudo systemctl stop docker.socket
nohup sudo dockerd \
   --tlsverify \
   --tlscacert=ca.pem \
   --tlscert=server-cert.pem \
   --tlskey=server-key.pem \
   -H=0.0.0.0:2376 \
   &> dockerd.log &
sleep 1
