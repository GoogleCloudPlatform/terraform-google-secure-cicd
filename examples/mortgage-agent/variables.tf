# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_number" {
  description = "The numeric identifier (e.g., 123456789012) of the Google Cloud project."
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "gateway"
}

variable "org_id" {
  description = "GCP organization ID (numeric). Required for Agent Identity IAM bindings."
  type        = string
  default     = null
}

variable "terraform_service_account" {
  description = "The email address of the service account that will run the Terraform code granted roles: discoveryengine.admin always; modelarmor.admin and modelarmor.floorSettingsAdmin when enable_model_armor; aiplatform.user (e.g. [\"serviceAccount:your_user@example.com\"])"
  type        = string
}

variable "enabled_services" {
  description = "List of Google Cloud APIs to enable"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "dns.googleapis.com",
    "containerregistry.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudprofiler.googleapis.com",
    "servicenetworking.googleapis.com",
    "networkmanagement.googleapis.com",
    "networkservices.googleapis.com",
    "modelarmor.googleapis.com",
    "networksecurity.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudkms.googleapis.com",
    "binaryauthorization.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "autoscaling.googleapis.com",
    "cloudbuild.googleapis.com",
    "certificatemanager.googleapis.com",
    "cloudquotas.googleapis.com",
    "aiplatform.googleapis.com",
    "dlp.googleapis.com",
    "telemetry.googleapis.com",
    "apphub.googleapis.com",
    "agentregistry.googleapis.com",
    "cloudkms.googleapis.com",
  ]
}

variable "kms_prevent_destroy" {
  description = "If set to true, delete KMS keyring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present."
  type        = bool
  default     = true
}

variable "bucket_force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects."
  type        = bool
  default     = false
}

variable "encrypt_gcs_bucket_tfstate" {
  description = "Encrypt the bucket used for storing Terraform state files in the seed project."
  type        = bool
  default     = true
}

variable "enable_logs_sink" {
  description = "Enable log sink resources in the observability module."
  type        = bool
  default     = false
}

# ==============================================================================
# NETWORKING
# ==============================================================================
variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gateway-vpc"
}

variable "subnet_name" {
  description = "Name of the primary subnet"
  type        = string
  default     = "mcp-subnet-us-central1"
}

variable "primary_subnet_cidr" {
  description = "CIDR range for the primary subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "proxy_subnet_cidr" {
  description = "CIDR range for the proxy-only subnet"
  type        = string
  default     = "10.9.0.0/24"
}

variable "psc_subnet_cidr" {
  description = "CIDR range for the Private Service Connect subnet"
  type        = string
  default     = "10.10.0.0/24"
}

# ==============================================================================
# DNS
# ==============================================================================
variable "dns_zone_domain" {
  description = "The domain name for the public DNS zone (must end with a dot, e.g., 'example.com.'). Certificate Manager validates the MCP LB cert against this zone."
  type        = string
  default     = null
}

variable "dns_zone_name" {
  description = "The name of the existing Cloud DNS managed zone. If not provided, derived from dns_zone_domain."
  type        = string
  default     = null
}

variable "mcp_ssl_certificate_id" {
  description = <<-EOT
    Optional existing Certificate Manager regional certificate ID to attach to
    the MCP internal HTTPS LB (same project and region as the LB).

    Leave null/empty to issue a Google-managed cert via DNS-01 against
    dns_zone_domain (requires a delegated public Cloud DNS zone and
    dns_zone_name). When set, issuance and DNS-01 records are skipped.

    Format:
      projects/<project>/locations/<region>/certificates/<name>

    In both modes the cert must be a public CA and cover mcp.<dns_zone_domain>
    and *.mcp.<dns_zone_domain>. dns_zone_domain is always required so private
    MCP hostnames match those SANs.
  EOT
  type        = string
  default     = null
}

