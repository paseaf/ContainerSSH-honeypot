# containerSSH-honeypot

![infra diagram](./diagrams/infra.drawio.svg)

### Ports

- MinIO: `9090`
- Prometheus: `9091`
- Node exporter: `9100`

## Troubleshooting

GCloud notes

- Install gcloud with [interactive](https://cloud.google.com/sdk/docs/downloads-interactive#linux-mac). The one with `dnf` doesn't allow installing components.
- Some APIs needs to be enabled from the GCP console. These APIs include but are not limited to: Cloud Build, Cloud Run.
- Enable Packer-related components
  https://cloud.google.com/build/docs/building/build-vm-images-with-packer
