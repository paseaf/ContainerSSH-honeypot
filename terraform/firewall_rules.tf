# Firewall rules naming convention:
# "action_source_to_destination_service/port"

locals {
  ports = {
    cadvisor             = "8088"
    node_exporter        = "9100"
    prometheus           = "9091"
    prometheus_auth      = "19091"
    minio_server         = "9000"
    minio_console        = "9090"
    grafana              = "3000"
    docker_tls           = "2376"
    containerssh_metrics = "9101"
  }
  tags = {
    gateway_vm     = "gateway"
    logger_vm      = "logger"
    sacrificial_vm = "sacrificial"
  }
}

resource "google_compute_firewall" "allow_all_to_network_icmp" {
  name    = "allow-all-to-network-icmp"
  network = google_compute_network.main.self_link
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_all_to_network_ssh" {
  name    = "allow-all-to-network-ssh"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_all_to_gateway_vm_2333" {
  name        = "allow-all-to-gateway-vm-2333"
  description = "Allow access to Gateway VM's SSH server on port 2333"
  network     = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = ["2333"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.tags.gateway_vm]
}

resource "google_compute_firewall" "allow_all_to_logger_vm_grafana" {
  name    = "allow-all-to-logger-vm-grafana"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = [local.ports.grafana]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.tags.logger_vm]
}

resource "google_compute_firewall" "allow_all_to_logger_vm_minio" {
  name    = "allow-all-to-logger-vm-minio"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports = [
      local.ports.minio_console,
      local.ports.minio_server
    ]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.tags.logger_vm]
}

resource "google_compute_firewall" "allow_all_to_logger_vm_prometheus_auth" {
  name    = "allow-all-to-logger-vm-prometheus-auth"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports = [
      local.ports.prometheus_auth
    ]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.tags.logger_vm]
}

resource "google_compute_firewall" "allow_logger_vm_to_network_cadvisor" {
  name    = "allow-logger-vm-to-network-cadvisor"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = [local.ports.cadvisor]
  }
  source_tags = [local.tags.logger_vm]
}

resource "google_compute_firewall" "allow_logger_vm_to_network_node_exporter" {
  name    = "allow-logger-vm-to-network-node-exporter"
  network = google_compute_network.main.self_link

  allow {
    protocol = "tcp"
    ports    = [local.ports.node_exporter]
  }

  source_tags = [local.tags.logger_vm]
}

resource "google_compute_firewall" "allow_logger_vm_to_gateway_vm_containerssh_metrics" {
  name    = "allow-logger-vm-to-gateway-vm-containerssh-metrics"
  network = google_compute_network.main.self_link

  allow {
    protocol = "tcp"
    ports    = [local.ports.containerssh_metrics]
  }

  source_tags = [local.tags.logger_vm]
  target_tags = [local.tags.gateway_vm]
}

resource "google_compute_firewall" "deny_sacrificial_vm_to_all" {
  name               = "deny-sacrificial-vm-to-all"
  description        = "Deny all outgoing connection from sacrificial host"
  network            = google_compute_network.main.name
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = [local.tags.sacrificial_vm]
  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_gateway_vm_to_sacrificial_vm_docker_tls" {
  name    = "allow-gateway-vm-to-sacrificial-vm-docker-tls"
  network = google_compute_network.main.name
  allow {
    protocol = "tcp"
    ports    = [local.ports.docker_tls]
  }
  source_tags = [local.tags.gateway_vm]
  target_tags = [local.tags.sacrificial_vm]
}
