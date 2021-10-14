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

resource "google_cloudbuild_trigger" "dev_deploy_trigger" {
  project = var.project_id
  name    = "${var.app_source_repo}-trigger"
  trigger_template {
    branch_name = var.trigger_branch_name
    repo_name   = var.manifest_wet_repo
  }
  substitutions = merge(
    {
      _GAR_REPOSITORY    = local.gar_name
      _DEFAULT_REGION    = var.primary_location
      _CACHE_BUCKET_NAME = google_storage_bucket.cache_bucket.name
      _MANIFEST_WET_REPO = var.manifest_wet_repo
    },
    var.additional_substitutions
  )
  filename   = var.app_deploy_trigger_yaml
  depends_on = [google_sourcerepo_repository.repos]
}

// Binary Authorization Policy
resource "google_binary_authorization_policy" "deployment_policy" {
  admission_whitelist_patterns {
    name_pattern = "gcr.io/google_containers/*"
  }

  default_admission_rule {
    evaluation_mode  = "ALWAYS_DENY"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
  }

  global_policy_evaluation_mode = "ENABLE"

  // Prod Cluster Policy
  cluster_admission_rules {
    cluster                 = "${var.primary_location}.${var.prod_cluster_name}"
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.attestor.name] //TODO
  }

  // QA Cluster Policy
  cluster_admission_rules {
    cluster                 = "${var.primary_location}.${var.qa_cluster_name}"
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.attestor.name] //TODO
  }

  // Dev Cluster Policy
  cluster_admission_rules {
    cluster                 = "${var.primary_location}.${var.dev_cluster_name}"
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.attestor.name] //TODO
  }
}