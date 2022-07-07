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
