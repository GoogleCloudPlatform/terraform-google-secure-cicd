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

locals {
  deploy_projects = distinct([
    for env in var.deploy_branch_clusters : env.project_id
  ])

  binary_authorization_map = zipmap(
    local.deploy_projects,
    [for project_id in local.deploy_projects : [
      for env in var.deploy_branch_clusters : env if env.project_id == project_id
    ]]
  )

  clouddeploy_pubsub_topic_name = "clouddeploy-operations"
}

resource "google_clouddeploy_target" "deploy_target" {
  provider = google-beta
  for_each = var.deploy_branch_clusters

  name        = each.value.target_type == "anthos_cluster" ? "${each.value.anthos_membership}-target" : each.value.target_type == "gke" ? "${each.value.cluster}-target" : "${each.key}-target"
  description = "Target for ${each.key} environment"
  location    = each.value.location
  project     = var.project_id

  dynamic "gke" {
    for_each = lower(each.value.target_type) == "gke" ? [1] : []
    content {
      cluster = "projects/${each.value.project_id}/locations/${each.value.location}/clusters/${each.value.cluster}"
    }
  }

  dynamic "anthos_cluster" {
    for_each = lower(each.value.target_type) == "anthos_cluster" ? [1] : []
    content {
      membership = "projects/${each.value.project_id}/locations/global/memberships/${each.value.anthos_membership}"
    }
  }

  dynamic "run" {
    for_each = lower(each.value.target_type) == "run" ? [1] : []
    content {
      location = "projects/${each.value.project_id}/locations/${each.value.location}"
    }
  }

  execution_configs {
    usages           = ["RENDER", "DEPLOY"]
    worker_pool      = var.cloudbuild_private_pool
    artifact_storage = "gs://${var.cache_bucket_name}/clouddeploy-artifacts"
    service_account  = google_service_account.clouddeploy_execution_sa.email
  }

  depends_on = [
    google_project_iam_member.clouddeploy_service_agent_role
  ]
}

resource "google_clouddeploy_delivery_pipeline" "pipeline" {
  name        = var.clouddeploy_pipeline_name
  description = "Pipeline for application" #TODO parameterize
  project     = var.project_id
  location    = var.primary_location

  serial_pipeline {
    dynamic "stages" {
      for_each = var.deploy_branch_clusters
      content {
        target_id = google_clouddeploy_target.deploy_target[stages.key].name
      }
    }
  }
}

# Binary Authorization Policy
resource "google_binary_authorization_policy" "deployment_policy" {
  for_each = local.binary_authorization_map
  project  = each.key

  default_admission_rule {
    evaluation_mode  = "ALWAYS_DENY"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
  }

  global_policy_evaluation_mode = "ENABLE"

  dynamic "cluster_admission_rules" {
    for_each = each.value
    content {
      cluster                 = "${cluster_admission_rules.value.location}.${cluster_admission_rules.value.cluster}"
      evaluation_mode         = "REQUIRE_ATTESTATION"
      enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
      require_attestations_by = cluster_admission_rules.value.required_attestations
    }
  }
}