# ==============================================================================
# MCP SERVICES (CLOUD RUN)
# ==============================================================================
variable "mcp_internal_dns_zone" {
  description = <<-EOT
    Private DNS zone hosting <service>.<domain> A records for the MCP Cloud Run
    services. Attached to the VPC so workloads (and Agent Engine via DNS
    peering) resolve internally.

    `domain` MUST be a real subdomain (typically "mcp.<dns_zone_domain>") so
    Certificate Manager can issue a Google-managed regional cert that the
    Agent Gateway will validate.
  EOT
  type = object({
    name   = optional(string, "mcp-server-internal")
    domain = string
  })
  default = null
  validation {
    condition     = var.mcp_internal_dns_zone == null || endswith(var.mcp_internal_dns_zone.domain, ".")
    error_message = "mcp_internal_dns_zone.domain must end with a trailing dot (e.g. \"mcp.example.com.\")."
  }
}

variable "mcp_services" {
  description = "Map of MCP service name to deployment configuration. The map key becomes the Cloud Run service name AND the URL-mask token (e.g. legacy-dms.<mcp_internal_dns_zone.domain> -> Cloud Run service 'legacy-dms')."
  type = map(object({
    image = string
    ci_repository = object({
      repository_name = string
      repository_url  = string
    })
    cd_repository = object({
      repository_name = string
      repository_url  = string
    })
    container_port     = optional(number, 8080)
    otel_service_name  = optional(string)
    min_instance_count = optional(number, 0)
    max_instance_count = optional(number, 3)
    cpu                = optional(string, "1")
    memory             = optional(string, "512Mi")
    env                = optional(map(string), {})
  }))
  default = {}
}

variable "mcp_tool_specs" {
  description = "Map of MCP service name -> path to its toolspec.json (relative to the terraform/ directory or absolute). Required for every key in var.mcp_services; the toolspec is uploaded into the Agent Registry entry as the MCP server spec. Note: the var.mcp_services key (which becomes the Agent Registry service ID and the LB hostname) does not need to match the source directory name (e.g. income-verification -> ../src/income-verification-api/toolspec.json)."
  type        = map(string)
  default     = {}
}

variable "mcp_lb_protocol" {
  description = <<-EOT
    Front-end protocol for the MCP internal Application LB. With HTTPS, the LB
    serves a Google-managed regional cert for *.mcp.<dns_zone_domain>; otherwise
    it falls back to an auto-generated self-signed cert for *.<mcp_internal_dns_zone.domain>
    (note: not validatable by Agent Gateway today).
  EOT
  type        = string
  default     = "HTTPS"
  validation {
    condition     = contains(["HTTPS"], var.mcp_lb_protocol)
    error_message = "mcp_lb_protocol must be HTTPS."
  }
}

# ==============================================================================
# MODEL ARMOR
# ==============================================================================
variable "enable_model_armor" {
  description = "Enable Model Armor template and IAM bindings"
  type        = bool
  default     = false
}

variable "model_armor_request_template_id" {
  description = "ID for the request-side Model Armor template (RAI + PI/jailbreak; no SDP). Wired into the Agent Gateway CONTENT_AUTHZ extension as request_template_id."
  type        = string
  default     = "agw-request-template"
}

variable "model_armor_response_template_id" {
  description = "ID for the response-side Model Armor template (RAI; SDP advanced_config when model_armor_sdp_enforcement = ENABLED). Wired into the Agent Gateway CONTENT_AUTHZ extension as response_template_id."
  type        = string
  default     = "agw-response-template"
}

variable "model_armor_rai_filters" {
  description = "RAI (Responsible AI) filter configurations. filter_type can be: SEXUALLY_EXPLICIT, HATE_SPEECH, HARASSMENT, DANGEROUS. confidence_level can be: LOW_AND_ABOVE, MEDIUM_AND_ABOVE, HIGH"
  type = list(object({
    filter_type      = string
    confidence_level = string
  }))
  default = [
    {
      filter_type      = "HATE_SPEECH"
      confidence_level = "MEDIUM_AND_ABOVE"
    },
    {
      filter_type      = "HARASSMENT"
      confidence_level = "MEDIUM_AND_ABOVE"
    },
    {
      filter_type      = "SEXUALLY_EXPLICIT"
      confidence_level = "MEDIUM_AND_ABOVE"
    }
  ]
}

variable "model_armor_sdp_enforcement" {
  description = "Sensitive Data Protection filter enforcement setting (ENABLED or DISABLED)"
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.model_armor_sdp_enforcement)
    error_message = "model_armor_sdp_enforcement must be ENABLED or DISABLED"
  }
}

