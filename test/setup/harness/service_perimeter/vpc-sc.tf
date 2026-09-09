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
  prefix            = "secure_ci_cd"
  access_level_name = "alp_${local.prefix}_members_${random_string.random_access_level_suffix.result}"
  perimeter_name    = "sp_${local.prefix}_perimeter_${random_string.random_access_level_suffix.result}"
  access_level_members = concat(
    var.access_level_members,
    [
      "serviceAccount:${google_project_service_identity.container_service_agent.email}",
      "serviceAccount:${google_project_service_identity.cloudbuild_service_agent.email}",
      "serviceAccount:${google_project_service_identity.clouddeploy_service_agent.email}",
      "serviceAccount:${google_project_service_identity.artifact_registry_agent.email}",
    ]
  )
  supported_restricted_service = [
    "accessapproval.googleapis.com",
    "agentcommunication.googleapis.com",
    "addressvalidation.googleapis.com",
    "adsdatahub.googleapis.com",
    "aiplatform.googleapis.com",
    "alloydb.googleapis.com",
    "analyticshub.googleapis.com",
    "apigee.googleapis.com",
    "apigeeconnect.googleapis.com",
    "apihub.googleapis.com",
    "apikeys.googleapis.com",
    "apphub.googleapis.com",
    "artifactregistry.googleapis.com",
    "assuredoss.googleapis.com",
    "assuredworkloads.googleapis.com",
    "auditmanager.googleapis.com",
    "automl.googleapis.com",
    "autoscaling.googleapis.com",
    "backupdr.googleapis.com",
    "baremetalsolution.googleapis.com",
    "batch.googleapis.com",
    "beyondcorp.googleapis.com",
    "biglake.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigtable.googleapis.com",
    "binaryauthorization.googleapis.com",
    "blockchainnodeengine.googleapis.com",
    "certificatemanager.googleapis.com",
    "cloud.googleapis.com",
    "cloudaicompanion.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudcode.googleapis.com",
    "cloudcontrolspartner.googleapis.com",
    "clouddeploy.googleapis.com",
    "clouderrorreporting.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudprofiler.googleapis.com",
    "cloudquotas.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudsearch.googleapis.com",
    "cloudsecuritycompliance.googleapis.com",
    "cloudsupport.googleapis.com",
    "cloudtasks.googleapis.com",
    "cloudtrace.googleapis.com",
    "commerceorggovernance.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "confidentialcomputing.googleapis.com",
    "config.googleapis.com",
    "configdelivery.googleapis.com",
    "connectgateway.googleapis.com",
    "connectors.googleapis.com",
    "contactcenteraiplatform.googleapis.com",
    "contactcenterinsights.googleapis.com",
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerfilesystem.googleapis.com",
    "containerregistry.googleapis.com",
    "containersecurity.googleapis.com",
    "containerthreatdetection.googleapis.com",
    "contentwarehouse.googleapis.com",
    "databasecenter.googleapis.com",
    "databaseinsights.googleapis.com",
    "datacatalog.googleapis.com",
    "dataflow.googleapis.com",
    "dataform.googleapis.com",
    "datafusion.googleapis.com",
    "datalineage.googleapis.com",
    "datamigration.googleapis.com",
    "datapipelines.googleapis.com",
    "dataplex.googleapis.com",
    "dataproc.googleapis.com",
    "dataprocgdc.googleapis.com",
    "datastream.googleapis.com",
    "developerconnect.googleapis.com",
    "dialogflow.googleapis.com",
    "discoveryengine.googleapis.com",
    "dlp.googleapis.com",
    "dns.googleapis.com",
    "documentai.googleapis.com",
    "domains.googleapis.com",
    "earthengine.googleapis.com",
    "edgecontainer.googleapis.com",
    "edgenetwork.googleapis.com",
    "essentialcontacts.googleapis.com",
    "eventarc.googleapis.com",
    "eventarcpublishing.googleapis.com",
    "file.googleapis.com",
    "financialservices.googleapis.com",
    "firebaseappcheck.googleapis.com",
    "firebasecrashlytics.googleapis.com",
    "firebasedataconnect.googleapis.com",
    "firebaserules.googleapis.com",
    "firebasevertexai.googleapis.com",
    "firestore.googleapis.com",
    "gameservices.googleapis.com",
    "geocoding-backend.googleapis.com",
    "gkebackup.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "gkemulticloud.googleapis.com",
    "gkeonprem.googleapis.com",
    "healthcare.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "iap.googleapis.com",
    "iaptunnel.googleapis.com",
    "identitytoolkit.googleapis.com",
    "ids.googleapis.com",
    "integrations.googleapis.com",
    "kmsinventory.googleapis.com",
    "krmapihosting.googleapis.com",
    "kubernetesmetadata.googleapis.com",
    "language.googleapis.com",
    "licensemanager.googleapis.com",
    "lifesciences.googleapis.com",
    "livestream.googleapis.com",
    "logging.googleapis.com",
    "looker.googleapis.com",
    "managedidentities.googleapis.com",
    "managedkafka.googleapis.com",
    "memcache.googleapis.com",
    "memorystore.googleapis.com",
    "meshca.googleapis.com",
    "meshconfig.googleapis.com",
    "metastore.googleapis.com",
    "microservices.googleapis.com",
    "migrationcenter.googleapis.com",
    "ml.googleapis.com",
    "modelarmor.googleapis.com",
    "monitoring.googleapis.com",
    "netapp.googleapis.com",
    "networkconnectivity.googleapis.com",
    "networkmanagement.googleapis.com",
    "networksecurity.googleapis.com",
    "networkservices.googleapis.com",
    "notebooks.googleapis.com",
    "ondemandscanning.googleapis.com",
    "opsconfigmonitoring.googleapis.com",
    "orgpolicy.googleapis.com",
    "osconfig.googleapis.com",
    "oslogin.googleapis.com",
    "parallelstore.googleapis.com",
    "parametermanager.googleapis.com",
    "places.googleapis.com",
    "policysimulator.googleapis.com",
    "policytroubleshooter.googleapis.com",
    "privateca.googleapis.com",
    "privilegedaccessmanager.googleapis.com",
    "publicca.googleapis.com",
    "pubsub.googleapis.com",
    "pubsublite.googleapis.com",
    "rapidmigrationassessment.googleapis.com",
    "recaptchaenterprise.googleapis.com",
    "recommender.googleapis.com",
    "redis.googleapis.com",
    "retail.googleapis.com",
    "run.googleapis.com",
    "seclm.googleapis.com",
    "secretmanager.googleapis.com",
    "securesourcemanager.googleapis.com",
    "securetoken.googleapis.com",
    "securitycenter.googleapis.com",
    "securitycentermanagement.googleapis.com",
    "servicecontrol.googleapis.com",
    "servicedirectory.googleapis.com",
    "servicehealth.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "spanner.googleapis.com",
    "speakerid.googleapis.com",
    "speech.googleapis.com",
    "sqladmin.googleapis.com",
    "ssh-serialport.googleapis.com",
    "storage.googleapis.com",
    "storagebatchoperations.googleapis.com",
    "storageinsights.googleapis.com",
    "storagetransfer.googleapis.com",
    "sts.googleapis.com",
    "telemetry.googleapis.com",
    "texttospeech.googleapis.com",
    "timeseriesinsights.googleapis.com",
    "tpu.googleapis.com",
    "trafficdirector.googleapis.com",
    "transcoder.googleapis.com",
    "translate.googleapis.com",
    "videointelligence.googleapis.com",
    "videostitcher.googleapis.com",
    "vision.googleapis.com",
    "visionai.googleapis.com",
    "visualinspection.googleapis.com",
    "vmmigration.googleapis.com",
    "vmwareengine.googleapis.com",
    "vpcaccess.googleapis.com",
    "webrisk.googleapis.com",
    "websecurityscanner.googleapis.com",
    "workflows.googleapis.com",
    "workloadmanager.googleapis.com",
    "workstations.googleapis.com",
  ]

  egress_rules = [
    {
      title = "Egress to Logging bucket project"
      from = {
        identity_type = "ANY_IDENTITY"
        sources = {
          resources = ["projects/${data.google_project.project.number}"]
        }
      }
      to = {
        resources = [
          "projects/${data.google_project.project.number}" //logging bucket
        ]
        operations = {
          "storage.googleapis.com" = { methods = ["*"] }
        }
      }
    },
    {
      title = "Allow Services to ${var.project_id}"
      from = {
        identity_type = "ANY_IDENTITY"
        sources = {
          resources = [for i in var.protected_projects : "projects/${i}"]
        }
      }
      to = {
        resources = [
          "projects/${var.gitlab_project_number}" //worker pool project
        ]
        operations = {
          "servicedirectory.googleapis.com" = { methods = ["*"] }
          "cloudbuild.googleapis.com"       = { methods = ["*"] }
          "clouddeploy.googleapis.com"      = { methods = ["*"] }
          "pubsub.googleapis.com"           = { methods = ["*"] }
          "compute.googleapis.com"          = { methods = ["SubnetworksService.Get"] }
          "secretmanager.googleapis.com"    = { methods = ["*"] }
        }
      }
    }
  ]

  ingress_rules = [
    {
      title = "Ingress from Private Worker Pool Project to Single Project project"
      from = {
        sources    = { resources = ["projects/${var.gitlab_project_number}"] }
        identities = ["serviceAccount:service-${var.gitlab_project_number}@gs-project-accounts.iam.gserviceaccount.com", "serviceAccount:${var.gitlab_sa}"] //gitlab storage identity
      },
      to = {
        resources = ["projects/${var.logging_bucket_project_number}"], //logging-kms bucket
        operations = {
          "cloudkms.googleapis.com"      = { methods = ["*"] }
          "secretmanager.googleapis.com" = { methods = ["*"] }
        }
      }
    }
  ]
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service_identity" "cloudkms_service_account" {
  provider = google-beta
  project  = var.project_id
  service  = "cloudkms.googleapis.com"
}

