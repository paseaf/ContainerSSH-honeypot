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

In terminal:

```bash
cd terraform
terraform apply
# answer yes
```

Terraform will now create resources and deploy all services on GCP.
Deployment should take around 3 minutes.

When complete, access the honeypot via

```bash
ssh -oHostKeyAlgorithms=+ssh-rsa \
  $(gcloud compute instances describe gateway-vm \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)') \
  -p 2222
```

You should be able to log in with any password.

## Misc.

### Handy commands

#### SSH to a GCP VM

```bash
# ssh to a vm (e.g., gateway-vm, logger-vm, sacrificial-vm)
gcp compute ssh <vm-name>
```

#### Managing MinIO with MinIO Client `mc`

`mc` allows you to manage a MinIO server.

```bash
# install mc
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/mc

# configure local connection to a MinIO server
mc alias set conn_name http://vm-host:9000 ROOTNAME CHANGEME123
# check connection status
mc admin info conn_name
# list buckets on a connection
mc ls conn_name
# add buckets to a connection
mc mb conn_name/bucket_name
# copy a file to a bucket
mc cp local_file conn_name/bucket_name
```

## Troubleshooting

### Trouble:

`terraform apply` failed with `Error creating Network: googleapi: Error 403: Required 'compute.networks.create' permission for '<project-id>', forbidden`

Possible solutions:

1. `project-id` might be wrong. Check if `project` value is correct in installation section step 4.
2. Did you grant the _Project Editor_ permission to the service account in installation section step 3?

### Trouble: `terraform apply` failed after timout

```bash
google_compute_instance.gateway_vm: Still creating... [5m0s elapsed]
google_compute_instance.logger_vm: Still creating... [5m10s elapsed]
google_compute_instance.gateway_vm: Still creating... [5m10s elapsed]
╷
│ Error: file provisioner error
│
│   with google_compute_instance.gateway_vm,
│   on main.tf line 132, in resource "google_compute_instance" "gateway_vm":
│  132:   provisioner "file" {
│
│ timeout - last error: SSH authentication failed (deployer@34.141.101.194:22): ssh: handshake failed: ssh: unable to
│ authenticate, attempted methods [none publickey], no supported methods remain
╵
```

Possible solution:

Remove `./deployer_key`, `./deployer_key.pub`, and regenerate them following this README.
