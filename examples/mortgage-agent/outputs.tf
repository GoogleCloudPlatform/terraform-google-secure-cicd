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

output "project_id" {
  description = "Project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region for resources"
  value       = var.region
}

output "cloudbuild_bucket" {
  description = "Cloud Build MCPs bucket name."
  value       = google_storage_bucket.cloudbuild.name
}

# Networking Module Outputs
output "vpc_id" {
  description = "The ID of the VPC network"
  value       = module.networking.network_id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = module.networking.network_name
}

output "subnet_id" {
  description = "The ID of the primary subnet"
  value       = module.networking.subnet_id
}

output "subnet_name" {
  description = "Name of the primary subnet"
  value       = module.networking.subnet_name
}

output "subnet_self_link" {
  description = "The self-link of the primary subnet"
  value       = module.networking.subnet_self_link
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = module.networking.network_self_link
}

output "psc_subnet_id" {
  description = "The ID of the Private Service Connect subnet"
  value       = module.networking.psc_subnet_id
}

output "psc_subnet_self_link" {
  description = "The self-link of the Private Service Connect subnet"
  value       = module.networking.psc_subnet_self_link
}

# MCP Services (Cloud Run) Outputs

output "mcp_service_names" {
  description = "Map of MCP service key to Cloud Run service name"
  value       = module.mcp_services.service_names
}

output "mcp_service_urls" {
  description = "Map of MCP service key to Cloud Run *.run.app URL (only reachable via the internal LB)"
  value       = module.mcp_services.service_urls
}

output "mcp_service_account_emails" {
  description = "Map of MCP service key to runtime service account email"
  value       = module.mcp_services.service_account_emails
}

output "agent_mcp_invoker_email" {
  description = "Email of the SA agents impersonate when invoking MCP Cloud Run services. Pass to deploy_agent.py via --mcp-invoker-sa or $MCP_INVOKER_SA_EMAIL."
  value       = module.agent_engine.agent_mcp_invoker_email
}

output "mcp_internal_dns_names" {
  description = "Map of MCP service key to its private DNS name (<service>.<domain>)."
  value = (
    var.mcp_internal_dns_zone != null
    ? { for k, _ in var.mcp_services : k => trimsuffix("${k}.${var.mcp_internal_dns_zone.domain}", ".") }
    : null
  )
}

output "mcp_internal_lb_ip" {
  description = "Internal IP address of the MCP services Application LB."
  value       = module.mcp_internal_lb.ip_address
}

output "mcp_internal_dns_zone_name" {
  description = "Cloud DNS managed zone name for the MCP servers private DNS"
  value       = module.networking.mcp_internal_dns_zone_name
}

output "mcp_internal_dns_domain" {
  description = "Domain name (with trailing dot) of the MCP servers private DNS zone"
  value       = module.networking.mcp_internal_dns_domain
}

output "mcp_cloud_run_ingress_annotation" {
  description = "Cloud Run v1 ingress annotation value to use when rendering cloudrun/*.yaml.tmpl."
  value       = "internal-and-cloud-load-balancing"
}

# Artifact Registry Outputs

output "artifact_registry_id" {
  description = "The Artifact Registry repository ID"
  value       = google_artifact_registry_repository.registry.id
}

output "artifact_registry_url" {
  description = "The Artifact Registry repository URL for docker push/pull"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.registry.repository_id}"
}

# Certificate Outputs

output "regional_certificate_name" {
  description = "Name or ID of the regional certificate used by the MCP Load Balancer."
  value       = local.provided_mcp_ssl_certificate_id != null ? local.provided_mcp_ssl_certificate_id : module.certificates.regional_certificate_name
}

output "mcp_ssl_certificate_id" {
  description = "Certificate Manager certificate ID attached to the MCP internal HTTPS LB (provided or issued)."
  value       = local.provided_mcp_ssl_certificate_id != null ? local.provided_mcp_ssl_certificate_id : module.certificates.internal_certificate_id
}

# Model Armor Outputs

