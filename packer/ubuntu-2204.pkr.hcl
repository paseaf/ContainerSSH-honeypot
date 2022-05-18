packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "ubuntu-2204" {
  project_id   = "containerssh"
  account_file = file("./gcp.key.json")
  source_image_family = "ubuntu-pro-2204-lts"
  ssh_username = "admin"
  zone         = "europe-west3-c"
}

build {
  name = "ubuntu-2204-with-docker"
  sources = [
    "source.googlecompute.ubuntu-2204"
  ]
}