variable "model_armor_pii_types" {
  description = "Info types whose findings the response Model Armor template's deidentify transformation replaces with the type-name placeholder. Model Armor's SDP filter still runs Google's built-in detectors (including PERSON_NAME) regardless of this list, but only findings whose info type appears here are transformed — anything else is passed through to the agent unchanged. Keep identity fields the agent needs for downstream reasoning (e.g. PERSON_NAME) OUT of this list."
  type        = list(string)
  default = [
    "US_SOCIAL_SECURITY_NUMBER",
    "CREDIT_CARD_NUMBER",
    "PHONE_NUMBER",
    "EMAIL_ADDRESS",
    "PASSPORT",
    "DATE_OF_BIRTH",
    "MEDICAL_RECORD_NUMBER",
    "IP_ADDRESS",
    "STREET_ADDRESS",
  ]
}

variable "model_armor_pi_jailbreak_enforcement" {
  description = "PI and jailbreak filter enforcement setting (ENABLED or DISABLED)"
  type        = string
  default     = "ENABLED"
}

variable "model_armor_pi_jailbreak_confidence" {
  description = "PI and jailbreak filter confidence level (LOW_AND_ABOVE, MEDIUM_AND_ABOVE, or HIGH)"
  type        = string
  default     = "LOW_AND_ABOVE"
  validation {
    condition     = contains(["LOW_AND_ABOVE", "MEDIUM_AND_ABOVE", "HIGH"], var.model_armor_pi_jailbreak_confidence)
    error_message = "model_armor_pi_jailbreak_confidence must be one of: LOW_AND_ABOVE, MEDIUM_AND_ABOVE, HIGH"
  }
}

variable "model_armor_malicious_uri_enforcement" {
  description = "Malicious URI filter enforcement setting (ENABLED or DISABLED)"
  type        = string
  default     = "ENABLED"
}

variable "enable_model_armor_mcp_floor_setting" {
  description = "Enable Model Armor floor setting for MCP server protection (BigQuery MCP)"
  type        = bool
  default     = true
}

variable "enable_model_armor_vertex_ai" {
  description = "Enable Model Armor integration with Vertex AI (floor setting + IAM)"
  type        = bool
  default     = false
}

variable "model_armor_vertex_ai_inspect_only" {
  description = "When true, Vertex AI uses INSPECT_ONLY mode; when false, uses INSPECT_AND_BLOCK"
  type        = bool
  default     = false
}

variable "model_armor_vertex_ai_cloud_logging" {
  description = "Enable Cloud Logging for Vertex AI Model Armor sanitization"
  type        = bool
  default     = true
}

# ==============================================================================
# PSC INTERFACE
# ==============================================================================
variable "psc_interface_subnet_cidr" {
  description = "CIDR for the PSC Interface subnet (min /28, must not overlap with psc_subnet_cidr)"
  type        = string
  default     = "10.11.0.0/28"
}

# ==============================================================================
# AGENT GATEWAY
# ==============================================================================
variable "agent_gateway_name" {
  description = "Name of the Agent Gateway resource (and prefix for its network attachment, authz extensions, and authz policies)"
  type        = string
  default     = "agent-gateway"
}

variable "agent_gateway_subnet_cidr" {
  description = "CIDR for the Agent Gateway dedicated subnet. Min /28, RFC1918, must not overlap 10.0.0.0/24, 10.0.1.0/24, or 10.0.2.0/24 (Agent Gateway egress restrictions)."
  type        = string
  default     = "10.20.0.0/28"
}

variable "agent_gateway_authz_fail_open" {
  description = "If true, allow traffic through the Agent Gateway when an authz extension call fails. Set false in production."
  type        = bool
  default     = true
}

variable "agent_gateway_iap_iam_enforcement_mode" {
  description = "Set to \"DRY_RUN\" to put the Agent Gateway IAP authz extension into dry-run mode (IAM allow policies evaluated and logged but not blocking). Leave null (the default) to omit the metadata key, which matches the IAP default of enforcing."
  type        = string
  default     = null
  validation {
    condition     = var.agent_gateway_iap_iam_enforcement_mode == null || var.agent_gateway_iap_iam_enforcement_mode == "DRY_RUN"
    error_message = "agent_gateway_iap_iam_enforcement_mode must be null or \"DRY_RUN\"."
  }
}

