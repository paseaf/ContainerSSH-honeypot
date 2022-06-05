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
  machine_type        = "e2-micro"
}

build {
  name = "sacrificial-vm-image"
  source "googlecompute.ubuntu-2204" {
    image_name = "sacrificial-vm-image"
  }

  provisioner "shell" {
    inline = ["mkdir /home/tmp/"]
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
    source      = "./files/containerssh-guest-image.tar"
    destination = "/home/tmp/containerssh-guest-image.tar"
  }
  provisioner "shell" {
    script = "./scripts/install_docker.sh"
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
}