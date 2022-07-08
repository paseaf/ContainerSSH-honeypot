# GCP has implied rules: allow all egress; deny all ingress
# https://cloud.google.com/vpc/docs/firewalls#default_firewall_rules
locals {
  ports = {
    cadvisor      = "8088"
    node_exporter = "9100"
    prometheus    = "9091"
    minio_server  = "9000"
    minio_console = "9090"
    grafana       = "3000"
    docker_tls    = "2376"
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
  target_tags   = ["gateway"]
}

resource "google_compute_firewall" "allow_all_to_logger_vm_grafana" {
  name    = "allow-all-to-logger-vm-grafana"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = [local.ports.grafana]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["logger"]
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
  target_tags   = ["logger"]
}

resource "google_compute_firewall" "allow_all_to_logger_vm_prometheus" {
  name    = "allow-all-to-logger-vm-prometheus"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports = [
      local.ports.prometheus
    ]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["logger"]
}

resource "google_compute_firewall" "allow_logger_vm_to_network_cadvisor" {
  name    = "allow-logger-vm-to-network-cadvisor"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = [local.ports.cadvisor]
  }
  source_tags = ["logger"]
}

resource "google_compute_firewall" "allow_logger_vm_to_network_node_exporter" {
  name    = "allow-logger-vm-to-network-node-exporter"
  network = google_compute_network.main.self_link

  allow {
    protocol = "tcp"
    ports    = [local.ports.node_exporter]
  }

  source_tags = ["logger"]
}

resource "google_compute_firewall" "deny_sacrificial_vm_to_all" {
  name               = "deny-sacrificial-vm-to-all"
  description        = "Deny all outgoing connection from sacrificial host"
  network            = google_compute_network.main.name
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["sacrificial"]
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
  source_tags = ["gateway"]
  target_tags = ["sacrificial"]
}
