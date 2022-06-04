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

   > Note: if you want to use a different file name or location, change `account_file` in [`./main.pkr.hcl`](./main.pkr.hcl) accordingly

3. Update `project-id` in `main.pkr.hcl` to match yours

4. Run the Script get-guestimage.sh in files, in case the ssh-guestimage not prepared yet.

### Build the image

Run

```bash
packer init . && packer build -force .
```

An image should be built to your GCP project

Note: `-force` to overwrite previously built image.

### Troubleshooting
1. Flaky `packer build -force` 
Solution: rerun the command. There are strange errors sometimes and we don't yet know how to solve it :P

