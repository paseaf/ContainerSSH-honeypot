# Deployment

Terraform is used to provision machines on GCP.
Install it as follows:

1. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) and `gcloud init` it with your GCP project

2. Install [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/gcp-get-started)

3. Create and download a GCP _service account key_ (in JSON) following [_Set up GCP_ in this guide](https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build?in=terraform/gcp-get-started).\
   Terraform will use it to manage your GCP resources. Move the key file to `./.gcp-key.json`

4. Update `terraform/terraform.tfvars` file with the following content

   ```bash
   project                  = "<GCP_project_ID>"
   credentials_file         = "<path_to_GCP_key_file>"
   ```

5. Verify if your Terraform is successfully set up.
   ```bash
   cd terraform
   terraform init # initialize the working directory
   terraform plan # preview the changes
   ```
   You should not see any error message in the output.

