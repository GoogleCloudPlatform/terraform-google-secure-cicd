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

variable "project_id" {
  type        = string
  description = "Project ID for CICD Pipeline Project"
}

variable "primary_location" {
  type        = string
  description = "Primary Google Cloud region for deploying resources like Cloud Build triggers and Cloud Deploy pipelines."
}

variable "csr_cloudbuild_cd_repo" {
  type        = string
  description = "Name of the CSR repo that stores the Cloud Build CD phase configs - for post-deployment checks"
  default     = null
}

variable "gar_repo_name" {
  type        = string
  description = "Docker artifact registry repo to store app build images"
}

variable "app_deploy_trigger_yaml" {
  type        = string
  description = "Name of application cloudbuild yaml file for deployment"
}

variable "deploy_branch_clusters" {
  type = map(object({
    name                  = string
    cluster               = string
    anthos_membership     = string
    project_id            = string
    location              = string
    required_attestations = list(string)
    env_attestation       = string
    env_number            = number
    target_type           = string
  }))
  description = "A list of environment deployments, ordered by 'env_number'. target_type can be one of `gke`, `anthos_cluster`, or `run`. See [clouddeploy_target Terraform docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_target) for more details"
  default     = {}
}

variable "cache_bucket_name" {
  description = "cloud build artifact bucket name"
  type        = string
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
}

variable "cloudbuild_service_account" {
  description = "Cloud Build SA email address"
  type        = string
}

variable "access_level_name" {
  description = "(VPC-SC) Access Level full name. When providing this variable, additional identities will be added to the access level, these are required to work within an enforced VPC-SC Perimeter."
  type        = string
  default     = null
}

variable "repository_type" {
  description = "The type of the repository. Must be one of 'GITHUB', 'GITLAB', or 'CSR'."
  type        = string
  validation {
    condition = (
      var.repository_type != "GITHUB" ||
      (var.github_auth != null && var.gitlab_auth == null)
    )
    error_message = "When repository_type is 'GITHUB', the 'github_auth' variable must be set, and 'gitlab_auth' must not be set."
  }
  validation {
    condition = (
      var.repository_type != "GITLAB" ||
      (var.gitlab_auth != null && var.github_auth == null)
    )
    error_message = "When repository_type is 'GITLAB', the 'gitlab_auth' variable must be set, and 'github_auth' must not be set."
  }
  validation {
    condition = (
      var.repository_type != "CSR" ||
      (var.github_auth == null && var.gitlab_auth == null)
    )
    error_message = "When repository_type is 'CSR', neither 'github_auth' nor 'gitlab_auth' should be set."
  }
}

variable "cd_repository" {
  type = object({
    repository_name = string
    repository_url  = string
  })
  description = "The CD repository to configure. The key is a short name for the service."
  default     = null
}
variable "github_auth" {
  type = object({
    secret_id         = string
    app_id_secret_id  = string
    secret_project_id = string
  })
  description = "Authentication configuration for GitHub. Required only if repo_type is 'GITHUBv2'."
  default     = null
}

variable "gitlab_auth" {
  type = object({
    read_authorizer_credential_secret_id = string
    authorizer_credential_secret_id      = string
    webhook_secret_id                    = string
    enterprise_host_uri                  = optional(string)
    enterprise_service_directory         = optional(string)
    enterprise_ca_certificate            = optional(string)
    secret_project_id                    = string
  })
  description = "Authentication configuration for GitLab. Required only if repo_type is 'GITLABv2'."
  default     = null
}
