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
  envs = ["${var.env1_name}", "${var.env2_name}", "${var.env3_name}"]
  ip_increment = {
    "${var.env1_name}" = 1,
    "${var.env2_name}" = 2,
    "${var.env3_name}" = 3
  }

  project_id = var.project_id_standalone

  deploy_branch_clusters = {
    "01-${var.env1_name}" = {
      cluster               = module.gke_cluster["${var.env1_name}"].name,
      network               = module.vpc["${var.env1_name}"].network_name
      project_id            = local.project_id,
      location              = var.region,
      required_attestations = [module.ci_pipeline.binauth_attestor_ids["build"]]
      env_attestation       = module.ci_pipeline.binauth_attestor_ids["security"]
      next_env              = "02-qa"
    },
    "02-${var.env2_name}" = {
      cluster               = module.gke_cluster["${var.env2_name}"].name,
      network               = module.vpc["${var.env2_name}"].network_name
      project_id            = local.project_id,
      location              = var.region,
      required_attestations = [module.ci_pipeline.binauth_attestor_ids["security"], module.ci_pipeline.binauth_attestor_ids["build"]]
      env_attestation       = module.ci_pipeline.binauth_attestor_ids["quality"]
      next_env              = "03-prod"
    },
    "03-${var.env3_name}" = {
      cluster               = module.gke_cluster["${var.env3_name}"].name,
      network               = module.vpc["${var.env3_name}"].network_name
      project_id            = local.project_id,
      location              = var.region,
      required_attestations = [module.ci_pipeline.binauth_attestor_ids["quality"], module.ci_pipeline.binauth_attestor_ids["security"], module.ci_pipeline.binauth_attestor_ids["build"]]
      env_attestation       = ""
      next_env              = ""
    },
  }

  gke_net_vpn = {
    "${module.vpc["${var.env1_name}"].network_name}" = {
      network    = module.vpc["${var.env1_name}"].network_name
      project_id = local.project_id
      location   = var.region
      control_plane_cidrs = {
        "${module.gke_cluster["${var.env1_name}"].master_ipv4_cidr_block}" = "GKE ${var.env1_name} control plane"
      }

      gateway_1_asn = 65007,
      gateway_2_asn = 65008,
      bgp_range_1   = "169.254.7.0/30",
      bgp_range_2   = "169.254.8.0/30"
    },
    "${module.vpc["${var.env2_name}"].network_name}" = {
      network    = module.vpc["${var.env2_name}"].network_name
      project_id = local.project_id
      location   = var.region
      control_plane_cidrs = {
        "${module.gke_cluster["${var.env2_name}"].master_ipv4_cidr_block}" = "GKE ${var.env2_name} control plane"
      }

      gateway_1_asn = 65009,
      gateway_2_asn = 65010,
      bgp_range_1   = "169.254.9.0/30",
      bgp_range_2   = "169.254.10.0/30"
    },
    "${module.vpc["${var.env3_name}"].network_name}" = {
      network    = module.vpc["${var.env3_name}"].network_name
      project_id = local.project_id
      location   = var.region
      control_plane_cidrs = {
        "${module.gke_cluster["${var.env3_name}"].master_ipv4_cidr_block}" = "GKE ${var.env3_name} control plane"
      }

      gateway_1_asn = 65011,
      gateway_2_asn = 65012,
      bgp_range_1   = "169.254.11.0/30",
      bgp_range_2   = "169.254.12.0/30"
    }

  }

  clouddeploy_pipeline_name = "${var.app_name}-pipeline"

}

# Secure-CI
module "ci_pipeline" {
  source                    = "../../modules/secure-ci"
  project_id                = local.project_id
  app_source_repo           = "${var.app_name}-source"
  cloudbuild_cd_repo        = "${var.app_name}-cloudbuild-cd-config"
  gar_repo_name_suffix      = "${var.app_name}-image-repo"
  cache_bucket_name         = "${var.app_name}-cloudbuild"
  primary_location          = var.region
  attestor_names_prefix     = ["build", "security", "quality"]
  app_build_trigger_yaml    = "cloudbuild-ci.yaml"
  runner_build_folder       = "${path.module}/cloud-build-builder"
  build_image_config_yaml   = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name       = ".*"
  cloudbuild_private_pool   = module.cloudbuild_private_pool.workerpool_id
  clouddeploy_pipeline_name = local.clouddeploy_pipeline_name
  skip_provisioners         = true
}

