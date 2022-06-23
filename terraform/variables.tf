variable "project" {
  type        = string
  description = "Your GCP project ID"
  default     = "containerssh-352007"
}

variable "credentials" {
  type        = string
  description = "Path to your GCP service account key file (JSON)"
  default     = "gcp.key.json"
}

variable "machine_type" {
  type    = string
  default = "e2-small"
}
