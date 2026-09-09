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
  gitlab_network_id_without_location = replace(var.network_id, "locations/", "")
  gitlab_network_url                 = "https://www.googleapis.com/compute/v1/projects/${var.project_id_workerpool}/global/networks/${var.network_name}"
  gitlab_vm_ip_range                 = "10.2.2.0/24"
}

data "google_project" "gitlab_project" {
  project_id = var.project_id_workerpool
}

data "google_storage_project_service_account" "gitlab_gcs_account" {
  project = var.project_id_workerpool
}

resource "google_project_iam_member" "allow_gitlab_bucket_download" {
  project = var.project_id_workerpool
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${var.cloud_build_sa}"
}

resource "google_project_iam_member" "allow_gitlab_iam_policy_edit" {
  project = var.project_id_workerpool
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${var.cloud_build_sa}"
}

resource "google_service_account" "gitlab_vm" {
  account_id   = "gitlab-vm-sa"
  project      = var.project_id_workerpool
  display_name = "Custom SA for VM Instance"
}

resource "google_project_iam_member" "secret_manager_admin_vm_instance" {
  for_each = toset([
    var.project_id_kms,
    var.project_id_workerpool
  ])
  project = each.value
  role    = "roles/secretmanager.admin"
  member  = google_service_account.gitlab_vm.member
}

resource "google_service_account_iam_member" "impersonate" {
  service_account_id = google_service_account.gitlab_vm.id
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.cloud_build_sa}"
}

resource "google_project_iam_member" "int_test_gitlab_permissions" {
  for_each = toset([
    var.project_id_kms,
    var.project_id_workerpool
  ])
  project = var.project_id_kms
  role    = "roles/compute.instanceAdmin"
  member  = "serviceAccount:${var.cloud_build_sa}"
}

resource "google_kms_crypto_key_iam_member" "logging_crypto_encrypt_key" {
  for_each      = { "gcs_account" : data.google_storage_project_service_account.gitlab_gcs_account.member, "gitlab_sa" : google_service_account.gitlab_vm.member }
  crypto_key_id = var.logging_kms_crypto_id
  role          = "roles/cloudkms.cryptoKeyEncrypter"
  member        = each.value
}

resource "google_kms_crypto_key_iam_member" "attestation_crypto_encrypt_key" {
  for_each      = { "gcs_account" : data.google_storage_project_service_account.gitlab_gcs_account.member, "gitlab_sa" : google_service_account.gitlab_vm.member }
  crypto_key_id = var.attestation_kms_crypto_id
  role          = "roles/cloudkms.cryptoKeyEncrypter"
  member        = each.value
}

resource "google_kms_crypto_key_iam_member" "logging_crypto_decrypt_key" {
  for_each      = { "gcs_account" : data.google_storage_project_service_account.gitlab_gcs_account.member, "gitlab_sa" : google_service_account.gitlab_vm.member }
  crypto_key_id = var.logging_kms_crypto_id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = each.value
}

resource "google_kms_crypto_key_iam_member" "attestation_crypto_decrypt_key" {
  for_each      = { "gcs_account" : data.google_storage_project_service_account.gitlab_gcs_account.member, "gitlab_sa" : google_service_account.gitlab_vm.member }
  crypto_key_id = var.attestation_kms_crypto_id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = each.value
}

resource "google_storage_bucket_iam_member" "logging_storage_admin" {
  for_each = { "gcs_account" : data.google_storage_project_service_account.gitlab_gcs_account.member, "gitlab_sa" : google_service_account.gitlab_vm.member }
  bucket   = var.logging_bucket_name
  role     = "roles/storage.admin"
  member   = each.value
}

resource "time_sleep" "waits_iam_propagation" {
  create_duration = "2m"
  depends_on = [
    google_storage_bucket_iam_member.logging_storage_admin,
    google_kms_crypto_key_iam_member.attestation_crypto_encrypt_key,
    google_kms_crypto_key_iam_member.attestation_crypto_decrypt_key,
    google_kms_crypto_key_iam_member.logging_crypto_encrypt_key,
    google_kms_crypto_key_iam_member.logging_crypto_decrypt_key,
    google_project_iam_member.secret_manager_admin_vm_instance,
    google_project_iam_member.int_test_gitlab_permissions,
  ]
}

resource "google_compute_instance" "default" {
  name         = "gitlab-vm"
  project      = var.project_id_workerpool
  machine_type = "n2-standard-4"
  zone         = "us-central1-a"

  tags = ["git-vm", "direct-gateway-access"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = var.network_name
    access_config {
      // Ephemeral public IP
    }
    subnetwork         = google_compute_subnetwork.gitlab_subnet.name
    subnetwork_project = var.project_id_workerpool
  }

  metadata = {
    secrets_project_id = var.project_id_kms
  }

  metadata_startup_script = file("./../../scripts/gitlab_self_hosted.sh")

  service_account {
    email  = google_service_account.gitlab_vm.email
    scopes = ["cloud-platform"]
  }
  depends_on = [time_sleep.waits_iam_propagation]
}

