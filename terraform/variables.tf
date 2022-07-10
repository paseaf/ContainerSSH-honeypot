variable "project" {
  type        = string
  description = "Your GCP project ID"
}

variable "credentials" {
  type        = string
  description = "Path to your GCP service account key file (JSON)"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}
