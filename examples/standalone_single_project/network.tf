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
}

# Private Cluster VPCs
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 13.0"

  project_id   = var.project_id
  network_name = "${var.app_name}-vpc"
  routing_mode = "REGIONAL"

  subnets          = values(local.subnets)
  secondary_ranges = local.secondary_ranges
}

resource "google_compute_network_peering_routes_config" "gke_peering_routes_config" {
  for_each = toset(local.envs)

  project = var.project_id
  peering = module.gke_cluster[each.value].peering_name
  network = module.vpc.network_name

  import_custom_routes = true
  export_custom_routes = true
}
