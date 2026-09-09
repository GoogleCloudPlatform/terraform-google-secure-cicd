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
  gar_name             = split("/", google_artifact_registry_repository.image_repo.name)[length(split("/", google_artifact_registry_repository.image_repo.name)) - 1]
  cache_bucket_name    = var.cache_bucket_name == "" ? "bkt-cloudbuild" : var.cache_bucket_name
  use_csr              = var.repository_type == "CSR"
  repos                = local.use_csr ? {} : { for repo in [var.ci_repository] : repo.repository_name => repo }
  second_gen_repo_id   = local.use_csr ? null : values(module.cloudbuild_repositories[0].cloud_build_repositories_2nd_gen_repositories)[0].id
  second_gen_repo_name = local.use_csr ? null : keys(module.cloudbuild_repositories[0].cloud_build_repositories_2nd_gen_repositories)[0]
  common_substitutions = merge(
    {
      _GAR_REPOSITORY            = local.gar_name
      _DEFAULT_REGION            = var.primary_location
      _CACHE_BUCKET_NAME         = google_storage_bucket.cache_bucket.name
      _ATTESTOR_NAME             = keys(local.attestors)[0]
      _CLOUDBUILD_PRIVATE_POOL   = var.cloudbuild_private_pool
      _CLOUDDEPLOY_PIPELINE_NAME = var.clouddeploy_pipeline_name
    },
    var.additional_substitutions
  )
  attestors = {
    for attestor_name in toset(var.attestor_names_prefix) : attestor_name => {
      id = "projects/${var.project_id}/attestors/${attestor_name}"
    }
  }
}
