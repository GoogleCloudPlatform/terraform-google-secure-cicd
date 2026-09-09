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

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_sourcerepo_repository" "csr_ci_repository" {
  count = local.use_csr ? 1 : 0

  project                      = var.project_id
  name                         = var.csr_app_source_repo
  create_ignore_already_exists = true
}

module "cloudbuild_repositories" {
  count = local.use_csr ? 0 : 1

  source  = "terraform-google-modules/bootstrap/google//modules/cloudbuild_repo_connection"
  version = "12.0.0"

  project_id = var.project_id

  connection_config = {
    connection_type = "${var.repository_type}v2"

    github_secret_id        = var.github_auth != null ? var.github_auth.secret_id : null
    github_app_id_secret_id = var.github_auth != null ? var.github_auth.app_id_secret_id : null

    gitlab_read_authorizer_credential_secret_id = var.gitlab_auth != null ? var.gitlab_auth.read_authorizer_credential_secret_id : null
    gitlab_authorizer_credential_secret_id      = var.gitlab_auth != null ? var.gitlab_auth.authorizer_credential_secret_id : null
    gitlab_webhook_secret_id                    = var.gitlab_auth != null ? var.gitlab_auth.webhook_secret_id : null
    gitlab_enterprise_host_uri                  = var.gitlab_auth != null ? var.gitlab_auth.enterprise_host_uri : null
    gitlab_enterprise_service_directory         = var.gitlab_auth != null ? var.gitlab_auth.enterprise_service_directory : null
    gitlab_enterprise_ca_certificate            = var.gitlab_auth != null ? var.gitlab_auth.enterprise_ca_certificate : null
  }

  cloud_build_repositories = local.repos
}

resource "google_storage_bucket" "cache_bucket" {
  project                     = var.project_id
  name                        = "${local.cache_bucket_name}-${random_string.suffix.id}"
  location                    = var.primary_location
  uniform_bucket_level_access = true
  force_destroy               = true
  versioning {
    enabled = true
  }
  labels = var.labels

  dynamic "encryption" {
    for_each = var.bucket_kms_key != null ? [1] : []
    content {
      default_kms_key_name = var.bucket_kms_key
    }
  }
}

resource "google_cloudbuild_trigger" "csr_app_build_trigger" {
  count    = local.use_csr ? 1 : 0
  project  = var.project_id
  name     = "${var.csr_app_source_repo}-trigger"
  location = var.primary_location
  trigger_template {
    branch_name = var.trigger_branch_name
    repo_name   = var.csr_app_source_repo
  }

  substitutions   = local.common_substitutions
  service_account = google_service_account.build_sa.id
  filename        = var.app_build_trigger_yaml
  depends_on = [
    google_sourcerepo_repository.csr_ci_repository,
    time_sleep.wait_for_cb_iam
  ]
}

resource "google_cloudbuild_trigger" "app_build_trigger" {
  count    = local.use_csr ? 0 : 1
  project  = var.project_id
  name     = "${local.second_gen_repo_name}-trigger"
  location = var.primary_location
  repository_event_config {
    repository = local.second_gen_repo_id
    push {
      branch = var.trigger_branch_name # Assumes the same branch for all
    }
  }

  substitutions   = local.common_substitutions
  service_account = google_service_account.build_sa.id
  filename        = var.app_build_trigger_yaml
  depends_on = [
    module.cloudbuild_repositories,
    time_sleep.wait_for_cb_iam
  ]
}

resource "google_artifact_registry_repository" "image_repo" {
  project       = var.project_id
  location      = var.primary_location
  repository_id = format("%s-%s", var.project_id, var.gar_repo_name_suffix)
  description   = "Docker repository for application images"
  format        = "DOCKER"
  labels        = var.labels
  vulnerability_scanning_config {
    enablement_config = "INHERITED"
  }
}

resource "google_artifact_registry_repository_iam_member" "terraform-image-iam" {
  project    = var.project_id
  location   = google_artifact_registry_repository.image_repo.location
  repository = google_artifact_registry_repository.image_repo.name
  role       = "roles/artifactregistry.admin"
  member     = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "google_project_service" "containerscanning_api" {
  project = var.project_id

  service = "containerscanning.googleapis.com"
}
