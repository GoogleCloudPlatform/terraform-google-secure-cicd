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

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name              = "ci-secure-cicd"
  random_project_id = "true"
  org_id            = var.org_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "clouddeploy.googleapis.com",
    "storage-api.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "sourcerepo.googleapis.com",
    "artifactregistry.googleapis.com",
    "containeranalysis.googleapis.com",
    "cloudkms.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containerscanning.googleapis.com",
    "servicenetworking.googleapis.com",
    "pubsub.googleapis.com",
  ]
  activate_api_identities = [
    {
      api = "cloudbuild.googleapis.com"
      roles = [
        "roles/storage.admin",
        "roles/artifactregistry.admin",
        "roles/cloudbuild.builds.builder",
        "roles/binaryauthorization.attestorsVerifier",
        "roles/cloudkms.cryptoOperator",
        "roles/containeranalysis.notes.attacher",
        "roles/containeranalysis.notes.occurrences.viewer",
        "roles/source.writer",
      ]
    },
  ]
}

locals {
  envs             = ["dev", "qa", "prod"]
  primary_location = "us-central1"
  ip_increment = {
    "dev"  = 1,
    "qa"   = 2,
    "prod" = 3
  }
}

# GKE Projects
module "gke_project" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/project-factory/google"
  version  = "~> 18.0"

  name                    = "secure-cicd-gke-${each.value}"
  random_project_id       = "true"
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "keep"

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "storage-api.googleapis.com",
    "serviceusage.googleapis.com",
    "containerregistry.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "containeranalysis.googleapis.com",
    "cloudkms.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containerscanning.googleapis.com",
    "container.googleapis.com",
    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
}

###### Public Clusters #####
# VPCs
module "vpc" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/network/google"
  version  = "~> 7.0"

  project_id   = module.gke_project[each.value].project_id
  network_name = "gke-vpc-${each.key}"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name   = "gke-subnet"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = local.primary_location
    },
  ]
  secondary_ranges = {
    gke-subnet = [
      {
        range_name    = "us-central1-01-gke-01-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "us-central1-01-gke-01-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

module "gke_cluster" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/kubernetes-engine/google"
  version  = "~> 25.0"


  project_id                  = module.gke_project[each.value].project_id
  name                        = "${each.key}-cluster"
  regional                    = true
  region                      = local.primary_location
  zones                       = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                     = module.vpc[each.key].network_name
  subnetwork                  = module.vpc[each.key].subnets_names[0]
  ip_range_pods               = "us-central1-01-gke-01-pods"
  ip_range_services           = "us-central1-01-gke-01-services"
  create_service_account      = true
  enable_binary_authorization = true
  skip_provisioners           = false

  release_channel    = "REGULAR"
  kubernetes_version = "latest"

  depends_on = [
    module.vpc
  ]
}


###### Private Clusters ######
# Private Cluster VPCs
module "vpc_private_cluster" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/network/google"
  version  = "~> 7.0"

  project_id   = module.gke_project[each.value].project_id
  network_name = "gke-private-vpc-${each.value}"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name   = "gke-subnet-private"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = local.primary_location
    },
  ]
  secondary_ranges = {
    gke-subnet-private = [
      {
        range_name    = "us-central1-01-gke-01-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "us-central1-01-gke-01-services"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

resource "google_compute_network_peering_routes_config" "gke_peering_routes_config" {
  for_each = toset(local.envs)

  project = module.gke_project[each.value].project_id
  peering = module.gke_private_cluster[each.value].peering_name
  network = module.vpc_private_cluster[each.value].network_name

  import_custom_routes = true
  export_custom_routes = true
}

module "gke_private_cluster" {
  for_each = toset(local.envs)
  source   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version  = "~> 25.0"

  project_id                  = module.gke_project[each.value].project_id
  name                        = "${each.value}-private-cluster"
  regional                    = true
  region                      = local.primary_location
  zones                       = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                     = module.vpc_private_cluster[each.value].network_name
  subnetwork                  = module.vpc_private_cluster[each.value].subnets_names[0]
  ip_range_pods               = "us-central1-01-gke-01-pods"
  ip_range_services           = "us-central1-01-gke-01-services"
  horizontal_pod_autoscaling  = true
  create_service_account      = true
  enable_binary_authorization = true

  release_channel    = "REGULAR"
  kubernetes_version = "latest"

  enable_private_endpoint = true
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.16.${local.ip_increment[each.value]}.0/28"

  enable_vertical_pod_autoscaling = true

  master_authorized_networks = [
    {
      cidr_block   = module.vpc_private_cluster[each.value].subnets_ips[0]
      display_name = "VPC"
    },
    {
      cidr_block   = "10.39.0.0/16"
      display_name = "CLOUDBUILD"
    }
  ]

  depends_on = [
    module.vpc_private_cluster
  ]
}

# Single Project example
module "project_standalone" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = "secure-cicd-singleproj"
  random_project_id       = "true"
  org_id                  = var.org_id
  folder_id               = var.folder_id
  billing_account         = var.billing_account
  default_service_account = "keep"

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "clouddeploy.googleapis.com",
    "storage-api.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbuild.googleapis.com",
    "iamcredentials.googleapis.com",
    "sourcerepo.googleapis.com",
    "artifactregistry.googleapis.com",
    "containeranalysis.googleapis.com",
    "cloudkms.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containerscanning.googleapis.com",
    "servicenetworking.googleapis.com",
    "pubsub.googleapis.com",
    "container.googleapis.com",
    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "compute.googleapis.com",
    "gkehub.googleapis.com",
    "connectgateway.googleapis.com",
  ]
  activate_api_identities = [
    {
      api = "cloudbuild.googleapis.com"
      roles = [
        "roles/storage.admin",
        "roles/artifactregistry.admin",
        "roles/cloudbuild.builds.builder",
        "roles/binaryauthorization.attestorsVerifier",
        "roles/cloudkms.cryptoOperator",
        "roles/containeranalysis.notes.attacher",
        "roles/containeranalysis.notes.occurrences.viewer",
        "roles/source.writer",
      ]
    },
  ]
}
