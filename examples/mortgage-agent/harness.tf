# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  bucket_name = format("%s-%s", "tfstate", random_id.project_id_suffix.hex)

  kms_key_name            = "${var.project_id}-mortgage-key-${random_id.project_id_suffix.hex}"
  terraform_state_kms_key = module.kms.keys[local.kms_key_name]

  terraform_sa_project_roles = [
    "roles/storage.admin",
    "roles/cloudkms.admin",
  ]
}

resource "random_id" "project_id_suffix" {
  byte_length = 2
}

#Enable Vertex AI API explicitly to control order and avoid race conditions
#in the project module's IAM bindings
locals {
  enabled_services = toset(var.enabled_services)

  need_api_wait = anytrue([
    for svc, d in data.http.enabled_service :
    try(jsondecode(d.response_body).state, "UNKNOWN") != "ENABLED"
  ])
}

data "google_client_config" "default" {}

data "http" "enabled_service" {
  for_each = local.enabled_services

  url = "https://serviceusage.googleapis.com/v1/projects/${var.project_id}/services/${each.value}"
  request_headers = {
    Authorization = "Bearer ${data.google_client_config.default.access_token}"
  }
}

resource "google_project_service" "enable_apis" {
  for_each = local.enabled_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "time_sleep" "wait_enable_apis" {
  count           = local.need_api_wait ? 1 : 0
  create_duration = "60s"

  depends_on = [google_project_service.enable_apis]
}

resource "google_project_service_identity" "network_services" {
  provider = google-beta
  project  = var.project_id
  service  = "networkservices.googleapis.com"
}

# Enable Vertex AI API explicitly to control order and avoid race conditions
# in the project module's IAM bindings
resource "google_project_service" "aiplatform" {
  project            = var.project_id
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

# Ensure Vertex AI service identity exists
# This must happen after the API is enabled
resource "google_project_service_identity" "aiplatform" {
  provider = google-beta
  project  = var.project_id
  service  = "aiplatform.googleapis.com"

  depends_on = [google_project_service.aiplatform]
}

resource "google_project_iam_member" "aiplatform_network_admin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_project_service_identity.aiplatform.email}"
}

resource "google_project_iam_member" "aiplatform_dns_peer" {
  project = var.project_id
  role    = "roles/dns.peer"
  member  = "serviceAccount:${google_project_service_identity.aiplatform.email}"
}

# Allow time for the AI Platform service identity to propagate before
# binding IAM roles to the Reasoning Engine service agent.
resource "time_sleep" "aiplatform_identity_propagation" {
  depends_on      = [google_project_service_identity.aiplatform]
  create_duration = "30s"
}

# The Reasoning Engine service agent (gcp-sa-aiplatform-re) also needs
# network and DNS permissions to create PSC Interface NICs and DNS peering zones.
resource "google_project_iam_member" "aiplatform_re_network_admin" {
  project    = var.project_id
  role       = "roles/compute.networkAdmin"
  member     = "serviceAccount:service-${var.project_number}@gcp-sa-aiplatform-re.iam.gserviceaccount.com"
  depends_on = [time_sleep.aiplatform_identity_propagation]
}

resource "google_project_iam_member" "aiplatform_re_dns_peer" {
  project    = var.project_id
  role       = "roles/dns.peer"
  member     = "serviceAccount:service-${var.project_number}@gcp-sa-aiplatform-re.iam.gserviceaccount.com"
  depends_on = [time_sleep.aiplatform_identity_propagation]
}

# ==============================================================================
# STORAGE CONFIGURATION
# ==============================================================================

module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "~> 4.0"

  project_id          = var.project_id
  location            = var.region
  keyring             = "${var.project_id}-mortgage-keyring-${random_id.project_id_suffix.hex}"
  keys                = [local.kms_key_name]
  key_rotation_period = "7776000s"

  prevent_destroy = var.kms_prevent_destroy
}

resource "google_project_service_identity" "storage_agent" {
  provider = google-beta

  project = var.project_id
  service = "storage.googleapis.com"

  depends_on = [time_sleep.wait_enable_apis]
}

data "google_storage_project_service_account" "storage_agent" {
  project    = var.project_id
  depends_on = [google_project_service_identity.storage_agent]
}

resource "google_kms_crypto_key_iam_member" "terraform_state_gcs_kms" {
  crypto_key_id = local.terraform_state_kms_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.storage_agent.email_address}"

  depends_on = [data.google_storage_project_service_account.storage_agent]
}

resource "google_storage_bucket" "terraform_state" {
  project                     = var.project_id
  name                        = local.bucket_name
  location                    = var.region
  force_destroy               = var.bucket_force_destroy
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }

  dynamic "encryption" {
    for_each = var.encrypt_gcs_bucket_tfstate ? ["encryption"] : []
    content {
      default_kms_key_name = local.terraform_state_kms_key
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.terraform_state_gcs_kms]
}

resource "google_project_iam_member" "project_roles" {
  for_each = toset(local.terraform_sa_project_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.terraform_service_account}"
}

resource "google_project_iam_member" "mcp_sa_impersonate" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${var.terraform_service_account}"
}
