# [WIP] containerSSH-honeypot

:construction::construction::construction:\
This project is still work in progress\
:construction::construction::construction:

![infra diagram](./diagrams/infra.drawio.svg)

Sacrificial VM provides infrastructure for containers.

### Ports

- MinIO: `9090`
- Prometheus: `9091`
- Node exporter: `9100`

## Troubleshooting

GCloud notes

- If `gcloud` failed when installing components:\
  Install `gcloud` with [interactive](https://cloud.google.com/sdk/docs/downloads-interactive#linux-mac). The one with `dnf` doesn't allow installing components.
