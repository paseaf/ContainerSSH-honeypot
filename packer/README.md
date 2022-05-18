1. Create a service account at [GCP Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) with roles:

- Compute Instance Admin (v1)
- Service Account User roles

2. Open the created service account -> Keys tab, create and download a service account key in JSON.

## Init and Build

This command builds an image to GCP

```bash
packer init . && packer build .
```
