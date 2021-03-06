# Packer

We use [Packer](https://www.packer.io/) to create a [VM image on GCP](https://cloud.google.com/compute/docs/images) with the latest software and Docker installed.
The image can be used to create secure VMs.

## How it works

Packer will

1. create a VM on Google Cloud Platform (GCP)
2. run our scripts to update software and install Docker on the VM
3. take a snapshot of the VM and store it as an image called `sacrificial-vm` on GCP
4. delete the VM

## Getting Started

### Prerequisite

What you need:

- `gcloud` installed locally
- A GCP project
- [Packer installed](https://www.packer.io/downloads) locally

### Set up Packer

1. Set up GCP service account for Packer following [Packer - Running outside of Google Cloud](https://www.packer.io/plugins/builders/googlecompute#running-outside-of-google-cloud)

2. Move the downloaded service account key file to `./gcp.key.json`

3. Create a `variables.auto.pkrvars.hcl` file:

   ```bash
   project_id      = "<your_GCP_project_ID>"
   ```

### Build the image

Run

```bash
packer init . && packer build -force .
```

An image should be built to your GCP project

Note: `-force` to overwrite previously built image.

### Troubleshooting

1. Flaky `packer build -force`\
   Solution: rerun the command. There are strange errors sometimes and we don't yet know how to solve it :P

2. Red text in log\
   ![image](https://user-images.githubusercontent.com/33207565/169320895-0fcc5d3d-67ac-48e7-87f4-54c49dc28707.png)
   Answer: It's an expected behavior caused by `set -x` in our bash scripts!!\
   See [here](https://github.com/hashicorp/packer/issues/7947#issuecomment-520566272)
