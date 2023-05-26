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
  description = "Project ID for Cloud Build Private Worker Pool"
}

variable "network_project_id" {
  type        = string
  description = "Project ID for Cloud Build network."
}

variable "create_cloudbuild_network" {
  type        = bool
  description = "Whether to create a VPC for the Cloud Build Worker Pool. Set to false if providing an existing VPC name in 'private_pool_vpc_name' "
}

variable "private_pool_vpc_name" {
  type        = string
  description = "Set the name of the private pool VPC"
  default     = "cloudbuild-vpc"
}

variable "worker_address" {
  type        = string
  description = "Choose an address range for the Cloud Build Private Pool workers. example: 10.37.0.0. Do not include a prefix length."
  default     = "10.37.0.0"
}

variable "worker_address_prefix_length" {
  type        = string
  description = "Prefix length, such as 24 for /24 or 16 for /16. Must be 24 or lower."
  default     = "16"
}

variable "worker_pool_name" {
  type        = string
  description = "Name of Cloud Build Worker Pool"
  default     = "cloudbuild-private-worker-pool"
}

variable "worker_range_name" {
  type        = string
  description = "Name of Cloud Build Worker IP address range"
  default     = "worker-pool-range"
}

variable "worker_pool_no_external_ip" {
  type        = bool
  description = "Whether to disable external IP on the Cloud Build Worker Pool"
  default     = false
}

variable "location" {
  type        = string
  description = "Region for Cloud Build worker pool"
  default     = "us-central1"
}

variable "machine_type" {
  type        = string
  description = "Machine type for Cloud Build worker pool"
  default     = "e2-medium"

  validation {
    condition     = contains(["e2-medium", "e2-standard-2", "e2-standard-4", "e2-standard-8", "e2-standard-16", "e2-standard-32", "e2-highmem-2", "e2-highmem-4", "e2-highmem-8", "e2-highmem-16", "e2-highcpu-2", "e2-highcpu-4", "e2-highcpu-8", "e2-highcpu-16", "e2-highcpu-32", ], var.machine_type)
    error_message = "Valid machine typees for Cloud Build private pools are: e2-medium, e2-standard-2, e2-standard-4, e2-standard-8, e2-standard-16, e2-standard-32, e2-highmem-2, e2-highmem-4, e2-highmem-8, e2-highmem-16, e2-highcpu-2, e2-highcpu-4, e2-highcpu-8, e2-highcpu-16, e2-highcpu-32"
  }
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the resources deployed by this blueprint."
  type        = map(string)
  default     = {}
}
