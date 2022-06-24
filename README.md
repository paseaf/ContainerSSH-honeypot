# [WIP] containerSSH-honeypot

:construction::construction::construction:\
This project is still work in progress\
:construction::construction::construction:

![infra diagram](./diagrams/infra.drawio.svg)

Sacrificial VM provides infrastructure for containers.

### Ports

Audit:
- MinIO server: `9000`
- MinIO Console: `9090`

Monitoring
- Grafana: `3000` 
- Prometheus: `9091`

Services:
- Auth-Config: `8080`
- containerSSH Audit-logs: `9101`


Utilities:
- Cadvisor on Gateway-VM: `8088`
- Cadvisor on Logger-VM: `8088`
- Cadvisor on Sacrificial-VM: `8080`
- Node exporter: `9100`

## Troubleshooting

GCloud notes

- If `gcloud` failed when installing components:\
  Install `gcloud` with [interactive](https://cloud.google.com/sdk/docs/downloads-interactive#linux-mac). The one with `dnf` doesn't allow installing components.
