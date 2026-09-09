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

locals {
  subnets = {
    for env in var.envs : env => {
      subnet_name           = "${var.app_name}-subnet-${env}"
      subnet_ip             = "10.${var.ip_increment[env]}.0.0/17"
      subnet_region         = var.region
      subnet_private_access = "true"
    }
  }
  secondary_ranges = {
    for env in var.envs : local.subnets[env].subnet_name => [
      {
        range_name    = "${local.subnets[env].subnet_name}-gke-pods"
        ip_cidr_range = "10.1${var.ip_increment[env]}.0.0/16"
      },
      {
        range_name    = "${local.subnets[env].subnet_name}-gke-services"
        ip_cidr_range = "10.10${var.ip_increment[env]}.0.0/20"
      },
    ]
  }
}

module "vpc" {
  source = "../../modules/cluster_network"

  project_id       = var.project_id
  vpc_name         = "${var.app_name}-vpc"
  subnets          = values(local.subnets)
  secondary_ranges = local.secondary_ranges
}
