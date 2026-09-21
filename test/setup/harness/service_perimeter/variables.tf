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

variable "org_id" {
  description = "The numeric organization id"
  type        = string
}

variable "folder_id" {
  description = "Seed folder id."
  type        = string
}

variable "gitlab_sa" {
  description = "SA used by gitlab instance."
  type        = string
}

variable "project_id" {
  type        = string
  description = "Project ID in which all resources will be deployed"
}

variable "gitlab_project_number" {
  type        = string
  description = "Project number in which the gitlab VM and the private worker pool will be deployed"
}

variable "logging_bucket_project_number" {
  type        = string
  description = "Project number in which the attestors, logging buckets and KMS keys will be deployed"
}

variable "protected_projects" {
  description = "The projects number to be protected."
  type        = list(string)
}

variable "service_perimeter_mode" {
  description = "(VPC-SC) Service perimeter mode: ENFORCE, DRY_RUN."
  type        = string
  default     = "DRY_RUN"

  validation {
    condition     = contains(["ENFORCE", "DRY_RUN"], var.service_perimeter_mode)
    error_message = "The service_perimeter_mode value must be one of: ENFORCE, DRY_RUN."
  }
}

variable "access_level_members" {
  description = "Extra access level members. serviceAccount:EMAIL@DOMAIN or user:EMAIL@DOMAIN"
  type        = list(string)
  default     = []
}
