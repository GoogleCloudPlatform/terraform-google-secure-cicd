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

variable "project_id" {
  type        = string
  description = "Project ID for CICD Pipeline Project"
}

variable "primary_location" {
  type        = string
  description = "Region used for key-ring"
}

variable "attestor_names_prefix" {
  description = "A list of Binary Authorization attestors to create. The first attestor specified in this list will be used as the build-attestor during the CI phase."
  type        = list(string)
}

variable "app_build_trigger_yaml" {
  type        = string
  description = "Name of application cloudbuild yaml file"
}

variable "runner_build_folder" {
  type        = string
  description = "Path to the source folder for the cloud builds submit command"
}

variable "build_image_config_yaml" {
  type        = string
  description = "Name of image builder yaml file"
}

variable "app_source_repo" {
  type        = string
  description = "Name of repo that contains app source code along with cloudbuild yaml"
  default     = "app-source"
}

variable "manifest_dry_repo" {
  type        = string
  description = "Name of repo that contains template K8s manifests files"
  default     = "app-dry-manifests"
}

variable "manifest_wet_repo" {
  type        = string
  description = "Name of repo that will receive hydrated K8s manifests files"
  default     = "app-wet-manifests"
}

variable "wet_branch_name" {
  type        = string
  description = "Name of branch in the wet manifest repo that CI pipeline will push to (usually, the name of the first deployed environment)"
  default     = "dev"
}

variable "cache_bucket_name" {
  type        = string
  description = "Name of cloudbuild artifact and cache GCS bucket"
  default     = ""
}

variable "gar_repo_name_suffix" {
  type        = string
  description = "Docker artifact regitery repo to store app build images"
  default     = "app-image-repo"
}

variable "use_tf_google_credentials_env_var" {
  description = "Optional GOOGLE_CREDENTIALS environment variable to be activated."
  type        = bool
  default     = false
}

variable "trigger_branch_name" {
  type        = string
  description = "A regular expression to match one or more branches for the build trigger."
}

variable "cloudbuild_service_account_roles" {
  type        = list(string)
  description = "IAM roles given to the Cloud Build service account to enable security scanning operations"
  default = [
    "roles/artifactregistry.admin",
    "roles/binaryauthorization.attestorsVerifier",
    "roles/cloudbuild.builds.builder",
    "roles/cloudkms.cryptoOperator",
    "roles/containeranalysis.notes.attacher",
    "roles/containeranalysis.notes.occurrences.viewer",
    "roles/source.writer",
    "roles/storage.admin",
    "roles/cloudbuild.workerPoolUser",
    "roles/ondemandscanning.admin",
  ]
}

variable "additional_substitutions" {
  description = "Parameters to be substituted in the build specification. All keys should begin with an underscore."
  type        = map(string)
  default     = {}
}

variable "cloudbuild_private_pool" {
  description = "Cloud Build private pool self-link"
  type        = string
  default     = ""
}

variable "clouddeploy_pipeline_name" {
  description = "Cloud Deploy pipeline name"
  type        = string
  default     = ""
}