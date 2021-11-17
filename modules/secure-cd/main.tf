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
 
}

data "google_project" "app_cicd_project" {
  project_id = var.project_id
}

resource "google_cloudbuild_trigger" "deploy_trigger" {
  for_each = var.deploy_branch_clusters
  project  = var.project_id
  name     = "deploy-trigger-${each.key}"

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
      _ATTESTOR_NAME       = each.value.next_env == "" ? "" : (var.deploy_branch_clusters[each.value.next_env].attestations[0])
    }
  )
  filename = var.app_deploy_trigger_yaml

}

// Binary Authorization Policy
resource "google_binary_authorization_policy" "deployment_policy" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  
  admission_whitelist_patterns {
    name_pattern = "gcr.io/google_containers/*"
  }

  default_admission_rule {
    evaluation_mode  = "ALWAYS_DENY"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
  }

  global_policy_evaluation_mode = "ENABLE"

  cluster_admission_rules {
    cluster                 = "${each.value.location}.${each.value.cluster}" 
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = each.value.attestations //TODO?
  }
}

## IAM bindings for Cloud Build SA to allow deployment to GKE (roles/container.developer)

resource "google_project_iam_member" "gke_dev" {
  for_each = var.deploy_branch_clusters
  project  = each.value.project_id
  role     = "roles/container.developer"
  member   = "serviceAccount:${data.google_project.app_cicd_project.number}@cloudbuild.gserviceaccount.com"
} 


## IAM bindings for GKE projects to access container images from GAR
## TODO: we can't be sure that they will be using the default GCE SA, so how do we automate this permissioning?
data "google_project" "gke_projects" {
  for_each = var.deploy_branch_clusters
  project_id = each.value.project_id
}
resource "google_project_iam_member" "gke_gar_reader" {
  for_each = var.deploy_branch_clusters
  project = var.project_id
  role = "roles/artifactregistry.reader"
  member = "serviceAccount:${data.google_project.gke_projects[each.key].number}-compute@developer.gserviceaccount.com"
}