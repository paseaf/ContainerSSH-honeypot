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

# standard firewall settings
resource "google_compute_firewall" "firewall-all-allow-ssh" {
  name    = "firewall-standard-rule"
  network = google_compute_network.main.self_link

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "9091"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# open gateway-port 9100 and 9101, to our prometheus and metrics server
resource "google_compute_firewall" "firewall-gateway-nodeexport" {
  name    = "firewall-gateway-nodeexport"
  network = google_compute_network.main.self_link

  allow {
    protocol = "tcp"
    ports    = ["9100","9101"]
  }

  target_tags = [ "gateway" ]
  source_tags = [ "observer" ]
}

# allow inbound connection on TCP port 2376 from gateway
resource "google_compute_firewall" "firewall-sacrificial-exception" {
  name = "firewall-sacrificial-exception"
  network = google_compute_network.main.name
  priority = 500
  source_tags = [ "gateway" ]
  target_tags = [ "sacrificial" ]
  allow {
    protocol = "tcp"
    ports = [ "2376" ]
  }
}

# close all outgoing connection from sacrificial host
resource "google_compute_firewall" "firewall-sacrificial-no-egress" {
  name = "firewall-sacrificial-no-egress"
  network = google_compute_network.main.name
  direction = "EGRESS"
  destination_ranges = [ "0.0.0.0/0" ]
  target_tags = [ "sacrificial" ]
  deny {
    protocol = "all"
  }
}

resource "google_compute_instance" "gateway_vm" {
  name         = "gateway-vm"
  machine_type = var.machine_type
  tags = [ "gateway" ]

  boot_disk {
    initialize_params {
      image = "ubuntu-with-docker-image"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gateway_subnet.self_link
    network_ip = "10.0.0.10"
    access_config {

    }
  }

  connection {
    type        = "ssh"
    user        = "deployer"
    private_key = file("./deployer_key")
    host        = self.network_interface.0.access_config.0.nat_ip
  }

  provisioner "remote-exec" {
    scripts = [
      "./scripts/download_node_exporter.sh",
      "./scripts/run_node_exporter.sh"
    ]
  }
}

resource "google_compute_instance" "sacrificial_vm" {
  name         = "sacrificial-vm"
  machine_type = var.machine_type
  tags = [ "sacrificial" ]
  boot_disk {
    initialize_params {
      image = "sacrificial-vm-image"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.honeypot_subnet.name
    network_ip = "10.0.1.10"
    access_config {

    }
  }
  connection {
    type        = "ssh"
    user        = "deployer"
    private_key = file("./deployer_key")
    host        = self.network_interface.0.access_config.0.nat_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo docker load -i /home/tmp/containerssh-guest-image.tar"
    ]
  }

}

resource "google_compute_instance" "logger_vm" {
  name         = "logger-vm"
  machine_type = var.machine_type
  tags = [ "observer" ]
  boot_disk {
    initialize_params {
      image = "ubuntu-with-docker-image"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gateway_subnet.name
    network_ip = "10.0.0.11"
    access_config {

    }
  }

  # Prometheus config
  provisioner "file" {
    source      = "./files/prometheus.yml" # relative to terraform work_dir
    destination = "./prometheus.yml"       # relative to remote $HOME
  }

  connection {
    type        = "ssh"
    user        = "deployer"
    private_key = file("./deployer_key")
    host        = self.network_interface.0.access_config.0.nat_ip
  }

  provisioner "remote-exec" {
    scripts = [
      "./scripts/run_minio.sh",
      "./scripts/run_prometheus.sh"
    ]
  }
}
