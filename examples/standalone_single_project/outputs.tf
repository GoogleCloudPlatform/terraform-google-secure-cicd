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

output "project_id" {
  description = "Project ID in which all resources were deployed"
  value       = var.project_id
}

output "region" {
  description = "Region in which all regional resources were deployed"
  value       = var.region
}

output "gke_cluster_names" {
  description = "Map of GKE Cluster names by environment"
  value       = { for k, v in module.gke_cluster : k => v.name }
}

output "clouddeploy_pipeline_id" {
  description = "ID of the Cloud Deploy delivery pipeline"
  value       = module.cd_pipeline.clouddeploy_delivery_pipeline_id
}

output "cloudbuild_workerpool_id" {
  description = "ID of the Cloud Build private worker pool"
  value       = var.private_worker_pool_id == null ? module.cloudbuild_private_pool[0].workerpool_id : var.private_worker_pool_id
}

output "ci_build_trigger_id" {
  description = "ID of the CI Cloud Build trigger"
  value       = module.ci_pipeline.ci_build_trigger_id
}

output "cd_ordered_trigger_names" {
  description = "Names of CD Cloud Build triggers in promotion order"
  value       = module.cd_pipeline.deploy_trigger_names
}

output "clouddeploy_target_names_ordered" {
  description = "Names of Cloud Deploy targets in promotion order"
  value       = module.cd_pipeline.clouddeploy_target_names_ordered
}

output "gar_repo_name" {
  description = "Name of the Google Artifact Registry repository"
  value       = module.ci_pipeline.app_artifact_repo
}

output "attestors" {
  description = "Map of Binary Authorization attestor IDs by name"
  value       = module.attestors.binauth_attestor_ids
}

output "ci_repo_name" {
  description = "Name of the CI source repository"
  value       = var.repository_type == "CSR" ? module.ci_pipeline.source_repo_name : var.ci_repository.repository_name
}

output "cd_repo_name" {
  description = "Name of the CD source repository"
  value       = var.repository_type == "CSR" ? module.ci_pipeline.source_repo_name : var.cd_repository.repository_name
}

output "gitlab_url" {
  description = "The URL of the GitLab instance."
  value       = var.gitlab_auth.enterprise_host_uri
}

output "ci_repo_url" {
  description = "The URL of the CI repository."
  value       = var.ci_repository.repository_url
}

output "cd_repo_url" {
  description = "The URL of the CD repository."
  value       = var.cd_repository.repository_url
}

output "cluster_membership_ids" {
  description = "GKE cluster membership IDs."
  value       = { for k, v in module.fleet_membership : k => v.cluster_membership_id }
}

output "clouddeploy_target_ids" {
  description = "ID(s) of Cloud Deploy targets"
  value       = module.cd_pipeline.clouddeploy_target_id
}

output "ci_service_account" {
  description = "Service account created and used during the CI infra deployment"
  value       = module.ci_pipeline.build_sa_email
}
