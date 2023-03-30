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

variable "gke_networks" {
  type = list(object({
    control_plane_cidrs = map(string)
    location            = string
    network             = string
    project_id          = string
  }))
  description = "list of GKE cluster networks in which to create VPN connections"
}

variable "deploy_branch_clusters" {
  type = map(object({
    cluster               = string
    anthos_membership     = string
    project_id            = string
    location              = string
    required_attestations = list(string)
    env_attestation       = string
    next_env              = string
    target_type           = string
  }))
  description = "mapping of branch names to cluster deployments. target_type can be one of `gke`, `anthos_cluster`, or `run`. See [clouddeploy_target Terraform docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_target) for more details"
  default     = {}
}
