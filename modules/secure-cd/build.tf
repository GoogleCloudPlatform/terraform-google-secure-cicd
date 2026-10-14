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

# Set up Cloud Deploy notifications
# (https://cloud.google.com/deploy/docs/subscribe-deploy-notifications)

resource "google_cloudbuild_trigger" "deploy_trigger_unknown" {
  for_each = {
    for i, env_obj in local.ordered_deploy_branch_clusters : env_obj.name => env_obj
    if env_obj.env_number < length(var.deploy_branch_clusters) && local.cd_repo_source.repo_type == "UNKNOWN"
  }

  project  = var.project_id
  location = var.primary_location
  name     = each.value.target_type == "gke" ? "deploy-trigger-${each.value.cluster}" : each.value.target_type == "anthos_cluster" ? "deploy-trigger-${each.value.anthos_membership}" : "deploy-trigger-${each.key}"
  filename = "cloudbuild-cd.yaml"

  service_account = "projects/${var.project_id}/serviceAccounts/${var.cloudbuild_service_account}"
  source_to_build {
    ref        = "main"
    repo_type  = "UNKNOWN"
    repository = local.cd_repo_source.repository
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
      _ATTESTOR_NAME             = each.value.env_attestation
      _CLOUDBUILD_PRIVATE_POOL   = var.cloudbuild_private_pool
      _CLOUDDEPLOY_PIPELINE_NAME = var.clouddeploy_pipeline_name
      _DELIVERY_PIPELINE_ID      = var.clouddeploy_pipeline_name
      _TARGET_ID                 = google_clouddeploy_target.deploy_target[each.key].name
    },
    var.additional_substitutions
  )

  lifecycle {
    ignore_changes = [
      source_to_build[0].repo_type
    ]
  }
}

resource "google_cloudbuild_trigger" "deploy_trigger_known" {
  for_each = {
    for i, env_obj in local.ordered_deploy_branch_clusters : env_obj.name => env_obj
    if env_obj.env_number < length(var.deploy_branch_clusters) && local.cd_repo_source.repo_type != "UNKNOWN"
  }

  project  = var.project_id
  location = var.primary_location
  name     = each.value.target_type == "gke" ? "deploy-trigger-${each.value.cluster}" : each.value.target_type == "anthos_cluster" ? "deploy-trigger-${each.value.anthos_membership}" : "deploy-trigger-${each.key}"
  filename = "cloudbuild-cd.yaml"

  service_account = "projects/${var.project_id}/serviceAccounts/${var.cloudbuild_service_account}"

  source_to_build {
    ref        = "main"
    repo_type  = local.cd_repo_source.repo_type
    repository = local.cd_repo_source.repository
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
      _ATTESTOR_NAME             = each.value.env_attestation
      _CLOUDBUILD_PRIVATE_POOL   = var.cloudbuild_private_pool
      _CLOUDDEPLOY_PIPELINE_NAME = var.clouddeploy_pipeline_name
      _DELIVERY_PIPELINE_ID      = var.clouddeploy_pipeline_name
      _TARGET_ID                 = google_clouddeploy_target.deploy_target[each.key].name
    },
    var.additional_substitutions
  )
}
