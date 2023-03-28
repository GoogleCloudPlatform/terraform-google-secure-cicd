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
  clouddeploy_pipeline_name = "pipeline-private"
}

# Secure-CI
module "ci_pipeline" {
  source                    = "../../modules/secure-ci"
  project_id                = var.project_id
  app_source_repo           = "app-source-pc"
  cloudbuild_cd_repo        = "cloudbuild-cd-config-pc"
  gar_repo_name_suffix      = "app-image-repo-pc"
  cache_bucket_name         = "private-cluster-cloudbuild"
  primary_location          = "us-central1"
  attestor_names_prefix     = ["build-pc", "security-pc", "quality-pc"]
  app_build_trigger_yaml    = "cloudbuild-ci.yaml"
  runner_build_folder       = "${path.module}/cloud-build-builder"
  build_image_config_yaml   = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name       = ".*"
  cloudbuild_private_pool   = module.cloudbuild_private_pool.workerpool_id
  clouddeploy_pipeline_name = local.clouddeploy_pipeline_name
}

# Secure-CD
module "cd_pipeline" {
  source           = "../../modules/secure-cd"
  project_id       = var.project_id
  primary_location = "us-central1"

  gar_repo_name              = module.ci_pipeline.app_artifact_repo
  cloudbuild_cd_repo         = "cloudbuild-cd-config-pc"
  deploy_branch_clusters     = var.deploy_branch_clusters
  app_deploy_trigger_yaml    = "cloudbuild-cd.yaml"
  cache_bucket_name          = module.ci_pipeline.cache_bucket_name
  cloudbuild_private_pool    = module.cloudbuild_private_pool.workerpool_id
  clouddeploy_pipeline_name  = local.clouddeploy_pipeline_name
  cloudbuild_service_account = module.ci_pipeline.build_sa_email
  depends_on = [
    module.ci_pipeline
  ]
}

# Cloud Build Private Pool
module "cloudbuild_private_pool" {
  source = "../../modules/cloudbuild-private-pool"

  project_id                = var.project_id
  network_project_id        = var.project_id
  location                  = "us-central1"
  create_cloudbuild_network = true
  private_pool_vpc_name     = "gke-private-pool-example-vpc"
  worker_pool_name          = "private-cluster-example-workerpool"
  machine_type              = "e2-highcpu-32"

  worker_address    = "10.39.0.0"
  worker_range_name = "private-cluster-example-worker-range"
}

# Cloud Build Workerpool <-> GKE HA VPNs
locals {
  gke_networks = {
    for net in var.gke_networks : net.network => merge(net, local.vpn_config[net.network])
  }
  vpn_config = {
    gke-private-vpc-dev = {
      gateway_1_asn = 65007,
      gateway_2_asn = 65008,
      bgp_range_1   = "169.254.7.0/30",
      bgp_range_2   = "169.254.8.0/30"
    },
    gke-private-vpc-qa = {
      gateway_1_asn = 65009,
      gateway_2_asn = 65010,
      bgp_range_1   = "169.254.9.0/30",
      bgp_range_2   = "169.254.10.0/30"
    },
    gke-private-vpc-prod = {
      gateway_1_asn = 65011,
      gateway_2_asn = 65012,
      bgp_range_1   = "169.254.11.0/30",
      bgp_range_2   = "169.254.12.0/30"
    }
  }
}

module "gke_cloudbuild_vpn" {
  for_each = local.gke_networks

  source = "../../modules/workerpool-gke-ha-vpn"

  project_id = var.project_id
  location   = "us-central1"

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

  vpn_router_name_prefix = "pc-"
}
