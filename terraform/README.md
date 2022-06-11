# Terraform

Terraform is used to provision virtual machines on GCP and run services for honeypot.

## Install and configure Terraform

Install Terraform as follows:

1. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) and `gcloud init` it with your GCP project

2. Install [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/gcp-get-started)

3. Create and download a GCP _service account key_ (in JSON) following [Terraform - Set Up GCP](https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build?in=terraform/gcp-get-started).\
   Terraform will use it to manage your GCP resources. Move the key file to current folder as `./gcp-key.json`

4. Create a `terraform/terraform.tfvars` file with the following content

   ```bash
   project                  = "<your_GCP_project_ID>"
   credentials_file         = "gcp.key.json"
   ```

5. Create an SSH key to run commands on created VM

   ```bash
   # create an ssh key
   ssh-keygen -t ed25519 -a 100 -C "deployer" -f ./deployer_key -N ""

   # add the ssh key to GCP project
   public_key=$(cat ./deployer_key.pub)
   echo "deployer":"$public_key" > ./temp_keyfile
   gcloud compute project-info add-metadata --metadata-from-file=ssh-keys=./temp_keyfile
   rm ./temp_keyfile
   ```

6. Verify if your Terraform is successfully set up.

   ```bash
   cd terraform
   terraform init # initialize the working directory
   terraform plan # preview the changes
   ```

   You should not see any error message in the output.

:tada: Congratulations! You can now use Terraform to deploy the honeypot services.

## Deploy the services

### 1. Provision

In terminal:

```bash
cd terraform
terraform apply
# in promt, answer yes
```

### 2. Set up CA

> This section is adapted from [Docker page](https://docs.docker.com/engine/security/protect-access/#create-a-ca-server-and-client-keys-with-openssl).

This step allows the gateway VM to connect to the Docker daemon on sacrificial VM via TLS.

#### 2.1 Generate CA key pair, server key, and a CSR

1. Log into sacrificial VM
   ```bash
   gcloud compute ssh sacrificial-vm
   ```
1. Preparation and set Env variable

   ```bash
   mkdir -p ~/ca
   cd ~/ca
   export HOST=$(hostname)
   ```

1. Generate CA private key

   ```bash
   # generate a passphrase file
   echo "1234567" > ./passphrase
   # generate CA private key
   openssl genrsa -aes256 -passout file:passphrase -out ca-key.pem 4096
   ```

1. Create a config file:

   ```bash
   vim openssl.conf
   ```

   Copy the following content to the file, then exit

   ```
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
   ```

1. Generate keys

   ```bash
   # generate a CA public key
   openssl req -new -x509 -days 365 -key ca-key.pem -config openssl.conf -passin file:passphrase -sha256 -out ca.pem
   # generate a server key
   openssl genrsa -out server-key.pem 4096
   # generate a certificate signing request (CSR)
   openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
   ```

1. Sign the public key with our CA

   ```bash
   # specify allowed host IPs for others to connect
   echo subjectAltName = DNS:$HOST,IP:$(hostname -i),IP:127.0.0.1 >> extfile.cnf
   # only use key for server authentication
   echo extendedKeyUsage = serverAuth >> extfile.cnf
   # generate the signed certificate
   openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
     -passin file:passphrase -CAcreateserial -out server-cert.pem -extfile extfile.cnf
   ```

   You should see something like

   ```
   Certificate request self-signature ok
   subject=CN = sacrificial-vm.europe-west3-c.c.containerssh.internal
   ```

1. Now you should have the following files

   ```bash
   $ ls -a ~/ca
   .  ..  ca-key.pem  ca.pem  cert.pem  key.pem  openssl.conf  passphrase  server-cert.pem  server-key.pem
   ```

#### 2.2 Client authentication

1. Create client keys (still on sacrificial VM for simplicity)

   ```bash
   cd ~/ca
   openssl genrsa -out key.pem 4096
   openssl req -subj '/CN=client' -new -key key.pem -out client.csr
   echo extendedKeyUsage = clientAuth > extfile-client.cnf

   openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
     -passin file:passphrase -CAcreateserial -out cert.pem -extfile extfile-client.cnf
   ```

   You should see

   ```
   Certificate request self-signature ok
   subject=CN = client
   ```

1. Clean up
   ```bash
   # Remove unused files:
   rm -v client.csr server.csr extfile.cnf extfile-client.cnf
   # Change key access permissions
   chmod -v 0400 ca-key.pem key.pem server-key.pem
   chmod -v 0444 ca.pem server-cert.pem cert.pem
   ```
1. Make sacrificial VM's Docker daemon only accept connections with trusted certificate

   ```bash
   # Stop current running docker daemon
   sudo systemctl stop docker.socket
   # start docker daemon with specified keys
   # TODO: find how to run this in background

   sudo dockerd \
      --tlsverify \
      --tlscacert=ca.pem \
      --tlscert=server-cert.pem \
      --tlskey=server-key.pem \
      -H=0.0.0.0:2376
   ```

#### 2.3 Configure gateway VM to run Docker via sacrificial VM by default

This step will move client key files to gateway VM.

On your local machine, run

```bash
# create  a temp folder for key files
mkdir -p /tmp/ca

# download key files from sacrificial VM
gcloud compute scp --recurse sacrificial-vm:~/ca/{ca,cert,key}.pem /tmp/ca/

# upload key files to gateway VM
gcloud compute scp --recurse /tmp/ca gateway-vm:~/.docker

# clean up temp files
rm -rfv /tmp/ca
```

#### 2.4 Verify if CA is correctly set up

1. Log into the gateway VM
   ```bash
   gcloud compute ssh gateway-vm
   ```
1. Check Docker version\
   It should use to your Docker daemon on sacrificial VM.
   ```bash
   # use remote docker engine by default
   # TODO should we add it to ~/.bashrc?
   export DOCKER_HOST=tcp://sacrificial-vm:2376 DOCKER_TLS_VERIFY=1
   # test connection
   docker version
   ```
   You should not see any error message here.

## Misc.

### Services

#### Prometheus status page

`http://<logger-vm>:9091/`:

To get logger-vm IP address:

```bash
gcloud compute instances describe logger-vm \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

### Handy commands

```bash
gcp compute ssh <vm-name> # ssh to a vm (e.g., gateway-vm, logger-vm, sacrificial-vm)
```

## Troubleshooting

Trouble:

`terraform apply` failed with `Error creating Network: googleapi: Error 403: Required 'compute.networks.create' permission for '<project-id>', forbidden`

Possible solutions:

1. `project-id` might be wrong. Check if `project` value is correct in installation section step 4.
2. Did you grant the _Project Editor_ permission to the service account in installation section step 3?
