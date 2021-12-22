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
  description = "Project ID for Cloud Build Private Pool VPC"
}

variable "private_pool_vpc_name" {
  type        = string
  description = "Set the name of the private pool VPC"
  default     = "cloudbuild-vpc"
}

variable "worker_address" {
  type        = string
  description = "Choose an address range for the Cloud Build Private Pool workers. example: 10.37.0.0. Do not include a prefix, as it must be /16"
}

variable "worker_pool_name" {
  type        = string
  description = "Name of Cloud Build Worker Pool"
  default     = "cloudbuild-private-worker-pool"
}

variable "vpn_router_name_prefix" {
  type        = string
  description = "Prefix for HA VPN router names"
  default     = ""
}

variable "location" {
  type        = string
  description = "Region for Cloud Build worker pool"
  default     = "us-central1"
}

variable "machine_type" {
  type        = string
  description = "Machine type for Cloud Build worker pool"
  default     = "e2-standard-4"
}

variable "deploy_branch_clusters" {
  type = map(object({
    cluster               = string
    network               = string
    project_id            = string
    location              = string
    required_attestations = list(string)
    env_attestation       = string
    next_env              = string
  }))
  description = "mapping of branch names to cluster deployments"
  default     = {}
}
