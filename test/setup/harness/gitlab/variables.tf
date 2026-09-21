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

variable "project_id_workerpool" {
  description = "The project id where Gitlab will run."
  type        = string
}

variable "project_id_kms" {
  description = "The project id where KMS/Secrets will be created on."
  type        = string
}

variable "network_name" {
  description = "The network name where Gitlab will run."
  type        = string
}

variable "network_id" {
  description = "The network id where Gitlab will run."
  type        = string
}

variable "cloud_build_sa" {
  description = "Cloud Build Service Account email to be granted Encrypt/Decrypt role."
  type        = string
}

variable "project_number_workerpool" {
  description = "The workerpool project number."
  type        = string
}

variable "project_number_kms" {
  description = "The kms/secret project number."
  type        = string
}

variable "bucket_kms_crypto_id" {
  description = "KMS key id used to encrypt buckets."
  type        = string
  default     = null
}

variable "attestation_kms_crypto_id" {
  description = "KMS key id used for image attestation."
  type        = string
}

variable "logging_bucket_name" {
  description = "The name of the logging bucket."
  type        = string
}

variable "logging_kms_crypto_id" {
  description = "The KMS key for the logging bucket."
  type        = string
}
