provider "google" {
  project = var.project
  region  = "europe-west3"
  zone    = "europe-west3-c"

  credentials = file(var.credentials)
}

resource "google_compute_network" "main" {
  name                    = "main-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gateway_subnet" {
  name          = "gateway-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.main.self_link
}

resource "google_compute_subnetwork" "honeypot_subnet" {
  name          = "honeypot-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.main.self_link
}

resource "google_compute_instance" "gateway_vm" {
  name         = "gateway-vm"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gateway_subnet.self_link
    network_ip = "10.0.0.10"
    access_config {

    }
  }
}

resource "google_compute_instance" "sacrificial_vm" {
  name         = "sacrificial"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.honeypot_subnet.self_link
    network_ip = "10.0.1.10"
    access_config {

    }
  }
}
