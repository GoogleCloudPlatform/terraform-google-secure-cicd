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

output "workerpool_id" {
  value       = google_cloudbuild_worker_pool.pool.id
  description = "Cloud Build worker pool ID"
}

output "workerpool_range" {
  value       = "${google_compute_global_address.worker_range.address}/${google_compute_global_address.worker_range.prefix_length}"
  description = "IP Address range for Cloud Build worker pool"
}

output "workerpool_network" {
  value       = var.create_cloudbuild_network ? google_compute_network.private_pool_vpc[0].self_link : data.google_compute_network.workerpool_vpc[0].self_link
  description = "Self Link for Cloud Build workerpool VPC network"
}
