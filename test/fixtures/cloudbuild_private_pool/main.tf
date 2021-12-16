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

module "example" {
  source = "../../../examples/gke_cloudbuild_private_pool"

  project_id       = var.project_id
  primary_location = var.primary_location
  deploy_branch_clusters = {
    dev = {
      cluster               = "dev-private-cluster",
      network               = var.gke_vpc_names["dev"]
      project_id            = var.gke_project_ids["dev"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/security-attestor"
      next_env              = "qa"
    },
    qa = {
      cluster               = "qa-private-cluster",
      network               = var.gke_vpc_names["qa"]
      project_id            = var.gke_project_ids["qa"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/quality-attestor"
      next_env              = "prod"
    },
    prod = {
      cluster               = "prod-private-cluster",
      network               = var.gke_vpc_names["prod"]
      project_id            = var.gke_project_ids["prod"],
      location              = var.primary_location,
      required_attestations = ["projects/${var.project_id}/attestors/quality-attestor", "projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = ""
      next_env              = ""
    },
  }
}
