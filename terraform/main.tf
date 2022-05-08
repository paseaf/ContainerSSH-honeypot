terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.20.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)

  project = var.project
  region  = "europe-west3"
  zone    = "europe-west3-c"
}

resource "google_compute_network" "vpc_network" {
  name = "containerssh-network"
}