# Secure-CD
module "cd_pipeline" {
  source           = "../../modules/secure-cd"
  project_id       = local.project_id
  primary_location = var.region

  gar_repo_name             = module.ci_pipeline.app_artifact_repo
  cloudbuild_cd_repo        = "${var.app_name}-cloudbuild-cd-config"
  deploy_branch_clusters    = local.deploy_branch_clusters
  app_deploy_trigger_yaml   = "cloudbuild-cd.yaml"
  cache_bucket_name         = module.ci_pipeline.cache_bucket_name
  cloudbuild_private_pool   = module.cloudbuild_private_pool.workerpool_id
  clouddeploy_pipeline_name = local.clouddeploy_pipeline_name
  depends_on = [
    module.ci_pipeline
  ]
}

# Cloud Build Private Pool
module "cloudbuild_private_pool" {
  source = "../../modules/cloudbuild-private-pool"

  project_id                = local.project_id
  network_project_id        = local.project_id
  location                  = var.region
  create_cloudbuild_network = true
  private_pool_vpc_name     = "cloudbuild-worker-vpc"
  worker_pool_name          = "cloudbuild-workerpool"
  machine_type              = "e2-highcpu-32"

  worker_address    = "10.39.0.0"
  worker_range_name = "cloudbuild-worker-range"
}

# Cloud Build Workerpool <-> GKE HA VPNs

module "gke_cloudbuild_vpn" {
  for_each = local.gke_net_vpn

  source = "../../modules/workerpool-gke-ha-vpn"

  project_id = local.project_id
  location   = var.region

  gke_project             = each.value.project_id
  gke_network             = each.value.network
  gke_location            = each.value.location
  gke_control_plane_cidrs = each.value.control_plane_cidrs

  workerpool_network = module.cloudbuild_private_pool.workerpool_network
  workerpool_range   = module.cloudbuild_private_pool.workerpool_range
  gateway_1_asn      = each.value.gateway_1_asn
  gateway_2_asn      = each.value.gateway_2_asn
  bgp_range_1        = each.value.bgp_range_1
  bgp_range_2        = each.value.bgp_range_2
}

###### Private Clusters ######
# Private Cluster VPCs
module "vpc" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/network/google"
  version  = "~> 4.0"

  project_id   = local.project_id
  network_name = "${var.app_name}-vpc-${each.value}"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name   = "${var.app_name}-subnet-${each.value}"
      subnet_ip     = "10.${local.ip_increment[each.value]}.0.0/17"
      subnet_region = var.region
    },
  ]
  secondary_ranges = {
    "${var.app_name}-subnet-${each.value}" = [
      {
        range_name    = "${var.region}-01-gke-01-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "${var.region}-01-gke-01-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

resource "google_compute_network_peering_routes_config" "gke_peering_routes_config" {
  for_each = toset(local.envs)

  project = local.project_id
  peering = module.gke_cluster[each.value].peering_name
  network = module.vpc[each.value].network_name

  import_custom_routes = true
  export_custom_routes = true
}

module "gke_cluster" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version  = "~> 23.0.0"

  project_id                  = local.project_id
  name                        = "${var.app_name}-cluster-${each.value}"
  regional                    = true
  region                      = var.region
  network                     = module.vpc[each.value].network_name
  subnetwork                  = module.vpc[each.value].subnets_names[0]
  ip_range_pods               = "${var.region}-01-gke-01-pods"
  ip_range_services           = "${var.region}-01-gke-01-services"
  horizontal_pod_autoscaling  = true
  create_service_account      = true
  enable_binary_authorization = true

  enable_private_endpoint = true
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.16.${local.ip_increment[each.value]}.0/28"

  enable_vertical_pod_autoscaling = true

  master_authorized_networks = [
    {
      cidr_block   = module.vpc[each.value].subnets_ips[0]
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
