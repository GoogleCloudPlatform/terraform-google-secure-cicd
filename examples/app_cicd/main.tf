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
    prod = {
      cluster    = "prod-cluster",
      project_id = var.project_id,
      location   = "us-central1",
    },
    qa = {
      cluster    = "qa-cluster",
      project_id = var.project_id,
      location   = "us-central1",
    }
    dev = {
      cluster    = "dev-cluster",
      project_id = var.project_id,
      location   = "us-central1",
    },
  }
}
module "ci_pipeline" {
  source                  = "../../modules/secure-ci"
  project_id              = var.project_id
  app_source_repo         = "app-source"
  manifest_dry_repo       = "app-dry-manifests"
  manifest_wet_repo       = "app-wet-manifests"
  gar_repo_name_suffix    = "app-image-repo"
  primary_location        = "us-central1"
  attestor_names_prefix   = ["build", "quality", "security"]
  app_build_trigger_yaml  = "cloudbuild-ci.yaml"
  runner_build_folder     = "../../../examples/app_cicd/cloud-build-builder"
  build_image_config_yaml = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name     = ".*"

  additional_substitutions = {
    _FAVORITE_COLOR = "blue"
  }
}

module "cd_pipeline" {
  source                  = "../../modules/secure-cd"
  project_id              = var.project_id
  primary_location        = "us-central1"

  gar_repo_name           = module.ci_pipeline.app_artifact_repo
  manifest_wet_repo       = "app-wet-manifests" 
  deploy_branch_clusters  = local.deploy_branch_clusters
  app_deploy_trigger_yaml = "cloudbuild-cd.yaml"


  additional_substitutions = {
    _FAVORITE_COLOR = "blue"
  }
}

module "gke_clusters" {
  source  = "terraform-google-modules/kubernetes-engine/google//examples/simple_regional"
  version = "17.0.0"
  
  
}