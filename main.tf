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

module "ci_pipeline" {
  source                  = "./modules/secure-ci"
  project_id              = var.project_id
  app_source_repo         = var.app_source_repo_name
  manifest_dry_repo       = var.manifest_dry_repo_name 
  manifest_wet_repo       = var.manifest_wet_repo_name 
  gar_repo_name_suffix    = var.gar_repo_name_suffix
  primary_location        = var.primary_location 
  attestor_names_prefix   = var.attestor_names_prefix 
  app_build_trigger_yaml  = var.app_build_trigger_yaml 
  runner_build_folder     = var.runner_build_folder 
  build_image_config_yaml = var.build_image_config_yaml 
  trigger_branch_name     = var.app_build_trigger_branch_name 
}

module "cd_pipeline" {
  source                  = "./modules/secure-cd"
  project_id              = var.project_id
  primary_location        = var.primary_location
  gar_repo_name           = module.ci_pipeline.app_artifact_repo
  manifest_wet_repo       = var.manifest_wet_repo_name 
  deploy_branch_clusters  = var.deploy_branch_clusters
  app_deploy_trigger_yaml = var.app_deploy_trigger_yaml 
  cache_bucket_name       = module.ci_pipeline.cache_bucket_name
}
