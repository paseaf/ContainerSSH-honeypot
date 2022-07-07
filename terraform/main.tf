provider "google" {
  project = var.project
  region  = "europe-west3"
  zone    = "europe-west3-c"

  credentials = file(var.credentials)
}

resource "google_compute_network" "main" {
  name                    = "containerssh"
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

resource "google_compute_firewall" "containerssh_allow_all" {
  name    = "containerssh-allow-all"
  network = google_compute_network.main.self_link

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "containerssh_allow_ssh" {
  name    = "containerssh-allow-ssh"
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

# open port 3000 for Grafana, 9000 and 9090 for MinIO on our logger-vm
resource "google_compute_firewall" "firewall_logger_view" {
  name    = "firewall-logger-view"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = ["3000", "9000", "9090"]
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
    ports    = ["8088", "9100", "9101"]
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

# open sacrificial-port 8088 for cadvisor and 9100 for node-exporter
resource "google_compute_firewall" "firewall_sacrificial_nodeexport" {
  name    = "firewall-sacrificial-nodeexport"
  network = google_compute_network.main.self_link

  allow {
    protocol = "tcp"
    ports    = ["8088", "9100"]
  }

  target_tags = ["sacrificial"]
  source_tags = ["observer"]
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

  provisioner "remote-exec" {
    scripts = [
      "./scripts/run_cadvisor.sh"
    ]
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
      size  = 200
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

  provisioner "local-exec" {
    command     = "./generate_credentials.sh"
    interpreter = ["/bin/bash"]
  }

  provisioner "file" {
    source      = "./credentials.txt" # relative to terraform work_dir
    destination = "./.env"            # relative to remote $HOME
  }

  provisioner "file" {
    source      = "./files/prometheus.yml" # relative to terraform work_dir
    destination = "./prometheus.yml"       # relative to remote $HOME
  }

  provisioner "file" {
    source      = "./grafana" # relative to terraform work_dir
    destination = "./"        # relative to remote $HOME
  }

  provisioner "remote-exec" {
    scripts = [
      "./scripts/run_cadvisor.sh",
      "./scripts/run_minio.sh",
      "./scripts/run_prometheus.sh",
      "./scripts/run_grafana.sh"
    ]
  }
}

# Note: provisioner in this block only runs after all previous provisioners are finished
resource "null_resource" "set_up_docker_tls_and_containerssh" {
  # 1. Create CA and client keys; Set up Docker TLS on Sacrificial VM
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "deployer"
      private_key = file("./deployer_key")
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
      private_key = file("./deployer_key")
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
      private_key = file("./deployer_key")
      host        = google_compute_instance.gateway_vm.network_interface.0.access_config.0.nat_ip
    }

    scripts = [
      "./scripts/set_up_and_run_containerssh.sh",
      "./scripts/remap_ssh_ports.sh"
    ]
  }
}
