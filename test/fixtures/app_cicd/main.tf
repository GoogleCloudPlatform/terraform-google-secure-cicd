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

locals {
  envs = ["dev", "qa", "prod"]
}

module "example" {
  source = "../../../examples/app_cicd"

  project_id       = var.project_id
  primary_location = var.primary_location
  deploy_branch_clusters = {
    dev = {
      cluster               = "dev-cluster",
      project_id            = module.gke-project["dev"].project_id,
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/security-attestor"
      next_env              = "qa"
    },
    qa = {
      cluster               = "qa-cluster",
      project_id            = module.gke-project["qa"].project_id,
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/quality-attestor"
      next_env              = "prod"
    },
    prod = {
      cluster               = "prod-cluster",
      project_id            = module.gke-project["prod"].project_id,
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/quality-attestor", "projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = ""
      next_env              = ""
    },
  }
  depends_on = [
    module.gke-project
  ]
}

# GKE Projects
module "gke-project" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/project-factory/google"
  version  = "~> 10.0"

  name                    = "secure-cicd-gke-${each.key}"
  random_project_id       = "true"
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "keep"

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "storage-api.googleapis.com",
    "serviceusage.googleapis.com",
    "containerregistry.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "containeranalysis.googleapis.com",
    "cloudkms.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containerscanning.googleapis.com",
    "container.googleapis.com",
    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
}

# VPCs
module "vpc" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/network/google"
  version  = "~> 3.0"

  project_id   = module.gke-project[each.value].project_id
  network_name = "gke-vpc-${each.value}"
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
  for_each = toset(local.envs)
  source   = "terraform-google-modules/kubernetes-engine/google"

  project_id                  = module.gke-project[each.value].project_id
  name                        = "${each.value}-cluster"
  regional                    = true
  region                      = var.primary_location
  zones                       = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                     = module.vpc[each.value].network_name
  subnetwork                  = module.vpc[each.value].subnets_names[0]
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
