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
  deploy_branch_clusters = {
    "01-${var.env1_name}" = {
      name                  = var.env1_name,
      cluster               = module.gke_cluster[var.env1_name].name,
      anthos_membership     = module.fleet_membership[var.env1_name].cluster_membership_id
      target_type           = "anthos_cluster"
      network               = var.network_name == null ? module.vpc.network_name : var.network_name
      project_id            = var.project_id
      location              = var.region
      required_attestations = [module.attestors.binauth_attestor_ids["build"]]
      env_attestation       = module.attestors.binauth_attestor_ids["security"]
      env_number            = 1
    },
    "02-${var.env2_name}" = {
      name                  = var.env2_name,
      cluster               = module.gke_cluster[var.env2_name].name,
      anthos_membership     = module.fleet_membership[var.env2_name].cluster_membership_id
      target_type           = "anthos_cluster"
      network               = var.network_name == null ? module.vpc.network_name : var.network_name
      project_id            = var.project_id
      location              = var.region
      required_attestations = [module.attestors.binauth_attestor_ids["security"], module.attestors.binauth_attestor_ids["build"]]
      env_attestation       = module.attestors.binauth_attestor_ids["quality"]
      env_number            = 2
    },
    "03-${var.env3_name}" = {
      name                  = var.env3_name,
      cluster               = module.gke_cluster[var.env3_name].name,
      anthos_membership     = module.fleet_membership[var.env3_name].cluster_membership_id
      target_type           = "anthos_cluster"
      network               = var.network_name == null ? module.vpc.network_name : var.network_name
      project_id            = var.project_id
      location              = var.region
      required_attestations = [module.attestors.binauth_attestor_ids["quality"], module.attestors.binauth_attestor_ids["security"], module.attestors.binauth_attestor_ids["build"]]
      env_attestation       = ""
      env_number            = 3
    },
  }

  clouddeploy_pipeline_name = "${var.app_name}-pipeline"
}

module "ci_pipeline" {
  source = "../../modules/secure-ci"

  project_id                = var.project_id
  repository_type           = var.repository_type
  github_auth               = var.repository_type == "GITHUB" ? var.github_auth : null
  gitlab_auth               = var.repository_type == "GITLAB" ? var.gitlab_auth : null
  ci_repository             = var.ci_repository
  gar_repo_name_suffix      = "${var.app_name}-image-repo"
  cache_bucket_name         = "${var.app_name}-cloudbuild"
  primary_location          = var.region
  access_level_name         = var.access_level_name
  attestor_names_prefix     = module.attestors.binauth_attestor_names
  app_build_trigger_yaml    = "cloudbuild-ci.yaml"
  trigger_branch_name       = ".*"
  cloudbuild_private_pool   = var.private_worker_pool_id == null ? module.cloudbuild_private_pool.workerpool_id : var.private_worker_pool_id
  clouddeploy_pipeline_name = local.clouddeploy_pipeline_name
  labels                    = var.labels
}

module "cd_pipeline" {
  source = "../../modules/secure-cd"

  project_id                 = var.project_id
  primary_location           = var.region
  repository_type            = var.repository_type
  github_auth                = var.repository_type == "GITHUB" ? var.github_auth : null
  gitlab_auth                = var.repository_type == "GITLAB" ? var.gitlab_auth : null
  gar_repo_name              = module.ci_pipeline.app_artifact_repo
  cd_repository              = var.cd_repository
  deploy_branch_clusters     = local.deploy_branch_clusters
  app_deploy_trigger_yaml    = "cloudbuild-cd.yaml"
  access_level_name          = var.access_level_name
  cache_bucket_name          = module.ci_pipeline.cache_bucket_name
  cloudbuild_private_pool    = var.private_worker_pool_id == null ? module.cloudbuild_private_pool.workerpool_id : var.private_worker_pool_id
  clouddeploy_pipeline_name  = local.clouddeploy_pipeline_name
  cloudbuild_service_account = module.ci_pipeline.build_sa_email
  depends_on = [
    module.ci_pipeline
  ]
}

module "cloudbuild_private_pool" {
  source = "../../modules/cloudbuild-private-pool"

  count = var.private_worker_pool_id == null ? 1 : 0

  project_id                   = var.project_id
  network_project_id           = var.project_id
  location                     = var.region
  create_cloudbuild_network    = true
  private_pool_vpc_name        = "cloudbuild-worker-vpc"
  worker_pool_name             = "cloudbuild-workerpool"
  machine_type                 = var.cloudbuild_private_pool_machine_type
  worker_address               = "10.39.0.0"
  worker_address_prefix_length = "24"
  worker_range_name            = "cloudbuild-worker-range"
  labels                       = var.labels
}

module "attestors" {
  source = "../../modules/attestor"

  project_id            = var.project_id
  primary_location      = var.region
  attestor_names_prefix = ["build", "security", "quality"]
}
