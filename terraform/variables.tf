variable "project_id" {
  type        = string
  description = "Your GCP project ID"
}

variable "gcp_key_file" {
  type        = string
  description = "Path to your GCP service account key file (JSON)"
  default     = "gcp.key.json"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}
