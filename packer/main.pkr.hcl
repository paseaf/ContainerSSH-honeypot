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
      "mkdir /etc/docker/",
      "mkdir /var/docker/"
    ]
  }

  provisioner "file" {
    source      = "./files/ca_server.tar"
    destination = "/home/deployer/ca_server.tar"
  }

  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/home/deployer/util_fn"
  }
  provisioner "shell" {
    script            = "./scripts/update.sh"
    expect_disconnect = true
  }
  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/home/deployer/util_fn"
  }

  provisioner "shell" {
    script = "./scripts/install_docker.sh"
  }

  provisioner "shell" {
    inline = [
      "docker pull containerssh/containerssh-guest-image:latest"
    ]
  }

  provisioner "shell" {
    script = "./scripts/ca_server_setup.sh"
  }

}

build {
  name = "ubuntu-with-docker-image"
  source "googlecompute.ubuntu-2204" {
    image_name = "ubuntu-with-docker-image"
  }

  # test
  provisioner "file" {
    source      = "./files/ca_client.tar"
    destination = "/home/deployer/ca_client.tar"
  }

  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/home/deployer/util_fn"
  }

  provisioner "shell" {
    script            = "./scripts/update.sh"
    expect_disconnect = true
  }

  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/home/deployer/util_fn"
  }

  provisioner "shell" {
    inline = [
      "mkdir /srv/containerssh/"
    ]
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
