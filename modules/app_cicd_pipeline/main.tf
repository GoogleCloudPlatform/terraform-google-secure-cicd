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
  created_csrs = toset([for repo in google_sourcerepo_repository.app_infra_repo : repo.name])
  gar_name     = split("/", google_artifact_registry_repository.image_repo.name)[length(split("/", google_artifact_registry_repository.image_repo.name)) - 1]
  folders      = ["cache/.m2/.ignore", "cache/.skaffold/.ignore", "cache/.cache/pip/wheels/.ignore"]
}

data "google_project" "app_cicd_project" {
  project_id = var.project_id
}

resource "google_sourcerepo_repository" "app_infra_repo" {
  for_each = toset(var.app_cicd_repos)
  project  = var.project_id
  name     = each.key
}

resource "google_storage_bucket" "cache_bucket" {
  project                     = var.project_id
  name                        = "${var.project_id}_cloudbuild"
  location                    = var.primary_location
  uniform_bucket_level_access = true
  force_destroy               = true
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_object" "cache_bucket_folders" {
  for_each = toset(local.folders)
  name     = each.value
  content  = "/n"
  bucket   = google_storage_bucket.cache_bucket.name
}

resource "google_storage_bucket_iam_member" "cloudbuild_artifacts_iam" {
  bucket     = google_storage_bucket.cache_bucket.name
  role       = "roles/storage.admin"
  member     = "serviceAccount:${data.google_project.app_cicd_project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [google_storage_bucket.cache_bucket]
}

resource "google_cloudbuild_trigger" "boa_build_trigger" {
  project = var.project_id
  name    = "${var.boa_build_repo}-trigger"
  trigger_template {
    branch_name = ".*"
    repo_name   = var.boa_build_repo
  }
  substitutions = {
    _GAR_REPOSITORY    = local.gar_name
    _DEFAULT_REGION    = var.primary_location
    _CACHE_BUCKET_NAME = google_storage_bucket.cache_bucket.name
  }
  filename   = var.build_app_yaml
  depends_on = [google_sourcerepo_repository.app_infra_repo]
}

resource "null_resource" "cloudbuild_image_builder" {
  triggers = {
    project_id_cloudbuild_project = var.project_id
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit ${path.module}/cloud-build-builder/ \
      --project ${var.project_id} \
      --config=${path.module}/cloud-build-builder/${var.build_image_yaml} \
      --substitutions=_DEFAULT_REGION=${var.primary_location},_GAR_REPOSITORY=${local.gar_name}
  EOT
  }
}

resource "google_artifact_registry_repository" "image_repo" {
  provider      = google-beta
  project       = var.project_id
  location      = var.primary_location
  repository_id = format("%s-%s", var.project_id, var.gar_repo_name_suffix)
  description   = "Docker repository for application images"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "terraform-image-iam" {
  provider   = google-beta
  project    = var.project_id
  location   = google_artifact_registry_repository.image_repo.location
  repository = google_artifact_registry_repository.image_repo.name
  role       = "roles/artifactregistry.admin"
  member     = "serviceAccount:${data.google_project.app_cicd_project.number}@cloudbuild.gserviceaccount.com"
}
