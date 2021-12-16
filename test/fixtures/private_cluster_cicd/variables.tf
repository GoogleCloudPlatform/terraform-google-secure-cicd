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
  description = "The ID of the CI/CD project to provision resources."
  type        = string
}

variable "org_id" {
  description = "The numeric organization id"
}

variable "folder_id" {
  description = "The folder to deploy in"
}

variable "primary_location" {
  type        = string
  description = "Region used for key-ring"
  default     = "us-central1"
}

variable "billing_account" {
  type        = string
  description = "The billing account id associated with the project, e.g. XXXXXX-YYYYYY-ZZZZZZ"
}

variable "gke_cluster_names" {
  type        = map(string)
  description = "map of env name to GKE cluster name"
}

variable "gke_project_ids" {
  type        = map(string)
  description = "map of env name to GKE project ID"
}

variable "gke_vpc_names" {
  type        = map(string)
  description = "map of env name to GKE network name"
}

variable "gke_service_accounts" {
  type        = map(string)
  description = "map of env name to GKE service account"
}