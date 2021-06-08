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

module "cicd_pipeline" {
  source                  = "../../modules/app_cicd_pipeline"
  project_id              = var.project_id
  app_cicd_repos          = ["bank-of-anthos-source", "root-config-repo", "accounts", "transactions", "frontend"]
  app_build_repo          = "bank-of-anthos-source"
  gar_repo_name_suffix    = "boa-image-repo"
  primary_location        = "us-central1"
  attestor_names_prefix   = ["build", "quality", "security"]
  app_build_trigger_yaml  = "cloudbuild-build-boa.yaml"
  runner_build_folder     = "../../../examples/app_cicd/cloud-build-builder"
  build_image_config_yaml = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name     = ".*"

  additional_substitutions = {
    _FAVORITE_COLOR = "blue"
  }
}
