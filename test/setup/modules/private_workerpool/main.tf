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

module "private_workerpool_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.2"

  name                     = "secure-cicd-workerpool"
  random_project_id        = "true"
  random_project_id_length = 4
  org_id                   = var.org_id
  folder_id                = var.folder_id
  billing_account          = var.billing_account
  default_service_account  = "KEEP"

  auto_create_network = true

  activate_apis = [
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "servicedirectory.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
  ]
}

resource "time_sleep" "wait_api_propagation" {
  depends_on = [module.private_workerpool_project]

  create_duration = "60s"
}

module "cloudbuild_private_pool" {
  source = "../../../../modules/cloudbuild-private-pool"

  create_cloudbuild_network = false

  project_id                   = module.private_workerpool_project.project_id
  network_project_id           = module.private_workerpool_project.project_id
  location                     = var.workpool_region
  worker_pool_name             = "cb-pool"
  private_pool_vpc_name        = module.vpc.network_name
  worker_range_name            = "worker-pool-range"
  worker_address               = "10.3.3.0"
  worker_address_prefix_length = 24
  machine_type                 = var.workerpool_machine_type

  depends_on = [time_sleep.wait_api_propagation]
}

resource "time_sleep" "wait_service_network_peering" {
  depends_on = [module.cloudbuild_private_pool]

  create_duration = "30s"
}
