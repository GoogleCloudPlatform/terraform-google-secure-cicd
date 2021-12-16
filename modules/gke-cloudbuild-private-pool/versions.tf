terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.3.0" # google_cloudbuild_worker_pool in GA requires >= 4.3.0
    }
  }
}
