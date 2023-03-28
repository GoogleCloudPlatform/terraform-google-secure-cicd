/**
 * Copyright 2022 Google LLC
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

# Set up Cloud Deploy notifications
# (https://cloud.google.com/deploy/docs/subscribe-deploy-notifications)
resource "google_pubsub_topic" "clouddeploy_topic" {
  name    = local.clouddeploy_pubsub_topic_name
  project = var.project_id
  labels  = var.labels
}

# Trigger post-deploy checks on successful Cloud Deploy rollout
resource "google_cloudbuild_trigger" "deploy_trigger" {
  for_each = {
    for env, config in var.deploy_branch_clusters : env => config
    if config.next_env != ""
  }

  project  = var.project_id
  location = var.primary_location
  name     = each.value.target_type == "gke" ? "deploy-trigger-${each.value.cluster}" : each.value.target_type == "anthos_cluster" ? "deploy-trigger-${each.value.anthos_membership}" : "deploy-trigger-${each.key}"
  filename = "cloudbuild-cd.yaml"

  service_account = "projects/${var.project_id}/serviceAccounts/${var.cloudbuild_service_account}"

  pubsub_config {
    topic = google_pubsub_topic.clouddeploy_topic.id
  }

  source_to_build {
    uri       = "https://source.developers.google.com/p/${var.project_id}/r/${var.cloudbuild_cd_repo}"
    ref       = "main"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }

  substitutions = merge(
    {
      _GAR_REPOSITORY            = var.gar_repo_name
      _DEFAULT_REGION            = each.value.location
      _CLUSTER_NAME              = each.value.cluster
      _ANTHOS_MEMBERSHIP         = each.value.anthos_membership
      _TARGET_TYPE               = each.value.target_type
      _CLUSTER_PROJECT           = each.value.project_id
      _CLOUDBUILD_FILENAME       = var.app_deploy_trigger_yaml
      _CACHE_BUCKET_NAME         = var.cache_bucket_name
      _NEXT_ENV                  = each.value.next_env
      _ATTESTOR_NAME             = each.value.env_attestation
      _CLOUDBUILD_PRIVATE_POOL   = var.cloudbuild_private_pool
      _CLOUDDEPLOY_PIPELINE_NAME = var.clouddeploy_pipeline_name
      # Create substitutions to parse incoming Pub/sub messages from Cloud Deploy
      _ACTION_TYPE          = "$(body.message.attributes.Action)"
      _RESOURCE_TYPE        = "$(body.message.attributes.ResourceType)"
      _DELIVERY_PIPELINE_ID = "$(body.message.attributes.DeliveryPipelineId)"
      _TARGET_ID            = "$(body.message.attributes.TargetId)"
      _RELEASE_ID           = "$(body.message.attributes.ReleaseId)"

    },
    var.additional_substitutions
  )

  # Only trigger the post-deployment check on relevant Cloud Deploy activity (successful rollout to a target)
  filter = "_RESOURCE_TYPE.matches('Rollout') && _ACTION_TYPE.matches('Succeed') && _DELIVERY_PIPELINE_ID.matches('${var.clouddeploy_pipeline_name}') && _TARGET_ID.matches('${google_clouddeploy_target.deploy_target[each.key].name}')"
}
