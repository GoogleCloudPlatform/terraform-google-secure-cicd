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
  deploy_branch_clusters = {
    "01-${var.env1_name}" = {
      cluster               = module.gke_cluster[var.env1_name].name,
      anthos_membership     = module.fleet_membership[var.env1_name].cluster_membership_id
      target_type           = "anthos_cluster"
      network               = module.vpc.network_name
      project_id            = var.project_id
      location              = var.region
      required_attestations = [module.ci_pipeline.binauth_attestor_ids["build"]]
      env_attestation       = module.ci_pipeline.binauth_attestor_ids["security"]
      next_env              = "02-qa"
    },
    "02-${var.env2_name}" = {
      cluster               = module.gke_cluster[var.env2_name].name,
      anthos_membership     = module.fleet_membership[var.env2_name].cluster_membership_id
      target_type           = "anthos_cluster"
      network               = module.vpc.network_name
      project_id            = var.project_id
      location              = var.region
      required_attestations = [module.ci_pipeline.binauth_attestor_ids["security"], module.ci_pipeline.binauth_attestor_ids["build"]]
      env_attestation       = module.ci_pipeline.binauth_attestor_ids["quality"]
      next_env              = "03-prod"
    },
    "03-${var.env3_name}" = {
      cluster               = module.gke_cluster[var.env3_name].name,
      anthos_membership     = module.fleet_membership[var.env3_name].cluster_membership_id
      target_type           = "anthos_cluster"
      network               = module.vpc.network_name
      project_id            = var.project_id
      location              = var.region
      required_attestations = [module.ci_pipeline.binauth_attestor_ids["quality"], module.ci_pipeline.binauth_attestor_ids["security"], module.ci_pipeline.binauth_attestor_ids["build"]]
      env_attestation       = ""
      next_env              = ""
    },
  }

  clouddeploy_pipeline_name = "${var.app_name}-pipeline"
}

# Secure-CI
module "ci_pipeline" {
  source  = "GoogleCloudPlatform/secure-cicd/google//modules/secure-ci"
  version = "~> 1.0"

  project_id                = var.project_id
  app_source_repo           = "${var.app_name}-source"
  cloudbuild_cd_repo        = "${var.app_name}-cloudbuild-cd-config"
  gar_repo_name_suffix      = "${var.app_name}-image-repo"
  cache_bucket_name         = "${var.app_name}-cloudbuild"
  primary_location          = var.region
  attestor_names_prefix     = ["build", "security", "quality"]
  app_build_trigger_yaml    = "cloudbuild-ci.yaml"
  build_image_config_yaml   = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name       = ".*"
  cloudbuild_private_pool   = module.cloudbuild_private_pool.workerpool_id
  clouddeploy_pipeline_name = local.clouddeploy_pipeline_name
  skip_provisioners         = true
  labels                    = var.labels
}

# Secure-CD
module "cd_pipeline" {
  source  = "GoogleCloudPlatform/secure-cicd/google//modules/secure-cd"
  version = "~> 1.0"

  project_id       = var.project_id
  primary_location = var.region

  gar_repo_name              = module.ci_pipeline.app_artifact_repo
  cloudbuild_cd_repo         = "${var.app_name}-cloudbuild-cd-config"
  deploy_branch_clusters     = local.deploy_branch_clusters
  app_deploy_trigger_yaml    = "cloudbuild-cd.yaml"
  cache_bucket_name          = module.ci_pipeline.cache_bucket_name
  cloudbuild_private_pool    = module.cloudbuild_private_pool.workerpool_id
  clouddeploy_pipeline_name  = local.clouddeploy_pipeline_name
  cloudbuild_service_account = module.ci_pipeline.build_sa_email
  labels                     = var.labels
  depends_on = [
    module.ci_pipeline
  ]
}

# Cloud Build Private Pool
module "cloudbuild_private_pool" {
  source  = "GoogleCloudPlatform/secure-cicd/google//modules/cloudbuild-private-pool"
  version = "~> 1.0"

  project_id                = var.project_id
  network_project_id        = var.project_id
  location                  = var.region
  create_cloudbuild_network = true
  private_pool_vpc_name     = "cloudbuild-worker-vpc"
  worker_pool_name          = "cloudbuild-workerpool"
  machine_type              = "e2-highcpu-32"

  worker_address    = "10.39.0.0"
  worker_range_name = "cloudbuild-worker-range"

  labels = var.labels
}
