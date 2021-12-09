terraform {
  required_providers {
    google-beta = {
        source  = "hashicorp/google-beta"
        version = "~> 4.3.0" # google_cloudbuild_worker_pool in GA requires > 4.3.0
    }
  }
}