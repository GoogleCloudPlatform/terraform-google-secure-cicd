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
  numeric = true
  upper   = false
  lower   = true
}

resource "google_kms_key_ring" "keyring" {
  name     = "attestor-key-ring-${random_string.keyring_name.id}"
  location = var.primary_location
  project  = var.project_id
  lifecycle {
    prevent_destroy = false
  }
}

module "attestors" {
  source   = "terraform-google-modules/kubernetes-engine/google//modules/binary-authorization"
  version  = "~> 42.0.0"
  for_each = toset(var.attestor_names_prefix)

  project_id    = var.project_id
  attestor-name = each.key
  keyring-id    = google_kms_key_ring.keyring.id
}
