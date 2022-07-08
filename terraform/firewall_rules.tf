# GCP has implied rules: allow all egress; deny all ingress
# https://cloud.google.com/vpc/docs/firewalls#default_firewall_rules
locals {
  internal_ip_ranges = ["10.128.0.0/9"]
  ports = {
    cadvisor      = "8088"
    node_exporter = "9100"
    prometheus    = "9091"
    minio_server  = "9000"
    minio_console = "9090"
    grafana       = "3000"
  }
}

## Network-wide rules
resource "google_compute_firewall" "allow_icmp" {
  name    = "allow-icmp"
  network = google_compute_network.main.self_link
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "internal_allow_metrics" {
  name    = "internal-allow-metrics"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = [local.ports.cadvisor, local.ports.node_exporter]
  }
  source_tags = ["logger"]
}

resource "google_compute_firewall" "internal_allow_node_exporter" {
  name    = "allow-internal-cadvisor"
  network = google_compute_network.main.self_link
  allow {
    protocol = "tcp"
    ports    = ["8088"]
  }
  source_ranges = local.internal_ip_ranges
}

resource "google_compute_firewall" "internal_allow_ssh" {
  name    = "internal-allow-ssh"
  network = google_compute_network.main.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = local.internal_ip_ranges
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
