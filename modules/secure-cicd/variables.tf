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
  description = "A list of Cloud Source Repos to be created to hold app infra Terraform configs"
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

variable "additional_substitutions" {
  description = "Parameters to be substituted in the build specification. All keys should begin with an underscore."
  type        = map(string)
  default     = {}
}

variable "trigger_branch_name" {
  type        = string
  description = "A regular expression to match one or more branches for the build trigger."
}
