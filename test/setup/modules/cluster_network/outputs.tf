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
  description = "Network project id."
  value       = module.cluster_vpc.project_id
}

output "subnets_self_links" {
  description = "Subnets self-links."
  value       = module.cluster_vpc.subnets_self_links
}

output "subnets_names" {
  description = "Subnets self-links."
  value       = module.cluster_vpc.subnets_names
}

output "network_self_link" {
  description = "Network self-link."
  value       = module.cluster_vpc.network_self_link
}

output "network_name" {
  description = "Network name."
  value       = module.cluster_vpc.network_name
}

output "network_id" {
  description = "Network name."
  value       = module.cluster_vpc.network_id
}
