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
      cluster               = module.gke_private_cluster["dev"].name,
      network               = module.vpc_private_cluster["dev"].network_name,
      project_id            = var.gke_project_ids["dev"],
      location              = module.gke_private_cluster["dev"].region,
      required_attestations = ["projects/${var.project_id}/attestors/build-pc-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/security-pc-attestor"
      next_env              = "02-qa"
    },
    "02-qa" = {
      cluster               = module.gke_private_cluster["qa"].name,
      network               = module.vpc_private_cluster["qa"].network_name,
      project_id            = var.gke_project_ids["qa"],
      location              = module.gke_private_cluster["qa"].region,
      required_attestations = ["projects/${var.project_id}/attestors/security-pc-attestor", "projects/${var.project_id}/attestors/build-pc-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/quality-pc-attestor"
      next_env              = "03-prod"
    },
    "03-prod" = {
      cluster               = module.gke_private_cluster["prod"].name,
      network               = module.vpc_private_cluster["prod"].network_name,
      project_id            = var.gke_project_ids["prod"],
      location              = module.gke_private_cluster["prod"].region,
      required_attestations = ["projects/${var.project_id}/attestors/quality-pc-attestor", "projects/${var.project_id}/attestors/security-pc-attestor", "projects/${var.project_id}/attestors/build-pc-attestor"]
      env_attestation       = ""
      next_env              = ""
    },
  }

  gke_networks = [
    {
      network    = module.vpc_private_cluster["dev"].network_name,
      location   = module.gke_private_cluster["dev"].region,
      project_id = var.gke_project_ids["dev"],
      control_plane_cidrs = {
        (module.gke_private_cluster["dev"].master_ipv4_cidr_block) = "GKE dev control plane"
      }
    },
    {
      network    = module.vpc_private_cluster["qa"].network_name,
      location   = module.gke_private_cluster["qa"].region,
      project_id = var.gke_project_ids["qa"],
      control_plane_cidrs = {
        (module.gke_private_cluster["qa"].master_ipv4_cidr_block) = "GKE qa control plane"
      }
    },
    {
      network    = module.vpc_private_cluster["prod"].network_name,
      location   = module.gke_private_cluster["prod"].region,
      project_id = var.gke_project_ids["prod"],
      control_plane_cidrs = {
        (module.gke_private_cluster["prod"].master_ipv4_cidr_block) = "GKE prod control plane"
      }
    }
  ]

  ip_increment = {
    "dev"  = 1,
    "qa"   = 2,
    "prod" = 3
  }
}

module "example" {
  source = "../../../examples/cloudbuild_private_pool"

  project_id       = var.project_id
  primary_location = var.primary_location
  gke_networks     = local.gke_networks
}

###### Private Clusters ######
# Private Cluster VPCs
module "vpc_private_cluster" {
  for_each = var.gke_project_ids
  source   = "terraform-google-modules/network/google"
  version  = "~> 4.0"

  project_id   = var.gke_project_ids[each.key]
  network_name = "gke-cbpp-vpc-${each.key}"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "gke-subnet-cbpp"
      subnet_ip             = "10.0.0.0/17"
      subnet_region         = var.primary_location
      subnet_private_access = true

    },
  ]
  secondary_ranges = {
    gke-subnet-cbpp = [
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

resource "google_compute_network_peering_routes_config" "gke_peering_routes_config" {
  for_each = var.gke_project_ids

  project = each.value
  peering = module.gke_private_cluster[each.key].peering_name
  network = module.vpc_private_cluster[each.key].network_name

  import_custom_routes = true
  export_custom_routes = true
}

module "gke_private_cluster" {
  for_each = var.gke_project_ids
  source   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version  = "~> 22.1.0"

  project_id                  = var.gke_project_ids[each.key]
  name                        = "${each.key}-cbpp-cluster"
  regional                    = true
  region                      = var.primary_location
  zones                       = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                     = module.vpc_private_cluster[each.key].network_name
  subnetwork                  = module.vpc_private_cluster[each.key].subnets_names[0]
  ip_range_pods               = "us-central1-01-gke-01-pods"
  ip_range_services           = "us-central1-01-gke-01-services"
  horizontal_pod_autoscaling  = true
  create_service_account      = true
  enable_binary_authorization = true
  skip_provisioners           = true

  enable_private_endpoint = true
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.16.${local.ip_increment[each.key]}.0/28"

  enable_vertical_pod_autoscaling = true

  # Enabled read-access to images in GAR repo in CI/CD project
  grant_registry_access = true
  registry_project_ids  = [var.project_id]

  master_authorized_networks = [
    {
      cidr_block   = module.vpc_private_cluster[each.key].subnets_ips[0]
      display_name = "VPC"
    },
    {
      cidr_block   = "10.37.0.0/16"
      display_name = "CLOUDBUILD"
    }
  ]

  depends_on = [
    module.vpc_private_cluster
  ]
}
