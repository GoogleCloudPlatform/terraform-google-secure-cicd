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
  nat_proxy_vm_ip_range = "10.1.1.0/24"
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 10.0"

  project_id                             = module.private_workerpool_project.project_id
  network_name                           = "secure-cicd-workerpool-network"
  shared_vpc_host                        = false
  delete_default_internet_gateway_routes = true

  ingress_rules = [
    {
      name     = "allow-ssh"
      priority = 500
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
      source_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    },
  ]

  subnets = [
    {
      subnet_name           = "nat-subnet"
      subnet_ip             = local.nat_proxy_vm_ip_range
      subnet_region         = "us-central1"
      subnet_private_access = true
    },
  ]

  depends_on = [time_sleep.wait_api_propagation]
}
