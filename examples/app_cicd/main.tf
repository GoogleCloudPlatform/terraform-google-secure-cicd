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

data "google_project" "app_cicd_project" {
  project_id = var.project_id
}

locals {
    deploy_branch_clusters = {
    prod = {
      cluster      = "prod-cluster",
      project_id   = var.project_id,
      location     = "us-central1",
      attestations = ["projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/quality-attestor", "projects/${var.project_id}/attestors/build-attestor"]
    },
    qa = {
      cluster      = "qa-cluster",
      project_id   = var.project_id,
      location     = "us-central1",
      attestations = ["projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]

    }
    dev = {
      cluster      = "dev-cluster",
      project_id   = "boa-dev-2",
      location     = "us-central1",
      attestations = ["projects/${var.project_id}/attestors/security-attestor"]
    },
  }
}
module "ci_pipeline" {
  source                  = "../../modules/secure-ci"
  project_id              = var.project_id
  app_source_repo         = "app-source"
  manifest_dry_repo       = "app-dry-manifests"
  manifest_wet_repo       = "app-wet-manifests"
  gar_repo_name_suffix    = "app-image-repo"
  primary_location        = "us-central1"
  attestor_names_prefix   = ["build", "quality", "security"]
  app_build_trigger_yaml  = "cloudbuild-ci.yaml"
  runner_build_folder     = "../../../examples/app_cicd/cloud-build-builder"
  build_image_config_yaml = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name     = ".*"

  additional_substitutions = {
    _FAVORITE_COLOR = "blue"
  }
}

module "cd_pipeline" {
  source                  = "../../modules/secure-cd"
  project_id              = var.project_id
  primary_location        = "us-central1"

  gar_repo_name           = module.ci_pipeline.app_artifact_repo
  manifest_wet_repo       = "app-wet-manifests" 
  deploy_branch_clusters  = local.deploy_branch_clusters
  app_deploy_trigger_yaml = "cloudbuild-cd.yaml"


  additional_substitutions = {
    _FAVORITE_COLOR = "blue"
  }
}

/////////////////
/// GKE + VPC ///
/////////////////

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# module "gke" {
#   source                      = "terraform-google-modules/kubernetes-engine/google"
#   project_id                  = local.deploy_branch_clusters["dev"].project_id
#   name                        = local.deploy_branch_clusters["dev"].cluster
#   regional                    = true
#   region                      = local.deploy_branch_clusters["dev"].location
#   network                     = module.vpc.network_name
#   subnetwork                  = "subnet-dev"
#   ip_range_pods               = "subnet-dev-pods"
#   ip_range_services           = "subnet-dev-svcs"
#   create_service_account      = false
#   service_account             = "${data.google_project.app_cicd_project.number}-compute@developer.gserviceaccount.com"
#   enable_binary_authorization = true
#   skip_provisioners           = false
#   cluster_autoscaling = {
#     "enabled": true,
#     "gpu_resources": [],
#     "max_cpu_cores": 32,
#     "max_memory_gb": 64,
#     "min_cpu_cores": 0,
#     "min_memory_gb": 0
#   }
# }

# module "vpc" {
#   source       = "terraform-google-modules/network/google"
#   project_id   = var.project_id 
#   network_name = "gke-vpc"

#   subnets = [
#     {
#       subnet_name   = "subnet-dev"
#       subnet_ip     = "10.10.0.0/20"
#       subnet_region = "us-central1"
#     },
#     {
#       subnet_name   = "subnet-qa"
#       subnet_ip     = "10.20.0.0/20"
#       subnet_region = "us-central1"
#     },
#     {
#       subnet_name   = "subnet-prod"
#       subnet_ip     = "10.30.0.0/20"
#       subnet_region = "us-central1"
#     },
#   ]

#   secondary_ranges = {
#     subnet-dev = [
#       {
#         range_name    = "subnet-dev-pods"
#         ip_cidr_range = "10.100.0.0/14"
#       },
#       {
#         range_name    = "subnet-dev-svcs"
#         ip_cidr_range = "10.120.0.0/14"
#       }
#     ]

#   }
# }