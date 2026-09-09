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

locals {
  skaffold_builder_version    = "1.0.0"
  skaffold_builder_image_name = "skaffold-builder"
  skaffold_builder_image_tag  = "${var.primary_location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.image_repo.name}/${local.skaffold_builder_image_name}:${local.skaffold_builder_version}"
}

resource "null_resource" "build_skaffold_builder_image" {
  triggers = {
    skaffold_builder_version = local.skaffold_builder_version
    project_id               = var.project_id
    region                   = var.primary_location
    gar_repo_name            = google_artifact_registry_repository.image_repo.name
  }

  provisioner "local-exec" {
    command = <<-EOT
      gcloud builds submit "${path.module}/cloud-build-builder" \
        --config="${path.module}/cloud-build-builder/cloudbuild-skaffold-build-image.yaml" \
        --project="${var.project_id}" \
        --region="${var.primary_location}" \
        --substitutions=_DEFAULT_REGION="${var.primary_location}",_GAR_REPOSITORY="${google_artifact_registry_repository.image_repo.name}" \
        --service-account="${google_service_account.build_sa.id}" \
        --gcs-log-dir="${google_storage_bucket.cache_bucket.url}/cloudbuild-logs" \
        --worker-pool="${var.cloudbuild_private_pool}"
    EOT
  }

  depends_on = [
    google_artifact_registry_repository.image_repo,
    google_service_account.build_sa,
    google_storage_bucket.cache_bucket,
    google_project_iam_member.build_sa_project_iam,
    time_sleep.wait_for_cb_iam
  ]
}
