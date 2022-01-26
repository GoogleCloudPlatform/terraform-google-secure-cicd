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
  network_project_id        = var.project_id
  location                  = var.primary_location
  worker_pool_name          = "cloudbuild-private-worker-pool"
  create_cloudbuild_network = true
  private_pool_vpc_name     = "workerpool-example-vpc"
  worker_address            = "10.37.0.0"
  worker_range_name         = "gke-private-pool-worker-range"
}

locals {
  gke_networks = {
    for net in var.gke_networks : net.network => merge(net, local.vpn_config[net.network])
  }
  vpn_config = {
    "gke-private-vpc-dev" = {
      gateway_1_asn = 65001,
      gateway_2_asn = 65002,
      bgp_range_1   = "169.254.1.0/30",
      bgp_range_2   = "169.254.2.0/30"
    },
    "gke-private-vpc-qa" = {
      gateway_1_asn = 65003,
      gateway_2_asn = 65004,
      bgp_range_1   = "169.254.3.0/30",
      bgp_range_2   = "169.254.4.0/30"
    },
    "gke-private-vpc-prod" = {
      gateway_1_asn = 65005,
      gateway_2_asn = 65006,
      bgp_range_1   = "169.254.5.0/30",
      bgp_range_2   = "169.254.6.0/30"
    }
  }
}

module "gke_cloudbuild_vpn" {
  for_each = local.gke_networks

  source = "../../modules/workerpool-gke-ha-vpn"

  project_id = var.project_id
  location   = "us-central1"

  gke_project             = each.value.project_id
  gke_network             = each.value.network
  gke_location            = each.value.location
  gke_control_plane_cidrs = each.value.control_plane_cidrs

  workerpool_network = module.cloudbuild_private_pool.workerpool_network
  workerpool_range   = module.cloudbuild_private_pool.workerpool_range
  gateway_1_asn      = each.value.gateway_1_asn
  gateway_2_asn      = each.value.gateway_2_asn
  bgp_range_1        = each.value.bgp_range_1
  bgp_range_2        = each.value.bgp_range_2
}
