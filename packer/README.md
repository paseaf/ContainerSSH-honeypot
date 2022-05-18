# Packer

We use Packer to create a VM image with latest software, so that Terraform can use the image to create VM instances.

## Set up GCP credentials for Packer

1. Set up GCP service account for Packer following [Packer - Running outside of Google Cloud](https://www.packer.io/plugins/builders/googlecompute#running-outside-of-google-cloud)

2. Move the downloaded service account key file to `./gcp.key.json`.
   Note: if you want to use a different file name or location, change `account_file` accordingly.

## Init and Build

This command builds an image to GCP

```bash
packer init . && packer build -force .
```

Note: `-force` to overwrite previously built image.
