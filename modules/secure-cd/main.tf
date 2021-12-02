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
}

data "google_project" "app_cicd_project" {
  project_id = var.project_id
}

resource "google_cloudbuild_trigger" "deploy_trigger" {
  for_each = var.deploy_branch_clusters
  project  = var.project_id
  name     = "deploy-trigger-${each.key}-${each.value.cluster}"

  trigger_template {
    branch_name = each.key
    repo_name   = var.manifest_wet_repo
  }
  substitutions = merge(
    {
      _GAR_REPOSITORY      = var.gar_repo_name
      _DEFAULT_REGION      = each.value.location
      _MANIFEST_WET_REPO   = var.manifest_wet_repo
      _CLUSTER_NAME        = each.value.cluster
      _CLUSTER_PROJECT     = each.value.project_id
      _CLOUDBUILD_FILENAME = var.app_deploy_trigger_yaml
      _CACHE_BUCKET_NAME   = var.cache_bucket_name
      _NEXT_ENV            = each.value.next_env
      _ATTESTOR_NAME       = each.value.env_attestation
    },
    var.additional_substitutions
  )
  filename = var.app_deploy_trigger_yaml

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
