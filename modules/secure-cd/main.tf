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

resource "google_sourcerepo_repository" "csr_cd_repository" {
  count = local.use_csr ? 1 : 0

  project                      = var.project_id
  name                         = var.csr_cloudbuild_cd_repo
  create_ignore_already_exists = true
}

module "cloudbuild_repositories" {
  count = local.use_csr ? 0 : 1

  source  = "terraform-google-modules/bootstrap/google//modules/cloudbuild_repo_connection"
  version = "12.0.0"

  project_id = var.project_id

  connection_config = {
    connection_type = "${var.repository_type}v2"

    github_secret_id        = var.github_auth != null ? var.github_auth.secret_id : null
    github_app_id_secret_id = var.github_auth != null ? var.github_auth.app_id_secret_id : null

    gitlab_read_authorizer_credential_secret_id = var.gitlab_auth != null ? var.gitlab_auth.read_authorizer_credential_secret_id : null
    gitlab_authorizer_credential_secret_id      = var.gitlab_auth != null ? var.gitlab_auth.authorizer_credential_secret_id : null
    gitlab_webhook_secret_id                    = var.gitlab_auth != null ? var.gitlab_auth.webhook_secret_id : null
    gitlab_enterprise_host_uri                  = var.gitlab_auth != null ? var.gitlab_auth.enterprise_host_uri : null
    gitlab_enterprise_service_directory         = var.gitlab_auth != null ? var.gitlab_auth.enterprise_service_directory : null
    gitlab_enterprise_ca_certificate            = var.gitlab_auth != null ? var.gitlab_auth.enterprise_ca_certificate : null
  }

  cloud_build_repositories = local.repos
}

resource "google_clouddeploy_target" "deploy_target" {
  for_each = { for env_obj in local.ordered_deploy_branch_clusters : env_obj.name => env_obj }

  name        = each.value.target_type == "anthos_cluster" ? "${each.value.anthos_membership}-target" : each.value.target_type == "gke" ? "${each.value.cluster}-target" : "${each.value.name}-target"
  description = "Target for ${each.value.name} environment"
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
      for_each = local.ordered_deploy_branch_clusters
      content {
        target_id = google_clouddeploy_target.deploy_target[stages.value.name].name
      }
    }
  }
}

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


