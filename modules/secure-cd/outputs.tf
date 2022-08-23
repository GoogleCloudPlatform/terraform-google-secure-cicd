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

output "deploy_trigger_names" {
  description = "Names of CD Cloud Build triggers"
  value       = [for trigger in google_cloudbuild_trigger.deploy_trigger : trigger.name]
}

output "binauthz_policy_required_attestations" {
  description = "Binary Authorization policy required attestation in GKE projects"
  value       = [for policy in google_binary_authorization_policy.deployment_policy : policy.cluster_admission_rules.*.require_attestations_by]
}

output "clouddeploy_delivery_pipeline_id" {
  description = "ID of the Cloud Deploy delivery pipeline"
  value       = google_clouddeploy_delivery_pipeline.pipeline.id
}

output "clouddeploy_target_id" {
  description = "ID(s) of Cloud Deploy targets"
  value       = [for target in google_clouddeploy_target.deploy_target : target.id]
}
