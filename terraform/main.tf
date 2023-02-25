terraform {
  required_providers {
    google = {
      source  = "google"
      version = "4.20.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "europe-west3"
  zone    = "europe-west3-c"
}

resource "google_compute_network" "containerssh" {
  name                    = "containerssh"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gateway_subnet" {
  name          = "gateway-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.containerssh.self_link
}

resource "google_compute_subnetwork" "honeypot_subnet" {
  name          = "honeypot-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.containerssh.self_link
}

# Note: provisioner in this block only runs after all previous provisioners are finished
resource "null_resource" "set_up_docker_tls_and_containerssh" {
  # 1. Create CA and client keys; Set up Docker TLS on Sacrificial VM
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "deployer"
      private_key = "${file("~/.ssh/google_compute_engine")}"
      host        = google_compute_instance.sacrificial_vm.network_interface.0.access_config.0.nat_ip
    }

    scripts = [
      "./scripts/set_up_ca.sh",
      "./scripts/restart_dockerd_with_tls.sh",
      "./scripts/run_cadvisor.sh"
    ]
  }

  # 2. move client keys to gateway VM
  provisioner "local-exec" {
    command     = "./scripts/move_certs_to_gateway_vm.sh"
    interpreter = ["/bin/bash"]
  }

  # 3. move MinIO and Grafana credentials to Gateway VM
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "deployer"
      private_key = "${file("~/.ssh/google_compute_engine")}"
      host        = google_compute_instance.gateway_vm.network_interface.0.access_config.0.nat_ip
    }
    source      = "./credentials.txt" # relative to terraform work_dir
    destination = "./.env"            # relative to remote $HOME
  }

  # 4. configure and run ContainerSSH on gateway VM
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "deployer"
      private_key = "${file("~/.ssh/google_compute_engine")}"
      host        = google_compute_instance.gateway_vm.network_interface.0.access_config.0.nat_ip
    }

    scripts = [
      "./scripts/set_up_and_run_containerssh.sh",
      "./scripts/remap_ssh_ports.sh"
    ]
  }
}
