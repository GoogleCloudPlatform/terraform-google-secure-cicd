/**
 * Copyright 2022 Google LLC
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
  attestor_iam_config = flatten([
    for env_key, env in var.deploy_branch_clusters : [
      for attestor in env.required_attestations : {
        env      = env_key
        attestor = split("/", attestor)[3]
      }
    ]
  ])

  cd_sa_required_roles = [
    "roles/clouddeploy.jobRunner",
  ]
}

# Cloud Deploy Execution Service Account
# https://cloud.google.com/deploy/docs/cloud-deploy-service-account#execution_service_account
resource "google_service_account" "clouddeploy_execution_sa" {
  project      = var.project_id
  account_id   = "clouddeploy-execution-sa"
  display_name = "clouddeploy-execution-sa"
}

resource "google_project_iam_member" "cd_sa_iam" {
  for_each = toset(local.cd_sa_required_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.clouddeploy_execution_sa.email}"
}

# Cloud Deploy Service Agent
resource "google_project_service_identity" "clouddeploy_service_agent" {
  provider = google-beta

  project = var.project_id
  service = "clouddeploy.googleapis.com"
}

resource "google_project_iam_member" "clouddeploy_service_agent_role" {
  project = var.project_id
  role    = "roles/clouddeploy.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.clouddeploy_service_agent.email}"
}

# IAM membership for Cloud Build SA to act as Cloud Deploy Execution SA
resource "google_service_account_iam_member" "cloudbuild_clouddeploy_impersonation" {
  service_account_id = google_service_account.clouddeploy_execution_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.cloudbuild_service_account}"
}

# IAM membership for Cloud Deploy Execution SA deploy to GKE
resource "google_project_iam_member" "clouddeploy_gke_dev" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/container.developer"
  member   = "serviceAccount:${google_service_account.clouddeploy_execution_sa.email}"
}

# IAM membership for Cloud Build SA to deploy to GKE
resource "google_project_iam_member" "cloudbuild_gke_dev" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/container.developer"
  member   = "serviceAccount:${var.cloudbuild_service_account}"
}

# IAM grants for deploying to GKE via Connect Gateway
# https://cloud.google.com/anthos/multicluster-management/gateway/setup#grant_roles_for_access_through_kubectl
# Cloud Deploy Execution SA deploy to cluster
resource "google_project_iam_member" "clouddeploy_gkehub_viewer" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/gkehub.viewer"
  member   = "serviceAccount:${google_service_account.clouddeploy_execution_sa.email}"
}
resource "google_project_iam_member" "clouddeploy_gkehub_gatewayadmin" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/gkehub.gatewayAdmin"
  member   = "serviceAccount:${google_service_account.clouddeploy_execution_sa.email}"
}

# Cloud Build SA to deploy to cluster
resource "google_project_iam_member" "cloudbuild_gkehub_viewer" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/gkehub.viewer"
  member   = "serviceAccount:${var.cloudbuild_service_account}"
}
resource "google_project_iam_member" "cloudbuild_gkehub_gatewayadmin" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/gkehub.gatewayAdmin"
  member   = "serviceAccount:${var.cloudbuild_service_account}"
}

# IAM membership for Binary Authorization service agents in GKE projects on attestors
resource "google_project_service_identity" "binauth_service_agent" {
  provider = google-beta
  for_each = var.deploy_branch_clusters

  project = each.value.project_id
  service = "binaryauthorization.googleapis.com"
}

resource "google_binary_authorization_attestor_iam_member" "binauthz_verifier" {
  for_each = { for entry in local.attestor_iam_config : "${entry.env}.${entry.attestor}" => entry } # turn into a map
  project  = var.project_id
  attestor = each.value.attestor
  role     = "roles/binaryauthorization.attestorsVerifier"
  member   = "serviceAccount:${google_project_service_identity.binauth_service_agent[each.value.env].email}"
}
