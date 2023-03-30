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

module "example" {
  source = "../../../examples/app_cicd"

  project_id       = var.project_id
  primary_location = var.primary_location
  deploy_branch_clusters = {
    "01-dev" = {
      cluster               = "dev-cluster",
      anthos_membership     = ""
      project_id            = var.gke_project_ids["dev"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/security-attestor"
      next_env              = "qa"
      target_type           = "gke"
    },
    "02-qa" = {
      cluster               = "qa-cluster",
      anthos_membership     = ""
      project_id            = var.gke_project_ids["qa"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/quality-attestor"
      next_env              = "prod"
      target_type           = "gke"
    },
    "03-prod" = {
      cluster               = "prod-cluster",
      anthos_membership     = ""
      project_id            = var.gke_project_ids["prod"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/quality-attestor", "projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = ""
      next_env              = ""
      target_type           = "gke"
    },
  }
}

resource "google_project_iam_member" "cluster_service_account-gcr" {
  for_each = var.gke_service_accounts
  project  = var.project_id
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${each.value}"
}

resource "google_project_iam_member" "cluster_service_account-artifact-registry" {
  for_each = var.gke_service_accounts
  project  = var.project_id
  role     = "roles/artifactregistry.reader"
  member   = "serviceAccount:${each.value}"
}
