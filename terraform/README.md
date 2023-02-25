# Terraform

Terraform is used to provision virtual machines on GCP and run services for honeypot.

## Install and configure Terraform

Install Terraform as follows:

1. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) and `gcloud init` it with your GCP project

1. Install [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/gcp-get-started)

1. Run `./setup.sh` to create a var for including your `gcloud` default values

   ```
   project_id      = "<your default gcloud project>"
   ```

1. Verify if your Terraform is successfully set up.

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
ssh -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa \
 root@$(gcloud compute instances describe gateway-vm \
 --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
 --zone=europe-west3-c)
```

You should be able to log in with any password.

## Misc.

### Handy commands

#### SSH to a GCP VM

```bash
# Gateway VM
gcloud compute ssh root@gateway-vm --zone=europe-west3-c --ssh-flag="-p 2333"

# Logger VM
gcloud compute ssh root@logger-vm --zone=europe-west3-c

# Sacrificial VM
gcloud compute ssh root@sacrificial-vm --zone=europe-west3-c
```

#### Managing MinIO with MinIO Client `mc`

`mc` allows you to manage a MinIO server.

```bash
# install mc
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/mc

# configure local connection to a MinIO server
mc alias set conn_name http://vm-host:9000 <MINIO_ROOT_USER> <MINIO_ROOT_PASSWORD>
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

### Trouble: unset credentials

Sometimes `terraform apply` may fail due to corrupted `./credentials.txt`.

Regenerate the credential file via

```bash
./generate_credentials.sh
```

Then, `terraform destroy` and `terraform apply` again.
