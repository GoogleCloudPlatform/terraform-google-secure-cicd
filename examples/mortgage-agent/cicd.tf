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
    "01-dev" = {
      name                  = "01-dev",
      target_type           = "run"
      network               = module.networking.network_name
      project_id            = var.project_id
      location              = var.region
      required_attestations = [module.attestors.binauth_attestor_ids["build"]]
      env_attestation       = module.attestors.binauth_attestor_ids["security"]
      env_number            = 1
      cluster               = null
      anthos_membership     = null
    }
  }

  clouddeploy_pipeline_name = "${var.name_prefix}-pipeline"
}

module "ci_pipeline" {
  for_each = var.mcp_services

  source = "../../modules/secure-ci"


  project_id                = var.project_id
  secure_pipeline_name      = each.key
  repository_type           = var.repository_type
  github_auth               = var.repository_type == "GITHUB" ? var.github_auth : null
  gitlab_auth               = null
  ci_repository             = each.value.ci_repository
  gar_repo_name_suffix      = "${var.name_prefix}-${each.value.otel_service_name}-image-repo"
  cache_bucket_name         = "${var.name_prefix}-${each.value.otel_service_name}-cloudbuild"
  primary_location          = var.region
  access_level_name         = null
  attestor_names_prefix     = module.attestors.binauth_attestor_names
  app_build_trigger_yaml    = var.app_build_trigger_yaml
  trigger_branch_name       = ".*"
  cloudbuild_private_pool   = module.cloudbuild_private_pool.workerpool_id
  clouddeploy_pipeline_name = "${local.clouddeploy_pipeline_name}-${each.value.otel_service_name}"
  labels                    = var.labels
}

module "cd_pipeline" {
  for_each = module.ci_pipeline

  source = "../../modules/secure-cd"

  project_id                 = var.project_id
  primary_location           = var.region
  repository_type            = var.repository_type
  github_auth                = var.repository_type == "GITHUB" ? var.github_auth : null
  gitlab_auth                = null
  gar_repo_name              = each.value.app_artifact_repo
  cd_repository              = var.mcp_services[each.key].cd_repository
  deploy_branch_clusters     = local.deploy_branch_clusters
  app_deploy_trigger_yaml    = var.app_deploy_trigger_yaml
  access_level_name          = null
  cache_bucket_name          = each.value.cache_bucket_name
  cloudbuild_private_pool    = module.cloudbuild_private_pool.workerpool_id
  secure_pipeline_name       = each.key
  clouddeploy_pipeline_name  = "${local.clouddeploy_pipeline_name}-${var.mcp_services[each.key].otel_service_name}"
  cloudbuild_service_account = each.value.build_sa_email
  depends_on = [
    module.ci_pipeline
  ]
}

module "cloudbuild_private_pool" {
  source = "../../modules/cloudbuild-private-pool"

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
  depends_on                   = [time_sleep.wait_enable_apis]
}

module "attestors" {
  source = "../../modules/attestor"

  project_id            = var.project_id
  primary_location      = var.region
  attestor_names_prefix = ["build", "security"]
  depends_on            = [time_sleep.wait_enable_apis]
}
