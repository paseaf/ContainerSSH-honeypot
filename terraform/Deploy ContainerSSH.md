Deploy ContainerSSH

## Goal

Implement step 1-3 of https://containerssh.io/guides/honeypot/

## Components and Requirements

> Extracted from https://containerssh.io/guides/honeypot/

### Gateway VM x1

- [ ] have sufficient disk space to hold audit logs and containers
- [ ] firewall rules
  - [ ] Port 22 should be open to the Internet.
  - [ ] Ports 9100 and 9101 should be open from your Prometheus instance. These will be used by the Prometheus node exporter and the ContainerSSH metrics server respectively.
  - [ ] Outbound rules to your S3-compatible object storage.

### Sacrificial VM x1

- [ ] Use a prebuilt VM image with Docker installed to keep the host up to date.
  - [ ] Use tools like [Packer](https://www.packer.io/) to keep the VM image updated
- [ ] run on its own dedicated physical hardware
- [ ] have sufficient disk space to hold audit logs and containers
- [ ] Firewall rules
  - [ ] Only allows connection with the gateway host
  - [ ] Only allow inbound connections on TCP port 2376 from the gateway host

### S3-compatible object storage x1

Maybe set up MINIO on GCP?
For uploading audit logs

- [ ] decide what S3 object to use

### Prometheus x1

For monitoring audit logs.

- [ ] get familiar with prometheus
