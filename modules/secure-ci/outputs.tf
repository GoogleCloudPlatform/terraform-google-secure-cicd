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

output "cache_bucket_name" {
  description = "The name of the storage bucket for cloud build."
  value       = google_storage_bucket.cache_bucket.name
}

output "build_trigger_name" {
  description = "The name of the cloud build trigger for the app source repo."
  value       = google_cloudbuild_trigger.app_build_trigger.name
}

output "binauth_attestor_names" {
  description = "Names of Attestors"
  value       = [for attestor_name in var.attestor_names_prefix : module.attestors[attestor_name].attestor]
}

output "binauth_attestor_ids" {
  description = "IDs of Attestors"
  value       = { for attestor_name in var.attestor_names_prefix : attestor_name => "projects/${var.project_id}/attestors/${module.attestors[attestor_name].attestor}" }
}

output "binauth_attestor_project_id" {
  description = "Project ID where attestors get created"
  value       = var.project_id
}

output "app_artifact_repo" {
  description = "GAR Repo created to store runner images"
  value       = google_artifact_registry_repository.image_repo.name
}

output "source_repo_names" {
  description = "Name of the created CSR repos"
  value       = [for repo in google_sourcerepo_repository.repos : repo.name]
}

output "source_repo_urls" {
  description = "URLS of the created CSR repos"
  value       = { for repo in google_sourcerepo_repository.repos : repo.name => repo.url }
}

output "build_sa_email" {
  description = "Cloud Build Service Account email address"
  value       = google_service_account.build_sa.email
}
