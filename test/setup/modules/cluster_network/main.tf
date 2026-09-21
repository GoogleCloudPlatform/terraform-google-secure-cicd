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

module "cluster_vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 13.0"

  project_id      = var.project_id
  network_name    = "vpc-${var.vpc_name}"
  shared_vpc_host = var.shared_vpc_host

  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules

  subnets          = var.subnets
  secondary_ranges = var.secondary_ranges
}

module "cluster_private_service_connect" {
  count                      = var.shared_vpc_host ? 1 : 0
  source                     = "terraform-google-modules/network/google//modules/private-service-connect"
  version                    = "~> 10.0"
  project_id                 = module.cluster_vpc.project_id
  network_self_link          = module.cluster_vpc.network_self_link
  private_service_connect_ip = "10.3.0.5"
  forwarding_rule_target     = "vpc-sc"
}

resource "google_compute_router" "nat_router" {
  for_each = var.shared_vpc_host ? { "create" : true } : {}
  name     = "nat-router-us-central-1"
  region   = "us-central1"
  network  = module.cluster_vpc.network_self_link
  project  = module.cluster_vpc.project_id
}

resource "google_compute_router_nat" "cloud_nat" {
  for_each                           = google_compute_router.nat_router
  name                               = "cloud-nat"
  router                             = each.value.name
  region                             = each.value.region
  project                            = module.cluster_vpc.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
