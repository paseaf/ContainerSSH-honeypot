//  variables.pkr.hcl

// For those variables that you don't provide a default for, you must
// set them from the command line, a var-file, or the environment.

variable "credentials" {
  type        = string
  description = "Path to your GCP service account key file (JSON)"
}
variable "project_id" {
  type        = string
  description = "Your GCP project ID"
}
