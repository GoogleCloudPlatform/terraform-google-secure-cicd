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

output "webhook_secret_id" {
  value = google_secret_manager_secret.gitlab_webhook.id
}

output "gitlab_pat_secret_name" {
  value = "gitlab-pat-from-vm"
}

output "gitlab_project_id" {
  value = var.project_id_workerpool
}

output "gitlab_project_number" {
  value = var.project_number_workerpool
}

output "gitlab_url" {
  value = "https://${google_compute_instance.default.network_interface[0].access_config[0].nat_ip}.sslip.io"
}

output "gitlab_internal_ip" {
  value = google_compute_instance.default.network_interface[0].network_ip
}

output "gitlab_secret_project" {
  value = var.project_id_kms
}

output "gitlab_secret_project_number" {
  value = var.project_number_kms
}

output "gitlab_instance_zone" {
  value = google_compute_instance.default.zone
}

output "gitlab_instance_name" {
  value = google_compute_instance.default.name
}

output "gitlab_service_directory" {
  value = google_service_directory_service.gitlab.id
}

output "gitlab_vm_sa" {
  value = google_service_account.gitlab_vm.email
}

output "gitlab_ssl_bucket_name" {
  value = module.ssl_cert.name
}
