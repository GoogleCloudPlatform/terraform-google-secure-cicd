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

resource "google_service_account" "clouddeploy_execution_sa" {
  project      = var.project_id
  account_id   = "clouddeploy-execution-sa"
  display_name = "clouddeploy-execution-sa"
}

resource "google_access_context_manager_access_level_condition" "additional_member_condition" {
  access_level = var.access_level_name

  members = [
    "serviceAccount:${google_service_account.clouddeploy_execution_sa.email}"
  ]
  depends_on = [
    time_sleep.wait_access_level_propagation
  ]
}

resource "google_project_iam_member" "cd_sa_iam" {
  for_each = toset(local.cd_sa_required_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.clouddeploy_execution_sa.email}"
}

resource "google_project_service_identity" "clouddeploy_service_agent" {
  provider = google-beta
  project  = var.project_id
  service  = "clouddeploy.googleapis.com"
}

resource "google_project_iam_member" "clouddeploy_service_agent_role" {
  project = var.project_id
  role    = "roles/clouddeploy.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.clouddeploy_service_agent.email}"
}

resource "google_service_account_iam_member" "cloudbuild_clouddeploy_impersonation" {
  service_account_id = google_service_account.clouddeploy_execution_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.cloudbuild_service_account}"
}

resource "google_project_iam_member" "clouddeploy_gke_dev" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/container.developer"
  member   = "serviceAccount:${google_service_account.clouddeploy_execution_sa.email}"
}

resource "google_project_iam_member" "cloudbuild_gke_dev" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/container.developer"
  member   = "serviceAccount:${var.cloudbuild_service_account}"
}

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

resource "google_service_account_iam_member" "sa_impersonate_self" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.cloudbuild_service_account}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.cloudbuild_service_account}"
}

resource "google_secret_manager_secret_iam_member" "gitlab_pat_accessor" {
  count = var.repository_type == "GITLAB" && var.gitlab_auth != null ? 1 : 0

  secret_id = var.gitlab_auth.authorizer_credential_secret_id

  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${var.cloudbuild_service_account}"
}

resource "google_project_service_identity" "clouddeploy_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "clouddeploy.googleapis.com"
}

resource "google_project_iam_member" "clouddeploy_service_agent_workerpool_access" {
  project = split("/", var.cloudbuild_private_pool)[1]
  role    = "roles/cloudbuild.workerPoolUser"
  member  = "serviceAccount:${google_project_service_identity.clouddeploy_sa.email}"
}

resource "time_sleep" "wait_access_level_propagation" {
  depends_on = [
    google_service_account.clouddeploy_execution_sa,
  ]
  destroy_duration = "5m"
  create_duration  = "2m"
}
