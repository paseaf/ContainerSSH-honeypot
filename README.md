# ContainerSSH-honeypot

An SSH honeypot built with [ContainerSSH](https://containerssh.io/) for GCP.

## Highlights

- **Infrastructure-as-Code**: all the infrastructure, software installation and configuration steps are coded with the help of Terraform and Packer
- **Montoring system**: our system is monitored with [Prometheus](https://prometheus.io/), [Grafana](https://grafana.com/), and [cAdvisor](https://github.com/google/cadvisor)
- **Audit logging**: we log attackers' IP, username, password, and all SSH activities, thanks to [ContainerSSH](https://containerssh.io/)
- [**Data integrator**](./analyzer): with a single command, audit logs are downloaded from GCP, transformed locally, then loaded into a local database for further analysis

## Infrastructure

![infra diagram](./diagrams/infra.drawio.svg)

- _Gateway VM_ works as a proxy, and logs user interactions to _Logger VM_.
- _Sacrificial VM_ hosts containers for SSH backend.
- _Logger VM_ hosts audit log storage and monitoring systems.

### Ports

Gateway VM:

- Honeypot gateway: `22`, `2222` (`2222` is redirected to `22`)
- SSH: `2333`
- cAdvisor: `8088`
- Node Exporter: `9100`
- ContainerSSH auth-config server: `8080`
- ContainerSSH metrics server: `9101`

Logger VM:

- SSH: `22`
- cAdvisor: `8088`
- Node Exporter: `9100`
- MinIO server: `9000`
- MinIO Console: `9090`
- Grafana: `3000`
- Prometheus with auth proxy: `19091`->`9091`

Sacrificial VM:

- SSH: `22`
- cAdvisor: `8088`
- Node Exporter: `9100`
- Dockerd over TLS: `2376`

## Getting started

### Prerequisites

- Linux (tested on Fedora and Ubuntu)
- a GCP account

### Deploying the Honeypot System

1. Build VM images following [`/packer/README.md`](/packer/README.md)
2. Provision infrastructure and deploy services following [`/terraform/README.md`](/terraform/README.md)

Now, you should be able to asscess your SSH honeypot via

```bash
ssh -oHostKeyAlgorithms=+ssh-rsa \
 $(gcloud compute instances describe gateway-vm \
 --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
 --zone=europe-west3-c)
```

Your will be redirected to a newly created container in the sacrificial VM.

### Debugging
Log into Gateway VM:
```bash
gcloud compute ssh gateway-vm --zone=europe-west3-c \
   --ssh-flag="-p 2333"
```

## Accessing audit logs and metrics

After you deployed the honeypot, following monitoring tools should be available:

- **Prometheus**: for raw hardware and OS metrics.
- **Grafana**: for visualized hardware and OS metrics.
- **MinIO Console**: for audit logs (what attackers did via SSH).

To get their URLs:

```bash
cd terraform
terraform output
```

You should see something like

```
grafana = "http://34.89.246.67:3000/"
minio_console = "http://34.89.246.67:9090/"
prometheus = "http://34.89.246.67:19091/"
```

Log in with credentials generated at `./terraform/credentials.txt`.

### Downloading and Analyzing Audit Logs

You can either

1. download audit logs from MinIO _manually_
2. or use our [log analyzer script](./analyzer) to download logs and load them into a SQLite database file.

#### Manual download

1. Open MinIO Console URL in browser.
1. Log in with credentials generated at `./terraform/credentials.txt`
1. You should see records in the `containerssh` bucket. Download records you want to analyze.
1. Decode the records with `containerssh-auditlog-decoder` from https://github.com/ContainerSSH/ContainerSSH/releases/tag/v0.4.1, or implement your own decoder.\
   Read more about the record format [here](https://containerssh.io/reference/audit/#the-binary-format-recommended).

Note: [this SSH guide](https://containerssh.io/development/containerssh/ssh/) may help you understand the audit log.
