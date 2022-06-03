# Deployment

Terraform is used to provision machines on GCP.
Install it as follows:

1. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) and `gcloud init` it with your GCP project

2. Install [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/gcp-get-started)

3. Create and download a GCP _service account key_ (in JSON) following [Terraform - Set Up GCP](https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build?in=terraform/gcp-get-started).\
   Terraform will use it to manage your GCP resources. Move the key file to current folder as `./gcp-key.json`

4. Update `terraform/terraform.tfvars` file with the following content

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

## Services

- `http://<logger-vm>:9091/`: Prometheus status page
  Get logger-vm IP address:

  ```bash
  gcloud compute instances describe logger-vm \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
  ```

## Trouble Shooting

1. `terraform apply` failed with `Error creating Network: googleapi: Error 403: Required 'compute.networks.create' permission for '<project-id>', forbidden`

Possible Issue:

1. `project-id` might be wrong. Check Deployment step 4.
2. Did you grant the _Project Editor_ permission to the service account in step 3?

- Create an SSH key and add it to your GCP project.

  ```bash
  # create an ssh key
  ssh-keygen -t ed25519 -a 100 -C "deployer" -f ./deployer_key -N ""

  # add the ssh key to GCP project
  public_key=$(cat ./deployer_key.pub)
  echo "deployer":"$public_key" > ./temp_keyfile
  gcloud compute project-info add-metadata --metadata-from-file=ssh-keys=./temp_keyfile
  rm ./temp_keyfile
  ```

- Open inventory file `ansible/inventory.gcp.yml`, Update `projects` property with your GCP project ID

  ```bash
  # ...
  projects:
    - <your GCP project ID>
  # ...
  ```

- :tada: Congratulations! You can now use Terraform and Ansible to provision and configure the SUT.

### Handy commands

```bash
gcp compute ssh <vm-name> # ssh to a vm (e.g., gateway-vm, logger-vm, sacrificial-vm)
```
