packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "ubuntu-2204" {
  project_id          = "containerssh-352007"
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

  provisioner "shell" {
    inline = [
      "mkdir /home/tmp/",
      "mkdir /etc/docker/",
    "mkdir /var/docker/"]
  }

  provisioner "file" {
    source      = "./files/ca_server.tar"
    destination = "/home/tmp/ca_server.tar"
  }

  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/home/tmp/util_fn"
  }
  provisioner "shell" {
    script            = "./scripts/update.sh"
    expect_disconnect = true
  }
  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/home/tmp/util_fn"
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

  provisioner "shell" {
    inline = ["mkdir /home/tmp/"]
  }

  provisioner "file" {
    source      = "./files/ca_client.tar"
    destination = "/home/tmp/ca_client.tar"
  }

  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/home/tmp/util_fn"
  }

  provisioner "shell" {
    script            = "./scripts/update.sh"
    expect_disconnect = true
  }

  provisioner "file" {
    source      = "./scripts/util_fn"
    destination = "/home/tmp/util_fn"
  }

  provisioner "file" {
    source      = "./files/config.yaml"
    destination = "/home/tmp/config.yaml"
  }

  provisioner "shell" {
    script = "./scripts/containerssh_config.sh"
  }

  provisioner "shell" {
    script = "./scripts/install_docker.sh"
  }
}