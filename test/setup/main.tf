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

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name              = "ci-secure-cicd"
  random_project_id = "true"
  org_id            = var.org_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "clouddeploy.googleapis.com",
    "storage-api.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "sourcerepo.googleapis.com",
    "artifactregistry.googleapis.com",
    "containeranalysis.googleapis.com",
    "cloudkms.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containerscanning.googleapis.com",
    "servicenetworking.googleapis.com",
    "pubsub.googleapis.com",
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
  ]
}

locals {
  envs = ["dev", "qa", "prod"]
}

# GKE Projects
module "gke_project" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/project-factory/google"
  version  = "~> 11.0"

  name                    = "secure-cicd-gke-${each.value}"
  random_project_id       = "true"
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "keep"

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "storage-api.googleapis.com",
    "serviceusage.googleapis.com",
    "containerregistry.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "containeranalysis.googleapis.com",
    "cloudkms.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containerscanning.googleapis.com",
    "container.googleapis.com",
    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
}