resource "google_project_service_identity" "cloudbuild_service_agent" {
  provider = google-beta
  project  = var.project_id
  service  = "cloudbuild.googleapis.com"
}

resource "google_project_service_identity" "container_service_agent" {
  provider = google-beta
  project  = var.project_id
  service  = "container.googleapis.com"
}

resource "google_project_service_identity" "clouddeploy_service_agent" {
  provider = google-beta
  project  = var.project_id
  service  = "clouddeploy.googleapis.com"
}

resource "google_project_service_identity" "artifact_registry_agent" {
  provider = google-beta
  project  = var.project_id
  service  = "artifactregistry.googleapis.com"
}

resource "random_string" "random_access_level_suffix" {
  length  = 4
  lower   = true
  numeric = true
  upper   = false
  special = false
}

/******************************************
  Access Context Manager Policy
*******************************************/

resource "google_access_context_manager_access_policy" "access_policy" {
  parent     = "organizations/${var.org_id}"
  scopes     = [var.folder_id]
  title      = "Secure CI/CD policy for ${var.folder_id}"
  depends_on = [time_sleep.destroy_wait_propagation]
}

module "access_level_members" {
  source             = "terraform-google-modules/vpc-service-controls/google//modules/access_level"
  version            = "~> 8.0"
  description        = "${local.prefix} Access Level"
  policy             = google_access_context_manager_access_policy.access_policy.name
  name               = local.access_level_name
  members            = local.access_level_members
  combining_function = "OR"

