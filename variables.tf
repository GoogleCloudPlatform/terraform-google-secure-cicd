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

variable "deploy_branch_clusters" {
  type = map(object({
    cluster      = string
    project_id   = string
    location     = string
    attestations = list(string)
    next_env     = string
  }))
  description = "mapping of branch names to cluster deployments"
  default     = {}
}

variable "app_source_repo_name" {
    type        = string
    description = "Name of CSR repo to build for application source code"
    default     = "app-source"
}

variable "manifest_dry_repo_name" {
    type        = string
    description = "Name of CSR repo to build for dry Kubernetes manifests"
    default     = "app-dry-manifests"
}

variable "manifest_wet_repo_name" {
    type        = string
    description = "Name of CSR repo to build for wet Kubernetes manifests"
    default     = "app-wet-manifests"
}

variable "gar_repo_name_suffix" {
    type        = string
    description = "Suffix to append to GAR repo name"
    default     = "app-image-repo"
}

variable "gar_repo_name_suffix" {
    type        = list(string)
    description = "List of Binary Authorization attestors to create for"
    default     = ["build", "security", "quality"]
}

variable "app_build_trigger_yaml" {
    type        = string
    description = "Filename for CI pipeline Cloud Build config"
    default     = "cloudbuild-ci.yaml"
}

variable "runner_build_folder" {
    type        = string
    description = "Path to Cloud Build builder image folder"
    default     = "./examples/app_cicd/cloud-build-builder"
}

variable "build_image_config_yaml" {
    type        = string
    description = "Cloud Build builder image config file name"
    default     = "cloudbuild-skaffold-build-image.yaml"
}

variable "app_build_trigger_branch_name" {
    type        = string
    description = "Branch name on which to trigger App Source builds"
    default     = ".*"
}

variable "app_deploy_trigger_yaml" {
    type        = string
    description = "Filename for CD pipeline Cloud Build config"
    default     = "cloudbuild-cd.yaml"
}