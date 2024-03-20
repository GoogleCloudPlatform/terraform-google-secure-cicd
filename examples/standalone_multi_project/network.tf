/**
 * Copyright 2023 Google LLC
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
  envs = [var.env1_name, var.env2_name, var.env3_name]
  env_projects = {
    (var.env1_name) = {
      project_id = var.env1_project_id
    }
    (var.env2_name) = {
      project_id = var.env2_project_id
    }
    (var.env3_name) = {
      project_id = var.env3_project_id
    }
  }
  ip_increment = {
    (var.env1_name) = 1,
    (var.env2_name) = 2,
    (var.env3_name) = 3
  }
  subnets = {
    for env in local.envs : env => {
      subnet_name           = "${var.app_name}-subnet-${env}"
      subnet_ip             = "10.${local.ip_increment[env]}.0.0/17"
      subnet_region         = var.region
      subnet_private_access = "true"
    }
  }
  secondary_ranges = {
    for env in local.envs : local.subnets[env].subnet_name => [
      {
        range_name    = "${local.subnets[env].subnet_name}-gke-pods"
        ip_cidr_range = "10.1${local.ip_increment[env]}.0.0/16"
      },
      {
        range_name    = "${local.subnets[env].subnet_name}-gke-services"
        ip_cidr_range = "10.10${local.ip_increment[env]}.0.0/20"
      },
    ]
  }
  vpn_config = {
    (var.env1_name) = {
      gateway_1_asn = 65007,
      gateway_2_asn = 65008,
      bgp_range_1   = "169.254.7.0/30",
      bgp_range_2   = "169.254.8.0/30"
    },
    (var.env2_name) = {
      gateway_1_asn = 65009,
      gateway_2_asn = 65010,
      bgp_range_1   = "169.254.9.0/30",
      bgp_range_2   = "169.254.10.0/30"
    },
    (var.env3_name) = {
      gateway_1_asn = 65011,
      gateway_2_asn = 65012,
      bgp_range_1   = "169.254.11.0/30",
      bgp_range_2   = "169.254.12.0/30"
    }
  }
}

# Private Cluster VPCs
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 6.0"

  for_each = toset(local.envs)

  project_id   = local.env_projects[each.key].project_id
  network_name = "${var.app_name}-vpc-${each.key}"
  routing_mode = "REGIONAL"

  subnets          = values(local.subnets)
  secondary_ranges = local.secondary_ranges
}

resource "google_compute_network_peering_routes_config" "gke_peering_routes_config" {
  for_each = toset(local.envs)

  project = local.env_projects[each.key].project_id
  peering = module.gke_cluster[each.key].peering_name
  network = module.vpc[each.key].network_name

  import_custom_routes = true
  export_custom_routes = true
}

module "gke_cloudbuild_vpn" {
  for_each = toset(local.envs)

  source = "../../modules/workerpool-gke-ha-vpn"

  project_id = var.management_project_id
  location   = var.region

  gke_project  = local.env_projects[each.key].project_id
  gke_network  = module.vpc[each.key].network_name
  gke_location = module.gke_cluster[each.key].location
  gke_control_plane_cidrs = {
    module.gke_cluster[each.key].master_ipv4_cidr_block = each.key
  }

  workerpool_network = module.cloudbuild_private_pool.workerpool_network
  workerpool_range   = module.cloudbuild_private_pool.workerpool_range
  gateway_1_asn      = local.vpn_config[each.key].gateway_1_asn
  gateway_2_asn      = local.vpn_config[each.key].gateway_2_asn
  bgp_range_1        = local.vpn_config[each.key].bgp_range_1
  bgp_range_2        = local.vpn_config[each.key].bgp_range_2

  vpn_router_name_prefix = "pc-"
}



