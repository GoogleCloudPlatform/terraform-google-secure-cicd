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
    "${var.env1_name}" = 1,
    "${var.env2_name}" = 2,
    "${var.env3_name}" = 3
  }
}

# Private GKE Clusters
module "gke_cluster" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version  = "~> 23.0.0"

  project_id                  = var.project_id
  name                        = "${var.app_name}-cluster-${each.value}"
  regional                    = true
  region                      = var.region
  network                     = module.vpc.network_name
  subnetwork                  = local.subnets[each.value].subnet_name
  ip_range_pods               = "${local.subnets[each.value].subnet_name}-gke-pods"
  ip_range_services           = "${local.subnets[each.value].subnet_name}-gke-services"
  horizontal_pod_autoscaling  = true
  create_service_account      = true
  enable_binary_authorization = true

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

  depends_on = [
    module.vpc
  ]
}
