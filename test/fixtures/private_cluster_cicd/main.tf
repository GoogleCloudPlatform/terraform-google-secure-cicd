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
  source = "../../../examples/private_cluster_cicd"

  project_id       = var.project_id
  primary_location = var.primary_location
  deploy_branch_clusters = {
    dev = {
      cluster               = var.gke_cluster_names["dev"]
      #cluster               = module.gke_cluster["dev"].name,
      network               = var.gke_vpc_names["dev"]
      #network               = module.vpc["dev"].network_name
      project_id            = var.gke_project_ids["dev"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/security-attestor"
      next_env              = "qa"
    },
    qa = {
      cluster               = var.gke_cluster_names["qa"]
      #cluster               = module.gke_cluster["qa"].name,
      network               = var.gke_vpc_names["qa"]
      #network               = module.vpc["qa"].network_name
      project_id            = var.gke_project_ids["qa"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/quality-attestor"
      next_env              = "prod"
    },
    prod = {
      cluster               = var.gke_cluster_names["prod"]
      #cluster               = module.gke_cluster["prod"].name,
      network               = var.gke_vpc_names["prod"]
      #network               = module.vpc["prod"].network_name
      project_id            = var.gke_project_ids["prod"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/quality-attestor", "projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = ""
      next_env              = ""
    },
  }
}

# # VPCs
# module "vpc" {
#   for_each = var.gke_project_ids
#   source   = "terraform-google-modules/network/google"
#   version  = "~> 3.0"

#   project_id   = var.gke_project_ids[each.key]
#   network_name = "gke-private-vpc-${each.key}"
#   routing_mode = "REGIONAL"

#   subnets = [
#     {
#       subnet_name   = "gke-subnet"
#       subnet_ip     = "10.0.0.0/17"
#       subnet_region = var.primary_location
#     },
#   ]
#   secondary_ranges = {
#     gke-subnet = [
#       {
#         range_name    = "us-central1-01-gke-01-pods"
#         ip_cidr_range = "192.168.0.0/18"
#       },
#       {
#         range_name    = "us-central1-01-gke-01-services"
#         ip_cidr_range = "192.168.64.0/18"
#       },
#     ]
#   }
# }

# module "gke_cluster" {
#   for_each = var.gke_project_ids
#   source   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"

#   project_id                  = var.gke_project_ids[each.key]
#   name                        = "${each.key}-private-cluster"
#   regional                    = true
#   region                      = var.primary_location
#   zones                      = ["us-central1-a", "us-central1-b", "us-central1-f"]
#   network                     = module.vpc[each.key].network_name
#   subnetwork                  = module.vpc[each.key].subnets_names[0]
#   ip_range_pods               = "us-central1-01-gke-01-pods"
#   ip_range_services           = "us-central1-01-gke-01-services"
#   create_service_account      = true
#   enable_binary_authorization = true
#   skip_provisioners           = false
#   enable_private_endpoint     = true
#   enable_private_nodes        = true
#   master_ipv4_cidr_block      = "172.16.0.0/28"

#   remove_default_node_pool  = true

#   node_pools = [
#     {
#       name              = "pool-01"
#       min_count         = 1
#       max_count         = 100
#       local_ssd_count   = 0
#       disk_size_gb      = 100
#       disk_type         = "pd-standard"
#       image_type        = "COS"
#       auto_repair       = true
#       auto_upgrade      = true
#       preemptible       = false
#       max_pods_per_node = 12
#     },
#   ]

#   # Enabled read-access to images in GAR repo in CI/CD project
#   grant_registry_access = true
#   registry_project_ids  = [var.project_id]

#   master_authorized_networks = [
#     {
#       cidr_block   = module.vpc[each.key].subnets_ips[0]
#       display_name = "VPC"
#     },
#   ]

#   depends_on = [
#     module.vpc
#   ]
# }

resource "google_project_iam_member" "cluster_service_account-gcr" {
  for_each = var.gke_service_accounts
  project  = var.project_id
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${each.value}"
}

resource "google_project_iam_member" "cluster_service_account-artifact-registry" {
  for_each = var.gke_service_accounts
  project  = var.project_id
  role     = "roles/artifactregistry.reader"
  member   = "serviceAccount:${each.value}"
}
