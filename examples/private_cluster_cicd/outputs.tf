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

output "project_id" {
  value       = var.project_id
  description = "The project to run tests against"
}

output "binauth_attestor_names" {
  description = "Names of Attestors"
  value       = module.ci_pipeline.binauth_attestor_names
}

output "binauth_attestor_project_id" {
  description = "Project ID where attestors get created"
  value       = module.ci_pipeline.binauth_attestor_project_id
}

output "boa_artifact_repo" {
  description = "GAR Repo created to store BoA images"
  value       = module.ci_pipeline.app_artifact_repo
}

output "cache_bucket_name" {
  description = "The name of the storage bucket for cloud build."
  value       = module.ci_pipeline.cache_bucket_name
}

output "build_trigger_name" {
  description = "The name of the cloud build trigger for the bank of anthos repo."
  value       = module.ci_pipeline.build_trigger_name
}

output "source_repo_names" {
  description = "Name of the created CSR repos"
  value       = module.ci_pipeline.source_repo_names
}
