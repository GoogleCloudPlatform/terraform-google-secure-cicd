/**
 * Copyright 2018 Google LLC
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

/******************************************
  Provider configuration
 *****************************************/
module "project-services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                  = var.project_id
  enable_apis                 = var.enable
  disable_services_on_destroy = true

  activate_apis = [
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "sourcerepo.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudkms.googleapis.com",
    "containeranalysis.googleapis.com"
  ]
}
