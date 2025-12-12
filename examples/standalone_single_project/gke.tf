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
  envs = [var.env1_name, var.env2_name, var.env3_name]
  ip_increment = {
    (var.env1_name) = 1,
    (var.env2_name) = 2,
    (var.env3_name) = 3
  }
}

data "google_compute_zones" "available" {
  provider = google

  project = var.project_id
  region  = var.region
}

resource "random_shuffle" "available_zones" {
  input        = data.google_compute_zones.available.names
  result_count = 2
}

# Private GKE Clusters
module "gke_cluster" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version  = "~> 42.0"

  project_id                  = var.project_id
  name                        = "${var.app_name}-cluster-${each.value}"
  regional                    = true
  region                      = var.region
  zones                       = sort(random_shuffle.available_zones.result)
  network                     = module.vpc.network_name
  subnetwork                  = local.subnets[each.value].subnet_name
  ip_range_pods               = "${local.subnets[each.value].subnet_name}-gke-pods"
  ip_range_services           = "${local.subnets[each.value].subnet_name}-gke-services"
  horizontal_pod_autoscaling  = true
  create_service_account      = true
  enable_binary_authorization = true
  remove_default_node_pool    = true

  grant_registry_access = true
  registry_project_ids  = [var.project_id]

  enable_private_endpoint = true
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.16.${local.ip_increment[each.value]}.0/28"

  release_channel    = "REGULAR"
  kubernetes_version = "latest"

  enable_vertical_pod_autoscaling = true

  master_authorized_networks = [
    {
      cidr_block   = local.subnets[each.value].subnet_ip
      display_name = "VPC"
    },
    {
      cidr_block   = "10.39.0.0/16"
      display_name = "CLOUDBUILD"
    }
  ]

  node_pools = [
    {
      name                 = "default-node-pool"
      location_policy      = "BALANCED"
      total_max_node_count = 2
    }
  ]

  node_pools_labels = {
    all = var.labels
  }
  cluster_resource_labels = var.labels

  depends_on = [
    module.vpc
  ]
}

module "fleet_membership" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/kubernetes-engine/google//modules/fleet-membership"
  version  = "~> 42.0.0"

  membership_name = "${module.gke_cluster[each.value].name}-membership"
  project_id      = var.project_id
  location        = var.region
  cluster_name    = module.gke_cluster[each.value].name
}
