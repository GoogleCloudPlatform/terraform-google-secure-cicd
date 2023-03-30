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
  deploy_branch_clusters = {
    "01-dev" = {
      cluster               = "dev-private-cluster",
      network               = var.gke_private_vpc_names["dev"]
      project_id            = var.gke_project_ids["dev"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/build-pc-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/security-pc-attestor"
      next_env              = "02-qa"
      anthos_membership     = ""
      target_type           = "gke"
    },
    "02-qa" = {
      cluster               = "qa-private-cluster",
      network               = var.gke_private_vpc_names["qa"]
      project_id            = var.gke_project_ids["qa"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/security-pc-attestor", "projects/${var.project_id}/attestors/build-pc-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/quality-pc-attestor"
      next_env              = "03-prod"
      anthos_membership     = ""
      target_type           = "gke"
    },
    "03-prod" = {
      cluster               = "prod-private-cluster",
      network               = var.gke_private_vpc_names["prod"]
      project_id            = var.gke_project_ids["prod"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/quality-pc-attestor", "projects/${var.project_id}/attestors/security-pc-attestor", "projects/${var.project_id}/attestors/build-pc-attestor"]
      env_attestation       = ""
      next_env              = ""
      anthos_membership     = ""
      target_type           = "gke"
    },
  }
}

data "google_container_cluster" "cluster" {
  for_each = local.deploy_branch_clusters
  project  = each.value.project_id
  location = each.value.location
  name     = each.value.cluster
}

module "example" {
  source = "../../../examples/cloudbuild_private_pool"

  project_id       = var.project_id
  primary_location = var.primary_location

  gke_networks = distinct([
    for env in local.deploy_branch_clusters : {
      network             = env.network
      location            = env.location
      project_id          = env.project_id
      control_plane_cidrs = { for cluster in data.google_container_cluster.cluster : cluster.private_cluster_config[0].master_ipv4_cidr_block => "GKE control plane" if cluster.network == "projects/${env.project_id}/global/networks/${env.network}" }
    }
  ])
}
