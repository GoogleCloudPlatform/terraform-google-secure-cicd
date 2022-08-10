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
  attestor_iam_config = flatten([
    for env_key, env in var.deploy_branch_clusters : [
      for attestor in env.required_attestations : {
        env      = env_key
        attestor = split("/", attestor)[3]
      }
    ]
  ])

  deploy_projects = distinct([
    for env in var.deploy_branch_clusters : env.project_id
  ])
  binary_authorization_map = zipmap(
    local.deploy_projects,
    [for project_id in local.deploy_projects : [
      for env in var.deploy_branch_clusters : env if env.project_id == project_id
    ]]
  )

  cd_sa_required_roles = [
    "roles/clouddeploy.jobRunner",
  ]

  clouddeploy_pubsub_topic_name = "clouddeploy-operations"
}

# Cluod Deploy Execution Service Account
# https://cloud.google.com/deploy/docs/cloud-deploy-service-account#execution_service_account
resource "google_service_account" "clouddeploy_execution_sa" {
  project      = var.project_id
  account_id   = "clouddeploy-execution-sa"
  display_name = "clouddeploy-execution-sa"
}

resource "google_project_iam_member" "cd_sa_iam" {
  for_each = toset(local.cd_sa_required_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.clouddeploy_execution_sa.email}"
}

# IAM membership for Cloud Build SA to act as Cloud Deploy Execution SA
resource "google_service_account_iam_member" "cloudbuild_clouddeploy_impersonation" {
  service_account_id = google_service_account.clouddeploy_execution_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${data.google_project.app_cicd_project.number}@cloudbuild.gserviceaccount.com"
}

# IAM membership for Cloud Deploy Execution SA deploy to GKE
resource "google_project_iam_member" "clouddeploy_gke_dev" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/container.developer"
  member   = "serviceAccount:${google_service_account.clouddeploy_execution_sa.email}"
}

resource "google_clouddeploy_target" "deploy_target" {
  for_each = var.deploy_branch_clusters

  name        = "${each.value.cluster}-target"
  description = "Target for ${each.key} environment"
  location    = each.value.location
  project     = var.project_id

  gke {
    cluster = "projects/${each.value.project_id}/locations/${each.value.location}/clusters/${each.value.cluster}"
  }

  execution_configs {
    usages          = ["RENDER", "DEPLOY"]
    worker_pool     = var.cloudbuild_private_pool
    service_account = google_service_account.clouddeploy_execution_sa.email
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

data "google_project" "app_cicd_project" {
  project_id = var.project_id
}

# Set up Cloud Deploy notifications
# (https://cloud.google.com/deploy/docs/subscribe-deploy-notifications)
resource "google_pubsub_topic" "clouddeploy_topic" {
  name     = local.clouddeploy_pubsub_topic_name
  project  = var.project_id
}

# Trigger post-deploy checks on successful Cloud Deploy rollout
resource "google_cloudbuild_trigger" "deploy_trigger" {
  for_each = {
    for env, config in var.deploy_branch_clusters : env => config
    if config.next_env != ""
  }

  project = var.project_id
  name    = "deploy-trigger-${each.value.cluster}"

  pubsub_config {
    topic = google_pubsub_topic.clouddeploy_topic.id
  }

  source_to_build {
    uri       = "https://source.developers.google.com/p/${var.project_id}/r/${var.cloudbuild_cd_repo}"
    ref       = "main"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }

  filename = "cloudbuild-cd.yaml"

  substitutions = merge(
    {
      _GAR_REPOSITORY            = var.gar_repo_name
      _DEFAULT_REGION            = each.value.location
      _CLUSTER_NAME              = each.value.cluster
      _CLUSTER_PROJECT           = each.value.project_id
      _CLOUDBUILD_FILENAME       = var.app_deploy_trigger_yaml
      _CACHE_BUCKET_NAME         = var.cache_bucket_name
      _NEXT_ENV                  = each.value.next_env
      _ATTESTOR_NAME             = each.value.env_attestation
      _CLOUDBUILD_PRIVATE_POOL   = var.cloudbuild_private_pool
      _CLOUDDEPLOY_PIPELINE_NAME = var.clouddeploy_pipeline_name
      # Create substitutions to parse incoming Pub/sub messages from Cloud Deploy
      _ACTION_TYPE               = "$(body.message.attributes.Action)"
      _RESOURCE_TYPE             = "$(body.message.attributes.ResourceType)"
      _DELIVERY_PIPELINE_ID      = "$(body.message.attributes.DeliveryPipelineId)"
      _TARGET_ID                 = "$(body.message.attributes.TargetId)"
      _RELEASE_ID                = "$(body.message.attributes.ReleaseId)"

    },
    var.additional_substitutions
  )

  # Only trigger the post-deployment check on relevant Cloud Deploy activity (successful rollout to a target)
  filter = "_RESOURCE_TYPE.matches('Rollout') && _ACTION_TYPE.matches('Succeed') && _DELIVERY_PIPELINE_ID.matches('${var.clouddeploy_pipeline_name}') && _TARGET_ID.matches('${google_clouddeploy_target.deploy_target[each.key].name}')"
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

# IAM membership for Cloud Build SA to allow deployment to GKE
resource "google_project_iam_member" "gke_dev" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/container.developer"
  member   = "serviceAccount:${data.google_project.app_cicd_project.number}@cloudbuild.gserviceaccount.com"
}

# Cloud Deploy Service Agent
resource "google_project_service_identity" "clouddeploy_service_agent" {
  provider = google-beta

  project = var.project_id
  service = "clouddeploy.googleapis.com"
}

resource "google_project_iam_member" "clouddeploy_service_agent_role" {
  project = var.project_id
  role    = "roles/clouddeploy.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.clouddeploy_service_agent.email}"
}

# IAM membership for Binary Authorization service agents in GKE projects on attestors
data "google_project" "gke_projects" {
  for_each   = var.deploy_branch_clusters
  project_id = each.value.project_id
}
resource "google_binary_authorization_attestor_iam_member" "binauthz_verifier" {
  for_each = { for entry in local.attestor_iam_config : "${entry.env}.${entry.attestor}" => entry } # turn into a map
  project  = var.project_id
  attestor = each.value.attestor
  role     = "roles/binaryauthorization.attestorsVerifier"
  member   = "serviceAccount:service-${data.google_project.gke_projects[each.value.env].number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
}

