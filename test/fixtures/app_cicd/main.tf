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

module "example" {
  source = "../../../examples/app_cicd"

  project_id       = var.project_id
  primary_location = var.primary_location
  deploy_branch_clusters = {
    dev = {
      cluster               = "dev-cluster",
      project_id            = var.gke_project_ids["dev"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/security-attestor"
      next_env              = "qa"
    },
    qa = {
      cluster               = "qa-cluster",
      project_id            = var.gke_project_ids["qa"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/quality-attestor"
      next_env              = "prod"
    },
    prod = {
      cluster               = "prod-cluster",
      project_id            = var.gke_project_ids["prod"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/quality-attestor", "projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = ""
      next_env              = ""
    },
  }
}

# VPCs
module "vpc" {
  for_each = var.gke_project_ids
  source   = "terraform-google-modules/network/google"
  version  = "~> 3.0"

  project_id   = var.gke_project_ids[each.key]
  network_name = "gke-vpc-${each.key}"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name   = "gke-subnet"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.primary_location
    },
  ]
  secondary_ranges = {
    gke-subnet = [
      {
        range_name    = "us-central1-01-gke-01-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "us-central1-01-gke-01-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

module "gke_cluster" {
  for_each = var.gke_project_ids
  source   = "terraform-google-modules/kubernetes-engine/google"

  project_id                  = var.gke_project_ids[each.key]
  name                        = "${each.key}-cluster"
  regional                    = true
  region                      = var.primary_location
  zones                       = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                     = module.vpc[each.key].network_name
  subnetwork                  = module.vpc[each.key].subnets_names[0]
  ip_range_pods               = "us-central1-01-gke-01-pods"
  ip_range_services           = "us-central1-01-gke-01-services"
  create_service_account      = true
  enable_binary_authorization = true
  skip_provisioners           = false

  # Enabled read-access to images in GAR repo in CI/CD project
  grant_registry_access = true
  registry_project_ids  = [var.project_id]

  depends_on = [
    module.vpc
  ]
}
