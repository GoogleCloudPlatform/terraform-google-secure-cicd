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

# Networking config
resource "google_project_service" "servicenetworking" {
  project            = var.network_project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service_identity" "servicenetworking_agent" {
  provider = google-beta

  project = var.network_project_id
  service = "servicenetworking.googleapis.com"
}

resource "google_project_iam_member" "servicenetworking_agent" {
  project = var.network_project_id
  role    = "roles/servicenetworking.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.servicenetworking_agent.email}"
}

resource "google_compute_network" "private_pool_vpc" {
  count = var.create_cloudbuild_network ? 1 : 0

  name                    = var.private_pool_vpc_name
  project                 = var.network_project_id
  auto_create_subnetworks = false
  depends_on              = [google_project_service.servicenetworking]
}

data "google_compute_network" "workerpool_vpc" {
  count   = var.create_cloudbuild_network ? 0 : 1
  name    = var.private_pool_vpc_name
  project = var.network_project_id
}

resource "google_compute_global_address" "worker_range" {
  provider = google-beta # labels support require google-beta

  name          = var.worker_range_name
  project       = var.network_project_id
  labels        = var.labels
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = var.worker_address
  prefix_length = var.worker_address_prefix_length
  network       = var.create_cloudbuild_network ? google_compute_network.private_pool_vpc[0].id : data.google_compute_network.workerpool_vpc[0].id
}

resource "google_service_networking_connection" "worker_pool_connection" {
  network                 = var.create_cloudbuild_network ? google_compute_network.private_pool_vpc[0].id : data.google_compute_network.workerpool_vpc[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.worker_range.name]
  depends_on              = [google_project_service.servicenetworking, google_project_iam_member.servicenetworking_agent]
}

resource "google_compute_network_peering_routes_config" "service_networking_peering_config" {
  project = var.network_project_id
  peering = google_service_networking_connection.worker_pool_connection.peering
  network = var.private_pool_vpc_name

  export_custom_routes = true
  import_custom_routes = true

  depends_on = [
    google_service_networking_connection.worker_pool_connection
  ]
}

# Cloud Build Worker Pool
resource "google_cloudbuild_worker_pool" "pool" {
  name     = var.worker_pool_name
  project  = var.project_id
  location = var.location
  worker_config {
    disk_size_gb   = 100
    machine_type   = var.machine_type
    no_external_ip = var.worker_pool_no_external_ip
  }
  network_config {
    peered_network = var.create_cloudbuild_network ? google_compute_network.private_pool_vpc[0].id : data.google_compute_network.workerpool_vpc[0].id
  }
  depends_on = [google_service_networking_connection.worker_pool_connection]
}


