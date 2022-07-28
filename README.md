# ContainerSSH-honeypot
An SSH honeypot built with [ContainerSSH](https://containerssh.io/) on GCP.

## Infrastructure
![infra diagram](./diagrams/infra.drawio.svg)

Sacrificial VM provides infrastructure for containers.

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

## Deploying the honeypot to GCP

1. Build VM images following [`/packer/README.md`](/packer/README.md)
2. Provision infrastructure and deploy services following [`/terraform/README.md`](/terraform/README.md)

## Trying out the honeypot

To SSH into the honeypot:

```bash
ssh -oHostKeyAlgorithms=+ssh-rsa \
 $(gcloud compute instances describe gateway-vm \
 --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
 --zone=europe-west3-c)
```

Your will be redirected to a newly created container in the sacrificial VM.

All SSH interactions with the honeypot are audited and logged into MinIO.

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

### Download and decode audit logs

1. Open MinIO Console URL in browser.
1. Log in with credentials generated at `./terraform/credentials.txt`
1. You should see records in the `containerssh` bucket. Download records you want to analyze.
1. Decode the records with `containerssh-auditlog-decoder` from https://github.com/ContainerSSH/ContainerSSH/releases/tag/v0.4.1, or implement your own decoder.\
   Read more about the record format [here](https://containerssh.io/reference/audit/#the-binary-format-recommended).

Note: [this SSH guide](https://containerssh.io/development/containerssh/ssh/) may help you understand the audit log.
