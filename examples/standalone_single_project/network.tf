/**
 * Copyright 2022 Google LLC
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

locals {
  gke_net_vpn = {
    "${module.vpc[var.env1_name].network_name}" = {
      network    = module.vpc[var.env1_name].network_name
      project_id = var.project_id
      location   = var.region
      control_plane_cidrs = {
        "${module.gke_cluster[var.env1_name].master_ipv4_cidr_block}" = "GKE ${var.env1_name} control plane"
      }

      gateway_1_asn = 65007,
      gateway_2_asn = 65008,
      bgp_range_1   = "169.254.7.0/30",
      bgp_range_2   = "169.254.8.0/30"
    },
    "${module.vpc[var.env2_name].network_name}" = {
      network    = module.vpc[var.env2_name].network_name
      project_id = var.project_id
      location   = var.region
      control_plane_cidrs = {
        "${module.gke_cluster[var.env2_name].master_ipv4_cidr_block}" = "GKE ${var.env2_name} control plane"
      }

      gateway_1_asn = 65009,
      gateway_2_asn = 65010,
      bgp_range_1   = "169.254.9.0/30",
      bgp_range_2   = "169.254.10.0/30"
    },
    "${module.vpc[var.env3_name].network_name}" = {
      network    = module.vpc[var.env3_name].network_name
      project_id = var.project_id
      location   = var.region
      control_plane_cidrs = {
        "${module.gke_cluster[var.env3_name].master_ipv4_cidr_block}" = "GKE ${var.env3_name} control plane"
      }

      gateway_1_asn = 65011,
      gateway_2_asn = 65012,
      bgp_range_1   = "169.254.11.0/30",
      bgp_range_2   = "169.254.12.0/30"
    }
  }
}

# Private Cluster VPCs
module "vpc" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/network/google"
  version  = "~> 4.0"

  project_id   = var.project_id
  network_name = "${var.app_name}-vpc-${each.value}"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "${var.app_name}-subnet-${each.value}"
      subnet_ip             = "10.${local.ip_increment[each.value]}.0.0/17"
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]
  secondary_ranges = {
    "${var.app_name}-subnet-${each.value}" = [
      {
        range_name    = "${var.region}-01-gke-01-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "${var.region}-01-gke-01-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

resource "google_compute_network_peering_routes_config" "gke_peering_routes_config" {
  for_each = toset(local.envs)

  project = var.project_id
  peering = module.gke_cluster[each.value].peering_name
  network = module.vpc[each.value].network_name

  import_custom_routes = true
  export_custom_routes = true
}

# Cloud Build Workerpool <-> GKE HA VPNs
module "gke_cloudbuild_vpn" {
  for_each = local.gke_net_vpn

  source = "../../modules/workerpool-gke-ha-vpn"

  project_id = var.project_id
  location   = var.region

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