  depends_on = [
    google_project_service_identity.cloudbuild_service_agent,
    google_project_service_identity.clouddeploy_service_agent,
    google_project_service_identity.cloudkms_service_account,
    google_project_service_identity.container_service_agent,
    google_project_service_identity.artifact_registry_agent,
    time_sleep.destroy_wait_propagation
  ]
}

module "regular_service_perimeter" {
  source                          = "terraform-google-modules/vpc-service-controls/google//modules/regular_service_perimeter"
  version                         = "~> 8.0"
  policy                          = google_access_context_manager_access_policy.access_policy.name
  perimeter_name                  = local.perimeter_name
  resources                       = var.service_perimeter_mode == "ENFORCE" ? [data.google_project.project.number] : []
  resources_dry_run               = [data.google_project.project.number]
  description                     = "Serverless VPC Service Controls perimeter"
  access_levels                   = var.service_perimeter_mode == "ENFORCE" ? [module.access_level_members.name] : []
  access_levels_dry_run           = [module.access_level_members.name]
  egress_policies                 = var.service_perimeter_mode == "ENFORCE" ? local.egress_rules : []
  egress_policies_dry_run         = local.egress_rules
  ingress_policies                = var.service_perimeter_mode == "ENFORCE" ? local.ingress_rules : []
  ingress_policies_dry_run        = local.ingress_rules
  vpc_accessible_services         = var.service_perimeter_mode == "ENFORCE" ? ["*"] : []
  vpc_accessible_services_dry_run = ["*"]
  restricted_services_dry_run     = local.supported_restricted_service
  restricted_services             = var.service_perimeter_mode == "ENFORCE" ? local.supported_restricted_service : []
  depends_on                      = [time_sleep.destroy_wait_propagation]
}

resource "time_sleep" "wait_vpc_sc_propagation" {
  depends_on = [
    google_access_context_manager_access_policy.access_policy,
    module.access_level_members,
    module.regular_service_perimeter
  ]
  destroy_duration = "5m"
  create_duration  = "2m"
}

resource "time_sleep" "destroy_wait_propagation" {
  destroy_duration = "5m"
}