variable "agent_gateway_dns_peering_config" {
  description = "Optional DNS peering for the Agent Gateway. Lets the gateway resolve the listed `domains` (each must end with a dot) against the target VPC's private Cloud DNS zones — required for the gateway to reach upstream MCP servers by hostname (e.g. `mcp.agent-gateway.sc-ccn.xyz.` records that point at the MCP internal LB). `target_project` defaults to `var.project_id` and `target_network` defaults to the self-link of the VPC this module creates; override only when peering against a VPC in a different project or network. Applied natively via `network_config.dns_peering_config` on the Agent Gateway resource."
  type = object({
    domains        = list(string)
    target_project = optional(string)
    target_network = optional(string)
  })
  default  = null
  nullable = true
}

# ==============================================================================
# AGENT REGISTRY ENDPOINT
# ==============================================================================
variable "agent_registry_google_apis" {
  description = "Map of Google API IDs to their display names to register in Agent Registry"
  type        = map(string)
  default = {
    aiplatform             = "Vertex AI Platform"
    cloudresourcemanager   = "Cloud Resource Manager"
    global-discoveryengine = "Global Discovery Engine"
    discoveryengine        = "Discovery Engine"
    logging                = "Logging"
    monitoring             = "Monitoring"
    oauth2                 = "OAuth2"
    telemetry              = "Telemetry"
    trace                  = "Trace"
    agentregistry          = "Agent Registry"
    iap                    = "Identity-Aware Proxy"
  }
}

variable "agent_registry_custom_services" {
  description = "List of custom services to register in Agent Registry"
  type = list(object({
    id           = string
    display_name = string
    url          = string
    description  = optional(string)
  }))
  default = [
    {
      id           = "github"
      display_name = "Github"
      url          = "https://github.com"
    }
  ]
}

variable "repository_type" {
  description = "The type of the repository. Must be one of 'GITHUB', 'GITLAB', or 'CSR'."
  type        = string
  default     = "GITHUB"
  validation {
    condition = (
      var.repository_type != "GITHUB" ||
      (var.github_auth != null && var.gitlab_auth == null)
    )
    error_message = "When repository_type is 'GITHUB', the 'github_auth' variable must be set, and 'gitlab_auth' must not be set."
  }
  validation {
    condition = (
      var.repository_type != "GITLAB" ||
      (var.gitlab_auth != null && var.github_auth == null)
    )
    error_message = "When repository_type is 'GITLAB', the 'gitlab_auth' variable must be set, and 'github_auth' must not be set."
  }
  validation {
    condition = (
      var.repository_type != "CSR" ||
      (var.github_auth == null && var.gitlab_auth == null)
    )
    error_message = "When repository_type is 'CSR', neither 'github_auth' nor 'gitlab_auth' should be set."
  }
}

variable "app_build_trigger_yaml" {
  type        = string
  description = "Name of application cloudbuild yaml file for the CI pipeline."
  default     = "cloudbuild-ci.yaml"
}

variable "app_deploy_trigger_yaml" {
  type        = string
  description = "Name of application cloudbuild yaml file for the CD pipeline."
  default     = "cloudbuild-cd.yaml"
}

variable "github_auth" {
  type = object({
    secret_id         = string
    app_id_secret_id  = string
    secret_project_id = string
  })
  description = "Authentication configuration for GitHub. Required only if repo_type is 'GITHUBv2'."
  default     = null
}

variable "gitlab_auth" {
  type = object({
    read_authorizer_credential_secret_id = string
    authorizer_credential_secret_id      = string
    webhook_secret_id                    = string
    enterprise_host_uri                  = optional(string)
    enterprise_service_directory         = optional(string)
    enterprise_ca_certificate            = optional(string)
    secret_project_id                    = string
  })
  description = "Authentication configuration for GitLab. Required only if repo_type is 'GITLABv2'."
  default     = null
}

variable "cloudbuild_private_pool_machine_type" {
  type        = string
  description = "Machine type for Cloud Build private pool"
  default     = "e2-medium"
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the resources deployed by this blueprint."
  type        = map(string)
  default     = {}
}
