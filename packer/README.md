# Packer

We use [Packer](https://www.packer.io/) to create [VM images on GCP](https://cloud.google.com/compute/docs/images) with the latest required software installed.
The images are used to create secure VMs for next steps.

## How it works

Packer will

1. create a VM on Google Cloud Platform (GCP)
2. run our scripts to update and install software (e.g., Docker, Prometheus, ContainerSSH) on the VM
3. take a snapshot of the VM and store it as an image on GCP
4. delete the VM

Two images are created:

- `ubuntu-with-docker-image` for _Gateway VM_ and _Logger VM_
- `sacrificial-vm-image` for _Sacrificial VM_

## Getting Started

### Prerequisite

- A GCP account
- Install [`gcloud CLI`](https://cloud.google.com/sdk/docs/install) and initalize it with `gcloud init`
- Install [Packer](https://www.packer.io/downloads)

### Setting up Packer for GCP

1. Set up default GCP account 
   ```bash
   gcloud auth application-default login
   ```
   For alternative login methods, check out [Packer - Authentication](https://developer.hashicorp.com/packer/plugins/builders/googlecompute#authentication).

1. Create a `variables.auto.pkrvars.hcl` file:

   ```bash
   project_id      = "<your_GCP_project_ID>"
   ```
1. Initialize Packer at `./packer`
   ```bash
   packer init .
   ```

### Building the images

Run

```bash
./run.sh
```

Images should be built to your GCP project.

## Troubleshooting

1. You may need to enable some GCP services if it is your first time to use GCP. Follow the links in error logs and enable them.

1. Flaky `packer build -force`\
   Solution: rerun the command. There are strange errors sometimes and we don't yet know how to solve it :P

1. Red text in log\
   ![image](https://user-images.githubusercontent.com/33207565/169320895-0fcc5d3d-67ac-48e7-87f4-54c49dc28707.png)
   Answer: It's an expected behavior caused by `set -x` in our bash scripts!!\
   See [here](https://github.com/hashicorp/packer/issues/7947#issuecomment-520566272)
