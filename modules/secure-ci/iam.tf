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
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_service_account" "build_sa" {
  account_id   = "build-sa"
  display_name = "Service Account for ${var.csr_app_source_repo} Cloud Build triggers"
  project      = var.project_id
}

resource "google_project_service_identity" "cloudbuild_service_identity" {
  provider = google-beta

  project = var.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service_identity" "cloud_deploy_sa" {
  provider = google-beta

  project = var.project_id
  service = "clouddeploy.googleapis.com"
}

resource "google_project_service_identity" "pubsub_sa" {
  provider = google-beta

  project = var.project_id
  service = "pubsub.googleapis.com"
}

resource "google_access_context_manager_access_level_condition" "access-level-conditions" {
  count        = var.access_level_name != null ? 1 : 0
  access_level = var.access_level_name
  members = [
    google_project_service_identity.cloudbuild_service_identity.member,
    google_project_service_identity.cloud_deploy_sa.member,
    google_project_service_identity.pubsub_sa.member,
    google_service_account.build_sa.member,
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  ]

  depends_on = [
    time_sleep.wait_access_level_propagation
  ]
}

resource "google_project_iam_member" "int_test_secret_viewer" {
  count   = var.repository_type == "GITLAB" ? 1 : 0
  project = var.project_id
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "google_storage_bucket_iam_member" "cloudbuild_artifacts_iam" {
  bucket     = google_storage_bucket.cache_bucket.name
  role       = "roles/storage.admin"
  member     = "serviceAccount:${google_service_account.build_sa.email}"
  depends_on = [google_storage_bucket.cache_bucket]
}

resource "google_project_iam_member" "build_sa_project_iam" {
  for_each = toset(var.cloudbuild_service_account_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "google_project_iam_member" "cloudbuild_sa_connection_viewer" {
  project = var.project_id
  role    = "roles/cloudbuild.connectionViewer"

  member = "serviceAccount:${google_project_service_identity.cloudbuild_service_identity.email}"
}

resource "time_sleep" "wait_for_cb_iam" {
  depends_on      = [google_project_iam_member.cloudbuild_sa_connection_viewer]
  create_duration = "30s"
}

resource "time_sleep" "wait_access_level_propagation" {
  depends_on = [
    google_project_service_identity.cloudbuild_service_identity,
    google_project_service_identity.cloud_deploy_sa,
    google_project_service_identity.pubsub_sa,
    google_service_account.build_sa,
  ]
  destroy_duration = "5m"
  create_duration  = "2m"
}
