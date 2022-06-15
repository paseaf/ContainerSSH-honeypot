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
resource "google_compute_firewall" "firewall_standard_rule" {
  name    = "firewall-standard-rule"
  network = google_compute_network.main.self_link

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# open port 9090 and 9091 on our logger-vm: to control metrics and minio
resource "google_compute_firewall" "firewall_logger_view" {
  name    = "firewall-logger-view"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = ["9090", "9091"]
  }
  target_tags   = ["observer"]
  source_ranges = ["0.0.0.0/0"]
}

# open gateway-port 9100 and 9101, to our prometheus and metrics server
resource "google_compute_firewall" "firewall_gateway_nodeexport" {
  name    = "firewall-gateway-nodeexport"
  network = google_compute_network.main.self_link

  allow {
    protocol = "tcp"
    ports    = ["9100", "9101"]
  }

  target_tags = ["gateway"]
  source_tags = ["observer"]
}

# allow inbound connection on TCP port 2376 from gateway
resource "google_compute_firewall" "firewall_sacrificial_exception" {
  name        = "firewall-sacrificial-exception"
  network     = google_compute_network.main.name
  priority    = 500
  source_tags = ["gateway"]
  target_tags = ["sacrificial"]
  allow {
    protocol = "tcp"
    ports    = ["2376"]
  }
}

# close all outgoing connection from sacrificial host
resource "google_compute_firewall" "firewall_sacrificial_no_egress" {
  name               = "firewall-sacrificial-no-egress"
  network            = google_compute_network.main.name
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["sacrificial"]
  deny {
    protocol = "all"
  }
}

resource "google_compute_instance" "sacrificial_vm" {
  name         = "sacrificial-vm"
  machine_type = var.machine_type
  tags         = ["sacrificial"]
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
}

resource "google_compute_instance" "logger_vm" {
  name         = "logger-vm"
  machine_type = var.machine_type
  tags         = ["observer"]
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

  connection {
    type        = "ssh"
    user        = "deployer"
    private_key = file("./deployer_key")
    host        = google_compute_instance.logger_vm.network_interface.0.access_config.0.nat_ip
  }

  provisioner "file" {
    source      = "./files/prometheus.yml" # relative to terraform work_dir
    destination = "./prometheus.yml"       # relative to remote $HOME
  }
}

resource "google_compute_instance" "gateway_vm" {
  name         = "gateway-vm"
  machine_type = var.machine_type
  tags         = ["gateway"]

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
    host        = google_compute_instance.gateway_vm.network_interface.0.access_config.0.nat_ip
  }

  provisioner "file" {
    source      = "./files/config.yaml"
    destination = "./config.yaml"
  }
}
resource "null_resource" "configure_everything" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "deployer"
      private_key = file("./deployer_key")
      host        = google_compute_instance.sacrificial_vm.network_interface.0.access_config.0.nat_ip
    }

    scripts = [
      "./scripts/set_up_ca.sh",
    ]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "deployer"
      private_key = file("./deployer_key")
      host        = google_compute_instance.logger_vm.network_interface.0.access_config.0.nat_ip
    }

    scripts = [
      "./scripts/run_minio.sh",
      "./scripts/run_prometheus.sh"
    ]
  }

  provisioner "local-exec" {
    command = "./scripts/move_certs_to_gateway_vm.sh"
    interpreter = ["/bin/bash"]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "deployer"
      private_key = file("./deployer_key")
      host        = google_compute_instance.gateway_vm.network_interface.0.access_config.0.nat_ip
    }

    scripts = [
      "./scripts/download_node_exporter.sh",
      "./scripts/run_node_exporter.sh",
      "./scripts/set_up_and_run_containerssh.sh",
    ]
  }
}
