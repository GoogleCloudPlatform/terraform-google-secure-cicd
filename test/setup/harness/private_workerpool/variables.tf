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

variable "folder_id" {
  description = "The folder to deploy in"
  type        = string
}

variable "project_id_standalone" {
  description = "The seed project id"
  type        = string
}

variable "project_number_standalone" {
  description = "The seed project number"
  type        = string
}

variable "org_id" {
  description = "The numeric organization id"
  type        = string
}

variable "billing_account" {
  description = "The billing account id associated with the project, e.g. XXXXXX-YYYYYY-ZZZZZZ"
  type        = string
}

variable "workpool_region" {
  description = "The region to deploy in"
  type        = string
  default     = "us-central1"
}

variable "workerpool_machine_type" {
  description = "The workerpool machine type"
  type        = string
  default     = "e2-standard-4"
}
