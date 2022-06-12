packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "ubuntu-2204" {
  project_id          = var.project_id
  source_image_family = "ubuntu-pro-2204-lts"
  ssh_username        = "root"
  zone                = "europe-west3-c"
  account_file        = "./gcp.key.json"
  machine_type        = "e2-small"
}

build {
  name = "sacrificial-vm-image"
  source "googlecompute.ubuntu-2204" {
    image_name = "sacrificial-vm-image"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /home/deployer/files",
      "mkdir -p /home/deployer/scripts"
    ]
  }

  provisioner "file" {
    source      = "./scripts"
    destination = "/home/deployer/"
  }

  provisioner "file" {
    source      = "./files"
    destination = "/home/deployer/"
  }

  provisioner "shell" {
    script            = "./scripts/update_apt_packages.sh"
    expect_disconnect = true
  }

  provisioner "shell" {
    script = "./scripts/install_docker.sh"
  }

  provisioner "shell" {
    inline = [
      "docker pull containerssh/containerssh-guest-image:latest"
    ]
  }
}

build {
  name = "ubuntu-with-docker-image"
  source "googlecompute.ubuntu-2204" {
    image_name = "ubuntu-with-docker-image"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /home/deployer/files",
      "mkdir -p /home/deployer/scripts",
      "mkdir -p /srv/containerssh/"
    ]
  }

  provisioner "file" {
    source      = "./scripts"
    destination = "/home/deployer/"
  }

  provisioner "file" {
    source      = "./files"
    destination = "/home/deployer/"
  }

  provisioner "file" {
    source      = "./files/config.yaml"
    destination = "/srv/containerssh/config.yaml"
  }

  provisioner "shell" {
    script = "./scripts/containerssh_config.sh"
  }

  provisioner "shell" {
    script = "./scripts/install_docker.sh"
  }
}
