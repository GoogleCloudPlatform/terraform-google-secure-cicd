/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "random_string" "keyring_name" {
  length  = 4
  special = false
  number  = true
  upper   = false
  lower   = true
}

resource "google_kms_key_ring" "keyring" {
  name     = "attestor-key-ring-${random_string.keyring_name.id}"
  location = var.primary_location
  project  = var.app_cicd_project_id
  lifecycle {
    prevent_destroy = false
  }
}

# Create a Google Secret containing the keyring name
resource "google_secret_manager_secret" "keyring-secret" {
  project   = var.app_cicd_project_id
  secret_id = google_kms_key_ring.keyring.name
  labels = {
    label = google_kms_key_ring.keyring.name
  }

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "keyring-secret-version" {
  secret      = google_secret_manager_secret.keyring-secret.id
  secret_data = google_kms_key_ring.keyring.name
}

module "attestors" {
  source   = "terraform-google-modules/kubernetes-engine/google//modules/binary-authorization"
  version  = "~> 14.1"
  for_each = toset(var.attestor_names_prefix)

  project_id    = var.app_cicd_project_id
  attestor-name = each.key
  keyring-id    = google_kms_key_ring.keyring.id
}
