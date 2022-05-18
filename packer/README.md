# Packer

We use Packer to create a VM image with latest software, so that Terraform can use the image to create VM instances.

## Set up GCP credentials for Packer

1. Set up GCP service account for Packer following [Packer - Running outside of Google Cloud](https://www.packer.io/plugins/builders/googlecompute#running-outside-of-google-cloud)

2. Move the downloaded service account key file to `./gcp.key.json`.

3. Set up credentials env for Packer

   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/gcp.key.json"
   ```

## Init and Build

This command builds an image to GCP

```bash
packer init . && packer build .
```
