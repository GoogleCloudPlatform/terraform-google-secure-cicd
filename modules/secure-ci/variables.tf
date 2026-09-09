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
  description = "Primary Google Cloud region for deploying resources like Artifact Registry, Cloud Storage buckets, and Cloud Build triggers."
}

variable "attestor_names_prefix" {
  description = "A list of Binary Authorization attestors to create. The first attestor specified in this list will be used as the build-attestor during the CI phase."
  type        = list(string)
}

variable "access_level_name" {
  description = "(VPC-SC) Access Level full name. When providing this variable, additional identities will be added to the access level, these are required to work within an enforced VPC-SC Perimeter."
  type        = string
  default     = null
}

variable "app_build_trigger_yaml" {
  type        = string
  description = "Name of application cloudbuild yaml file"
}

variable "csr_app_source_repo" {
  type        = string
  description = "Name of repo that contains app source code along with cloudbuild yaml"
  default     = "app-source"
}

variable "cache_bucket_name" {
  type        = string
  description = "Name of cloudbuild artifact and cache GCS bucket"
  default     = ""
}

variable "gar_repo_name_suffix" {
  type        = string
  description = "Docker artifact registry repo to store app build images"
  default     = "app-image-repo"
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
    "roles/cloudbuild.connectionViewer",
    "roles/clouddeploy.developer",
    "roles/clouddeploy.releaser",
    "roles/cloudkms.cryptoOperator",
    "roles/containeranalysis.notes.attacher",
    "roles/containeranalysis.notes.occurrences.viewer",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/source.writer",
    "roles/storage.admin",
    "roles/cloudbuild.workerPoolUser",
    "roles/ondemandscanning.admin",
    "roles/logging.logWriter"
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
  default     = "deploy-pipeline"
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the resources deployed by this blueprint."
  type        = map(string)
  default     = {}
}

variable "bucket_kms_key" {
  description = "KMS Key id to be used to encrypt bucket."
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

variable "ci_repository" {
  type = object({
    repository_name = string
    repository_url  = string
  })
  description = "The CI repository to configure. The key is a short name for the service."
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
