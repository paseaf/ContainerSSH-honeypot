resource "google_compute_instance" "gateway_vm" {
  name         = "gateway-vm"
  machine_type = var.machine_type
  tags         = [local.tags.gateway_vm]

  boot_disk {
    initialize_params {
      image = "ubuntu-with-docker-image"
      size  = 20
      type  = "pd-balanced"
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
    private_key = "${file("~/.ssh/google_compute_engine")}"
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
  tags         = [local.tags.sacrificial_vm]
  boot_disk {
    initialize_params {
      image = "sacrificial-vm-image"
      size  = 20
      type  = "pd-balanced"
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
  tags         = [local.tags.logger_vm]

  boot_disk {
    initialize_params {
      image = "ubuntu-with-docker-image"
      size  = 200
      type  = "pd-balanced"
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
    private_key = "${file("~/.ssh/google_compute_engine")}"
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
    source      = "./files/grafana" # relative to terraform work_dir
    destination = "./"              # relative to remote $HOME
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
