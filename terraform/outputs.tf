output "vm_ip_addresses" {
  description = "VM external IP address"
  value = {
    "gateway_vm"     = google_compute_instance.gateway_vm.network_interface.0.access_config.0.nat_ip
    "sacrificial_vm" = google_compute_instance.sacrificial_vm.network_interface.0.access_config.0.nat_ip
    "logger_vm"      = google_compute_instance.logger_vm.network_interface.0.access_config.0.nat_ip
  }
}

output "grafana" {
  value = "http://${google_compute_instance.logger_vm.network_interface.0.access_config.0.nat_ip}:3000/"
}

output "minio_console" {
  value = "http://${google_compute_instance.logger_vm.network_interface.0.access_config.0.nat_ip}:9090/"
}

output "prometheus" {
  value = "http://${google_compute_instance.logger_vm.network_interface.0.access_config.0.nat_ip}:19091/"
}
