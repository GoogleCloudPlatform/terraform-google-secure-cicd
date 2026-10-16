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
  description = "Project ID in which all resources will be deployed"
}

variable "region" {
  type        = string
  description = "Location in which all regional resources will be deployed"
  default     = "us-central1"
}

variable "app_name" {
  type        = string
  description = "Name of intended deployed application; to be used as a prefix for certain resources"
  default     = "ci-cd"
}

variable "env1_name" {
  type        = string
  description = "Name of environment 1"
  default     = "dev"
}

variable "repository_type" {
  type        = string
  description = "Repository type, e.g. GITHUB or GITLAB"
  default     = "GITLAB"
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

variable "github_auth" {
  type = object({
    secret_id         = string
    app_id_secret_id  = string
    secret_project_id = string
  })
  description = "Authentication configuration for GitHub. Required only if repo_type is 'GITHUBv2'."
  default     = null
}

variable "ci_repository" {
  type = object({
    repository_name = string
    repository_url  = string
  })
  description = "The CI repository to configure. The key is a short name for the service."
  default     = null
}

variable "cd_repository" {
  type = object({
    repository_name = string
    repository_url  = string
  })
  description = "The CD repository to configure. The key is a short name for the service."
  default     = null
}

variable "env2_name" {
  type        = string
  description = "Name of environment 2"
  default     = "qa"
}

variable "env3_name" {
  type        = string
  description = "Name of environment 3"
  default     = "prod"
}

variable "cloudbuild_private_pool_machine_type" {
  type        = string
  description = "Machine type for Cloud Build private pool"
  default     = "e2-medium"
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the resources deployed by this blueprint."
  type        = map(string)
  default     = {}
}

variable "private_worker_pool_id" {
  description = "Optional private worker pool id if using already existing worker pool"
  validation {
    condition     = var.private_worker_pool_id != ""
    error_message = "private_worker_pool_id cannot be empty, only null or a valid value."
  }
  validation {
    condition     = var.private_worker_pool_id == null ? true : can(regex("^projects/[a-z0-9-]+/locations/[a-z0-9-]+/workerPools/[a-z0-9-]+$", var.private_worker_pool_id))
    error_message = "The private_worker_pool_id must follow the exact format: 'projects/PROJECT/locations/LOCATION/workerPools/POOL_NAME'."
  }
}

variable "network_name" {
  description = "Optional vpc network name if using already existing vpc"
  default     = null
}

variable "access_level_name" {
  description = "(VPC-SC) Access Level full name. When providing this variable, additional identities will be added to the access level, these are required to work within an enforced VPC-SC Perimeter."
  type        = string
  default     = null
}
