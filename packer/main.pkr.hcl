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
  name = "sacrificial-vm-image"

  source "googlecompute.ubuntu-2204" {
    image_name = "sacrificial-vm-image"
  }

  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/tmp/util_fn"
  }

  provisioner "shell" {
    script = "./scripts/update.sh"
  }

  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/tmp/util_fn"
  }
  provisioner "shell" {
    script = "./scripts/install_docker.sh"
  }
}

build {
  name = "logger-vm-image"

  source "googlecompute.ubuntu-2204" {
    image_name = "logger-vm-image"
  }


  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/tmp/util_fn"
  }

  provisioner "shell" {
    script = "./scripts/update.sh"
  }

  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/tmp/util_fn"
  }
  provisioner "shell" {
    script = "./scripts/install_docker.sh"
  }
}

