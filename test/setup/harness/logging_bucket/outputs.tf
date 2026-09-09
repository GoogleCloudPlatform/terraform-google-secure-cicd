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

output "project_id_standalone" {
  value = var.project_id_standalone
}

output "logging_bucket" {
  value = module.logging_bucket.name
}

output "bucket_kms_key" {
  value = module.kms.keys["bucket"]
}

output "attestation_kms_key" {
  value = module.kms_attestor.keys["attestation"]
}
