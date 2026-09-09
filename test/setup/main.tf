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

locals {
  envs             = ["dev", "qa", "prod"]
  primary_location = "us-central1"
  ip_increment = {
    "dev"  = 1,
    "qa"   = 2,
    "prod" = 3
  }
}

module "folder_seed" {
  source              = "terraform-google-modules/folders/google"
  version             = "~> 5.1"
  prefix              = random_string.prefix.result
  parent              = "folders/${var.folder_id}"
  names               = ["seed"]
  deletion_protection = false
}

resource "random_string" "prefix" {
  length  = 6
  special = false
  upper   = false
}

module "project_standalone" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = "secure-cicd-singleproj"
  random_project_id       = "true"
  org_id                  = var.org_id
  folder_id               = module.folder_seed.id
  billing_account         = var.billing_account
  default_service_account = "keep"

  activate_apis = [
    "accesscontextmanager.googleapis.com",
    "aiplatform.googleapis.com",
    "anthos.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "anthospolicycontroller.googleapis.com",
    "apikeys.googleapis.com",
    "artifactregistry.googleapis.com",
    "binaryauthorization.googleapis.com",
    "certificatemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerscanning.googleapis.com",
    "gkehub.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "mesh.googleapis.com",
    "modelarmor.googleapis.com",
    "monitoring.googleapis.com",
    "multiclusteringress.googleapis.com",
    "multiclusterservicediscovery.googleapis.com",
    "networkmanagement.googleapis.com",
    "networkservices.googleapis.com",
    "notebooks.googleapis.com",
    "orgpolicy.googleapis.com",
    "secretmanager.googleapis.com",
    "servicedirectory.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "sourcerepo.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "trafficdirector.googleapis.com",
  ]
  activate_api_identities = [
    {
      api = "cloudbuild.googleapis.com"
      roles = [
        "roles/storage.admin",
        "roles/artifactregistry.admin",
        "roles/cloudbuild.builds.builder",
        "roles/binaryauthorization.attestorsVerifier",
        "roles/cloudkms.cryptoOperator",
        "roles/containeranalysis.notes.attacher",
        "roles/containeranalysis.notes.occurrences.viewer",
        "roles/source.writer",
      ]
    },
    {
      api   = "artifactregistry.googleapis.com",
      roles = []
    }
  ]
}

resource "random_string" "kms_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_project_service_identity" "gcs_sa" {
  provider   = google-beta
  project    = module.project_standalone.project_id
  service    = "storage.googleapis.com"
  depends_on = [module.project_standalone]
}

resource "google_kms_key_ring" "standalone_keyring" {
  name       = "standalone-keyring-${random_string.kms_suffix.result}"
  location   = local.primary_location
  project    = module.project_standalone.project_id
  depends_on = [google_project_service_identity.gcs_sa]
}

resource "google_kms_crypto_key" "standalone_bucket_key" {
  name            = "standalone-bucket-key"
  key_ring        = google_kms_key_ring.standalone_keyring.id
  rotation_period = "7776000s"
}

resource "google_kms_crypto_key_iam_member" "standalone_gcs_sa_kms" {
  crypto_key_id = google_kms_crypto_key.standalone_bucket_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${module.project_standalone.project_number}@gs-project-accounts.iam.gserviceaccount.com"
  depends_on    = [google_project_service_identity.gcs_sa]
}
