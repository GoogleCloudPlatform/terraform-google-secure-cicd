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

locals {
  gar_name          = split("/", google_artifact_registry_repository.image_repo.name)[length(split("/", google_artifact_registry_repository.image_repo.name)) - 1]
  cache_bucket_name = var.cache_bucket_name == "" ? "${var.project_id}-cloudbuild" : "${var.project_id}-${var.cache_bucket_name}"
}

resource "google_sourcerepo_repository" "repos" {
  for_each = toset([var.cloudbuild_cd_repo, var.app_source_repo])
  name     = each.key
  project  = var.project_id
}

resource "google_storage_bucket" "cache_bucket" {
  project                     = var.project_id
  name                        = local.cache_bucket_name
  location                    = var.primary_location
  uniform_bucket_level_access = true
  force_destroy               = true
  versioning {
    enabled = true
  }
  labels = var.labels
}

resource "google_service_account" "build_sa" {
  account_id   = "build-sa"
  display_name = "Service Account for ${var.app_source_repo} Cloud Build triggers"
  project      = var.project_id
}

resource "google_storage_bucket_iam_member" "cloudbuild_artifacts_iam" {
  bucket     = google_storage_bucket.cache_bucket.name
  role       = "roles/storage.admin"
  member     = "serviceAccount:${google_service_account.build_sa.email}"
  depends_on = [google_storage_bucket.cache_bucket]
}

resource "google_cloudbuild_trigger" "app_build_trigger" {
  project  = var.project_id
  name     = "${var.app_source_repo}-trigger"
  location = var.primary_location
  trigger_template {
    branch_name = var.trigger_branch_name
    repo_name   = var.app_source_repo
  }
  substitutions = merge(
    {
      _GAR_REPOSITORY            = local.gar_name
      _DEFAULT_REGION            = var.primary_location
      _CACHE_BUCKET_NAME         = google_storage_bucket.cache_bucket.name
      _ATTESTOR_NAME             = module.attestors[var.attestor_names_prefix[0]].attestor
      _CLOUDBUILD_PRIVATE_POOL   = var.cloudbuild_private_pool
      _CLOUDDEPLOY_PIPELINE_NAME = var.clouddeploy_pipeline_name
    },
    var.additional_substitutions
  )
  service_account = google_service_account.build_sa.id
  filename        = var.app_build_trigger_yaml
  depends_on      = [google_sourcerepo_repository.repos]
}

# Build the Cloud Build builder image
module "gcloud" {
  source                            = "terraform-google-modules/gcloud/google"
  count                             = var.skip_provisioners ? 0 : 1
  version                           = "~> 4.0.0"
  platform                          = "linux"
  create_cmd_entrypoint             = "${path.module}/scripts/cloud-build-submit.sh"
  create_cmd_body                   = "${var.runner_build_folder} ${var.project_id} ${var.build_image_config_yaml} ${var.primary_location} ${local.gar_name} ${google_storage_bucket.cache_bucket.url}/source"
  use_tf_google_credentials_env_var = var.use_tf_google_credentials_env_var
}

# Cloud Build Service Account permissions
resource "google_project_iam_member" "build_sa_project_iam" {
  for_each = toset(var.cloudbuild_service_account_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "google_artifact_registry_repository" "image_repo" {
  provider      = google-beta
  project       = var.project_id
  location      = var.primary_location
  repository_id = format("%s-%s", var.project_id, var.gar_repo_name_suffix)
  description   = "Docker repository for application images"
  format        = "DOCKER"
  labels        = var.labels
}

resource "google_artifact_registry_repository_iam_member" "terraform-image-iam" {
  provider   = google-beta
  project    = var.project_id
  location   = google_artifact_registry_repository.image_repo.location
  repository = google_artifact_registry_repository.image_repo.name
  role       = "roles/artifactregistry.admin"
  member     = "serviceAccount:${google_service_account.build_sa.email}"
}