output "model_armor_request_template_id" {
  description = "Request-side Model Armor template ID"
  value       = var.enable_model_armor ? module.model_armor[0].request_template_id : null
}

output "model_armor_request_template_name" {
  description = "Request-side Model Armor template full resource name"
  value       = var.enable_model_armor ? module.model_armor[0].request_template_name : null
}

output "model_armor_response_template_id" {
  description = "Response-side Model Armor template ID"
  value       = var.enable_model_armor ? module.model_armor[0].response_template_id : null
}

output "model_armor_response_template_name" {
  description = "Response-side Model Armor template full resource name"
  value       = var.enable_model_armor ? module.model_armor[0].response_template_name : null
}

output "model_armor_inspect_template_id" {
  description = "DLP inspect template ID referenced by the response template's advanced SDP config (null when model_armor_sdp_enforcement = DISABLED)"
  value       = var.enable_model_armor ? module.model_armor[0].inspect_template_id : null
}

output "model_armor_deidentify_template_id" {
  description = "DLP de-identify template ID referenced by the response template's advanced SDP config (null when model_armor_sdp_enforcement = DISABLED)"
  value       = var.enable_model_armor ? module.model_armor[0].deidentify_template_id : null
}

output "model_armor_service_account" {
  description = "Service Extensions service account (gcp-sa-dep) used by the Agent Gateway to call Model Armor"
  value       = var.enable_model_armor ? module.model_armor[0].service_account_email : null
}

output "model_armor_service_agent_email" {
  description = "Model Armor service agent (gcp-sa-modelarmor) granted DLP read access (null when model_armor_sdp_enforcement = DISABLED)"
  value       = var.enable_model_armor ? module.model_armor[0].model_armor_service_agent_email : null
}

# PSC Interface Outputs

output "psc_interface_network_attachment_id" {
  description = "Network attachment ID for PSC Interface (pass to deploy_agent.py --network-attachment)"
  value       = module.networking.psc_interface_network_attachment_id
}

output "psc_interface_network_attachment_name" {
  description = "Network attachment name for PSC Interface"
  value       = module.networking.psc_interface_network_attachment_name
}

output "psc_interface_dns_zone_name" {
  description = "DNS zone name for PSC Interface DNS peering"
  value       = module.networking.psc_interface_dns_zone_name
}

output "psc_interface_dns_domain" {
  description = "Domain name for PSC Interface DNS peering (ends with a dot)"
  value       = module.networking.psc_interface_dns_domain
}

output "psc_interface_dns_peering_domain" {
  description = "DNS domain for PSC Interface DNS peering (pass to deploy_agent.py --dns-peering-domain)"
  value       = var.mcp_internal_dns_zone != null ? var.mcp_internal_dns_zone.domain : null
}

# Agent Gateway Outputs

output "agent_gateway_id" {
  description = "Full resource ID of the Agent Gateway"
  value       = module.agent_gateway.agent_gateway_id
}

output "agent_gateway_mtls_endpoint" {
  description = "mTLS endpoint clients use to reach the Agent Gateway"
  value       = module.agent_gateway.mtls_endpoint
}

output "agent_gateway_root_certificates" {
  description = "Root certificates clients use to validate the Agent Gateway mTLS endpoint"
  value       = module.agent_gateway.root_certificates
  sensitive   = true
}

output "agent_gateway_service_extensions_service_account" {
  description = "Service account the Agent Gateway uses to call out to authz extensions"
  value       = module.agent_gateway.service_extensions_service_account
}

output "agent_gateway_registry_uri" {
  description = "URI of the project-local agent registry the gateway is bound to"
  value       = module.agent_gateway.registry_uri
}

output "agent_gateway_subnet_self_link" {
  description = "Self link of the Agent Gateway dedicated co-location subnet"
  value       = module.networking.agent_gateway_subnet_self_link
}

# Agent Registry Endpoints Outputs

output "agent_registry_service_ids" {
  description = "Map of registered Agent Registry service resource IDs, keyed by service_id"
  value       = module.agent_registry_endpoints.service_ids
}
