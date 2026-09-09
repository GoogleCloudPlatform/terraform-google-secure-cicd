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

variable "project_id_standalone" {
  description = "The seed project."
  type        = string
}

variable "sa_email" {
  description = "The ci service account email created by setup to run the tests."
  type        = string
}

variable "cloud_build_sa" {
  description = "Cloud Build Service Account email to be granted Encrypt/Decrypt role."
  type        = string
}

variable "region" {
  description = "Region where KMS and Logging bucket will be deployed."
  type        = string
  default     = "us-central1"
}
