packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "ubuntu-2204" {
  project_id          = "containerssh"
  source_image_family = "ubuntu-pro-2204-lts"
  ssh_username        = "root"
  zone                = "europe-west3-c"
  account_file        = "./gcp.key.json"
}

build {
  name = "sacrificial vm image"

  source "googlecompute.ubuntu-2204" {
    image_name = "sacrificial-vm-image"
  }
  # sources = [
  #   "source.googlecompute.ubuntu-2204"
  # ]
  provisioner "shell" {
    scripts = ["./scripts/update.sh", "./scripts/install_docker.sh"]
  }
}

