/**
 * Copyright 2026 Google LLC
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

resource "random_string" "prefix" {
  length  = 6
  special = false
  upper   = false
}

module "logging_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 10.0"

  name          = "bkt-logging-${random_string.prefix.result}"
  project_id    = var.project_id_standalone
  location      = var.region
  force_destroy = true

  versioning = true
  encryption = { default_kms_key_name = module.kms.keys["bucket"] }
}

resource "google_storage_bucket_iam_member" "logging_storage_admin" {
  for_each = { "admin_ci" : "serviceAccount:${var.sa_email}" }
  bucket   = module.logging_bucket.name
  role     = "roles/storage.admin"
  member   = each.value
}

data "google_storage_project_service_account" "ci_gcs_account" {
  project = var.project_id_standalone
}

module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "~> 4.0"

  project_id     = var.project_id_standalone
  location       = var.region
  keyring        = "kms-bucket-encryption"
  keys           = ["bucket"]
  set_owners_for = ["bucket"]
  owners = [
    "serviceAccount:${var.sa_email}",
  ]
  set_encrypters_for = ["bucket"]
  encrypters = [
    "${data.google_storage_project_service_account.ci_gcs_account.member},${"serviceAccount:${var.sa_email}"},serviceAccount:${var.cloud_build_sa}",
  ]
  set_decrypters_for = ["bucket"]
  decrypters = [
    "${data.google_storage_project_service_account.ci_gcs_account.member},${"serviceAccount:${var.sa_email}"},serviceAccount:${var.cloud_build_sa}",
  ]
  prevent_destroy = false
}

module "kms_attestor" {
  source  = "terraform-google-modules/kms/google"
  version = "~> 4.0"

  project_id          = var.project_id_standalone
  location            = var.region
  keyring             = "kms-attestation-sign"
  keys                = ["attestation"]
  set_owners_for      = ["attestation"]
  purpose             = "ASYMMETRIC_SIGN"
  key_algorithm       = "RSA_SIGN_PKCS1_4096_SHA512"
  key_rotation_period = null
  owners = [
    "serviceAccount:${var.sa_email}",
  ]
  set_encrypters_for = ["attestation"]
  encrypters = [
    "${data.google_storage_project_service_account.ci_gcs_account.member},${"serviceAccount:${var.sa_email}"},serviceAccount:${var.cloud_build_sa}",
  ]
  set_decrypters_for = ["attestation"]
  decrypters = [
    "${data.google_storage_project_service_account.ci_gcs_account.member},${"serviceAccount:${var.sa_email}"},serviceAccount:${var.cloud_build_sa}",
  ]
  prevent_destroy = false
}
