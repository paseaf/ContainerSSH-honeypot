//  variables.pkr.hcl

// For those variables that you don't provide a default for, you must
// set them from the command line, a var-file, or the environment.

variable "gcp_key_file" {
  type        = string
  description = "Path to your GCP service account key file (JSON)"
  default     = "gcp.key.json"
}

variable "project_id" {
  type        = string
  description = "Your GCP project ID"
}
