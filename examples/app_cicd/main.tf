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
  clouddeploy_pipeline_name = "pipeline-01"
}

module "ci_pipeline" {
  source                    = "../../modules/secure-ci"
  project_id                = var.project_id
  app_source_repo           = "app-source"
  cloudbuild_cd_repo        = "cloudbuild-cd-config"
  gar_repo_name_suffix      = "app-image-repo"
  primary_location          = var.primary_location
  attestor_names_prefix     = ["build", "security", "quality"]
  cache_bucket_name         = "app-cloudbuild"
  app_build_trigger_yaml    = "cloudbuild-ci.yaml"
  runner_build_folder       = "${path.module}/cloud-build-builder"
  build_image_config_yaml   = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name       = ".*"
  clouddeploy_pipeline_name = local.clouddeploy_pipeline_name
}

module "cd_pipeline" {
  source           = "../../modules/secure-cd"
  project_id       = var.project_id
  primary_location = var.primary_location

  gar_repo_name              = module.ci_pipeline.app_artifact_repo
  cloudbuild_cd_repo         = "cloudbuild-cd-config"
  deploy_branch_clusters     = var.deploy_branch_clusters
  app_deploy_trigger_yaml    = "cloudbuild-cd.yaml"
  cache_bucket_name          = module.ci_pipeline.cache_bucket_name
  clouddeploy_pipeline_name  = local.clouddeploy_pipeline_name
  cloudbuild_service_account = module.ci_pipeline.build_sa_email
  depends_on = [
    module.ci_pipeline
  ]
}
