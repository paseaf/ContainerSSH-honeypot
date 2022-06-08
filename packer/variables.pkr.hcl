//  variables.pkr.hcl

// For those variables that you don't provide a default for, you must
// set them from the command line, a var-file, or the environment.

variable "project_id" {
  type    = string
  default = "containerssh-352007"
  // Sensitive vars are hidden from output as of Packer v1.6.5
  sensitive = true
}
