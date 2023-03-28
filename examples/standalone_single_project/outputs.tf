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

output "app_source_repo" {
  description = "URL of the created CSR app soure repo"
  value       = module.ci_pipeline.source_repo_urls["${var.app_name}-source"]
}

output "cloudbuild_cd_repo_name" {
  description = "URL of the created CSR app soure repo"
  value       = "${var.app_name}-cloudbuild-cd-config"
}

output "gar_repo" {
  description = "Artifact Registry repo"
  value       = module.ci_pipeline.app_artifact_repo
}

output "console_walkthrough_link" {
  description = "URL to open the in-console walkthrough."
  value       = "https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FGoogleCloudPlatform%2Fterraform-google-secure-cicd.git&cloudshell_git_branch=main&cloudshell_tutorial=examples%2Fstandalone_single_project%2Fwalkthrough.md&project=${var.project_id}"
}