resource "google_compute_subnetwork" "gitlab_subnet" {
  project       = var.project_id_workerpool
  name          = "gitlab-vm-subnet"
  ip_cidr_range = "10.2.2.0/24"

  region  = "us-central1"
  network = var.network_id
}

resource "google_secret_manager_secret" "gitlab_webhook" {
  project   = var.project_id_kms
  secret_id = "gitlab-webhook"
  replication {
    auto {}
  }
}

resource "random_uuid" "random_webhook_secret" {
}

resource "google_secret_manager_secret_version" "gitlab_webhook" {
  secret      = google_secret_manager_secret.gitlab_webhook.id
  secret_data = random_uuid.random_webhook_secret.result
}

// ================================
//          FIREWALL RULES
// ================================

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = var.network_name
  project = var.project_id_workerpool

  allow {
    ports    = [22]
    protocol = "tcp"
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "allow_service_networking" {
  name    = "allow-service-networking"
  network = var.network_name
  project = var.project_id_workerpool

  allow {
    protocol = "all"
  }

  source_ranges = ["35.199.192.0/19"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = var.network_name
  project = var.project_id_workerpool

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["git-vm"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = var.network_name
  project = var.project_id_workerpool

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["git-vm"]
}

// =======================================================
//          GITLAB WORKER POOL AND PRIVATE DNS CONFIG
// =======================================================
module "ssl_cert" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 10.0"

  name              = "${var.project_id_workerpool}-ssl-cert"
  project_id        = var.project_id_workerpool
  location          = "us-central1"
  log_bucket        = var.logging_bucket_name
  log_object_prefix = "ssl-cert"
  force_destroy     = true

  versioning = true
  encryption = { default_kms_key_name = var.logging_kms_crypto_id }

  # Module does not support values not know before apply (member and role are used to create the index in for_each)
  # https://github.com/terraform-google-modules/terraform-google-cloud-storage/blob/v10.0.2/modules/simple_bucket/main.tf#L122
  # iam_members = [{
  #   role   = "roles/storage.admin"
  #   member = "${google_service_account.gitlab_vm.member}"
  # }]

  depends_on = [time_sleep.waits_iam_propagation]
}

resource "google_storage_bucket_iam_member" "ssl_storage_admin" {
  bucket = module.ssl_cert.name
  role   = "roles/storage.admin"
  member = google_service_account.gitlab_vm.member
}

resource "google_service_directory_namespace" "gitlab" {
  provider     = google-beta
  namespace_id = "gitlab-namespace"
  location     = "us-central1"
  project      = var.project_id_workerpool
}

resource "google_service_directory_service" "gitlab" {
  provider   = google-beta
  service_id = "gitlab"
  namespace  = google_service_directory_namespace.gitlab.id
}

resource "google_service_directory_endpoint" "gitlab" {
  provider    = google-beta
  endpoint_id = "endpoint"
  service     = google_service_directory_service.gitlab.id

  network = var.network_id
  address = google_compute_instance.default.network_interface[0].network_ip
  port    = 443
}

resource "google_dns_managed_zone" "sd_zone" {
  provider = google-beta

  name        = "peering-zone"
  dns_name    = "example.com."
  description = "Example private DNS Service Directory zone for Gitlab Instance"
  project     = var.project_id_workerpool

  visibility = "private"

  service_directory_config {
    namespace {
      namespace_url = google_service_directory_namespace.gitlab.id
    }
  }

  private_visibility_config {
    networks {
      network_url = local.gitlab_network_url
    }
  }
}

resource "google_project_iam_member" "cloudbuild_workerpool_permissions" {
  for_each = toset([
    "roles/servicedirectory.viewer",
    "roles/servicedirectory.pscAuthorizedService",
    "roles/cloudbuild.workerPoolUser"
  ])
  project = var.project_id_workerpool
  role    = each.key
  member  = "serviceAccount:service-${var.project_number_kms}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cb_sa_pool_user" {
  project = var.project_id_workerpool
  role    = "roles/cloudbuild.workerPoolUser"
  member  = "serviceAccount:${var.project_number_kms}@cloudbuild.gserviceaccount.com"
}

resource "google_service_networking_peered_dns_domain" "name" {
  project    = var.project_id_workerpool
  name       = "example-com"
  network    = var.network_name
  dns_suffix = "example.com."

  depends_on = [
    google_dns_managed_zone.sd_zone,
  ]
}


