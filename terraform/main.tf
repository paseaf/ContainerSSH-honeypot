provider "google" {
  project = var.project
  region  = "europe-west3"
  zone    = "europe-west3-c"

  credentials = file(var.credentials)
}

resource "google_compute_network" "vpc_network" {
  name                    = "containerssh-network"
  auto_create_subnetworks = true
}

resource "google_compute_instance" "gateway_vm" {
  name         = "gateway-vm"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-pro-2204-jammy-v20220506"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {

    }
  }
}

resource "google_compute_instance" "sacrificial_vm" {
  name         = "sacrificial"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-pro-2204-jammy-v20220506"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {

    }
  }
}
