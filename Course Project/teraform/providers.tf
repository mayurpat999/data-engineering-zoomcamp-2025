# providers.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Use a recent version
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}