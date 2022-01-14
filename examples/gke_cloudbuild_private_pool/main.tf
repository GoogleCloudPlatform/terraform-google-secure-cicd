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

module "cloudbuild_private_pool" {
  source = "../../modules/cloudbuild-private-pool"

  project_id                = var.project_id
  location                  = var.primary_location
  create_cloudbuild_network = true
  private_pool_vpc_name     = "gke-private-pool-example-vpc"
  worker_address            = "10.37.0.0"
  worker_range_name         = "gke-private-pool-worker-range"
}

module "gke_cloudbuild_vpn_0" {
  source = "../../modules/workerpool-gke-ha-vpn"

  project_id = var.project_id
  location   = "us-central1"

  gke_project             = var.gke_networks[0].project_id
  gke_network             = var.gke_networks[0].network
  gke_location            = var.gke_networks[0].location
  gke_control_plane_cidrs = var.gke_networks[0].control_plane_cidrs

  workerpool_network = module.cloudbuild_private_pool.workerpool_network
  workerpool_range   = module.cloudbuild_private_pool.workerpool_range
  gateway_1_asn      = 65001
  gateway_2_asn      = 65002
  bgp_range_1        = "169.254.1.0/30"
  bgp_range_2        = "169.254.2.0/30"

  vpn_router_name_prefix = "cbpp-ex"
}

module "gke_cloudbuild_vpn_1" {
  source = "../../modules/workerpool-gke-ha-vpn"

  project_id = var.project_id
  location   = "us-central1"

  gke_project             = var.gke_networks[1].project_id
  gke_network             = var.gke_networks[1].network
  gke_location            = var.gke_networks[1].location
  gke_control_plane_cidrs = var.gke_networks[1].control_plane_cidrs

  workerpool_network = module.cloudbuild_private_pool.workerpool_network
  workerpool_range   = module.cloudbuild_private_pool.workerpool_range
  gateway_1_asn      = 65003
  gateway_2_asn      = 65004
  bgp_range_1        = "169.254.3.0/30"
  bgp_range_2        = "169.254.4.0/30"

  vpn_router_name_prefix = "cbpp-ex"
}

module "gke_cloudbuild_vpn_2" {
  source = "../../modules/workerpool-gke-ha-vpn"

  project_id = var.project_id
  location   = "us-central1"

  gke_project             = var.gke_networks[2].project_id
  gke_network             = var.gke_networks[2].network
  gke_location            = var.gke_networks[2].location
  gke_control_plane_cidrs = var.gke_networks[2].control_plane_cidrs

  workerpool_network = module.cloudbuild_private_pool.workerpool_network
  workerpool_range   = module.cloudbuild_private_pool.workerpool_range
  gateway_1_asn      = 65005
  gateway_2_asn      = 65006
  bgp_range_1        = "169.254.5.0/30"
  bgp_range_2        = "169.254.6.0/30"

  vpn_router_name_prefix = "cbpp-ex"
}
