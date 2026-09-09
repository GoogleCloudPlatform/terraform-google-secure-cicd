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

output "cache_bucket_name" {
  description = "The name of the storage bucket for cloud build."
  value       = google_storage_bucket.cache_bucket.name
}

output "binauth_attestor_names" {
  description = "Names of Attestors"
  value       = keys(local.attestors)
}

output "binauth_attestor_ids" {
  description = "IDs of Attestors"
  value       = { for key, attestor in local.attestors : key => attestor.id }
}

output "binauth_attestor_project_id" {
  description = "Project ID where attestors get created"
  value       = var.project_id
}

output "app_artifact_repo" {
  description = "GAR Repo created to store runner images"
  value       = google_artifact_registry_repository.image_repo.name
}

output "source_repo_name" {
  description = "Name of the created CSR repos"
  value       = local.use_csr ? google_sourcerepo_repository.csr_ci_repository[0].name : null
}

output "source_repo_url" {
  description = "URLS of the created CSR repos"
  value       = local.use_csr ? google_sourcerepo_repository.csr_ci_repository[0].url : null
}

output "build_sa_email" {
  description = "Cloud Build Service Account email address"
  value       = google_service_account.build_sa.email
}

output "standalone_bucket_kms_key" {
  description = "KMS Key for standalone bucket."
  value       = var.bucket_kms_key
}

output "skaffold_builder_image_tag" {
  description = "The full path to the built Skaffold builder image in Artifact Registry."
  value       = local.skaffold_builder_image_tag
}

output "ci_build_trigger_id" {
  description = "ID of the CI Cloud Build trigger."
  value       = google_cloudbuild_trigger.app_build_trigger[0].id
}
