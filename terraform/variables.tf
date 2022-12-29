variable "project_id" {
  type        = string
  description = "Your GCP project ID"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}
