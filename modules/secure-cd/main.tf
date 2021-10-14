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
  for_each = toset(var.deploy_branches)
  project = var.project_id
  name    = "deploy-trigger-${each.value}"
  trigger_template {
    branch_name = each.value
    repo_name   = var.manifest_wet_repo
  }
  substitutions = merge(
    {
      _GAR_REPOSITORY    = local.gar_name
      _DEFAULT_REGION    = var.primary_location
      _MANIFEST_WET_REPO = var.manifest_wet_repo
      _ENVIRONMENT       = each.value // TODO: is this necessary or can we just know the branch inherently
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
    require_attestations_by = ["security-attestor", "quality-attestor", "build-attestor"] //TODO
  }

  // QA Cluster Policy
  cluster_admission_rules {
    cluster                 = "${var.primary_location}.${var.qa_cluster_name}"
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = ["security-attestor", "build-attestor"] //TODO
  }

  // Dev Cluster Policy
  cluster_admission_rules {
    cluster                 = "${var.primary_location}.${var.dev_cluster_name}"
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = ["security-attestor"] //TODO
  }
}