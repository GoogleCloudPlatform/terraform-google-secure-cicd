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

output "subnets_self_links" {
  description = "The self-links of the created subnets."
  value       = module.vpc.subnets_self_links
}

output "network_name" {
  description = "The name of the created network."
  value       = module.vpc.network_name
}
output "network_id" {
  description = "The ID of the created network."
  value       = module.vpc.network_id
}

output "project_id" {
  description = "The project ID of the network."
  value       = module.vpc.project_id
}
