/**
 * Copyright 2019 Google LLC
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
  value = module.project.project_id
}

output "project_id_standalone" {
  value = module.project_standalone.project_id
}

output "sa_key" {
  value     = google_service_account_key.int_test.private_key
  sensitive = true
}

output "folder_id" {
  value = var.folder_id
}

output "org_id" {
  value = var.org_id
}

output "billing_account" {
  value = var.billing_account
}

output "gke_project_ids" {
  description = "List of GKE project IDs"
  value       = zipmap(local.envs, [for env in local.envs : module.gke_project[env].project_id])
}

output "gke_vpc_names" {
  description = "List of GKE project IDs"
  value       = zipmap(local.envs, [for env in local.envs : module.vpc[env].network_name])
}

output "gke_service_accounts" {
  description = "List of GKE service accounts"
  value       = zipmap(local.envs, [for env in local.envs : module.gke_cluster[env].service_account])
}

output "gke_cluster_names" {
  description = "List of GKE clusters"
  value       = zipmap(local.envs, [for env in local.envs : module.gke_cluster[env].name])
}

output "gke_private_vpc_names" {
  description = "List of GKE project IDs"
  value       = zipmap(local.envs, [for env in local.envs : module.vpc_private_cluster[env].network_name])
}

output "gke_private_service_accounts" {
  description = "List of GKE private cluster service accounts"
  value       = zipmap(local.envs, [for env in local.envs : module.gke_private_cluster[env].service_account])
}

output "gke_private_cluster_names" {
  description = "List of GKE private clusters"
  value       = zipmap(local.envs, [for env in local.envs : module.gke_private_cluster[env].name])
}
