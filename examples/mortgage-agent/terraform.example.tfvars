# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

project_id = "YOUR_PROJECT_ID"

project_number = "000000000000" # format "000000000000"

org_id = "000000000000" # format "000000000000"

terraform_service_account = "REPLACE_ME"

# IAP Enforcement Mode ("DRY_RUN" or null)
agent_gateway_iap_iam_enforcement_mode = "DRY_RUN"

# Public DNS zone domain (must end with a dot). Still required when attaching
# a Google-provided cert so MCP hostnames match the cert SANs
# (mcp.<dns_zone_domain> / *.mcp.<dns_zone_domain>).
dns_zone_domain = "REPLACE_ME."

# Optional: skip Certificate Manager issuance and attach a cert Google already
# created in this project/region. Format:
# projects/PROJECT/locations/REGION/certificates/NAME
# mcp_ssl_certificate_id = "projects/YOUR_PROJECT_ID/locations/us-central1/certificates/REPLACE_ME"

# `domain` MUST be a real subdomain of dns_zone_domain (e.g.
# "mcp.${dns_zone_domain}") so Certificate Manager can issue a Google-managed
# regional cert. Agent Gateway does not currently validate self-signed certs,
# so values like "mcp-server.internal."
mcp_internal_dns_zone = {
  name   = "mcp-server-internal"
  domain = "mcp.REPLACE_ME."
}


# MCP services: key = Cloud Run service name + URL-mask token (DNS A record auto-created).
# New service = deploy + one entry. Replace the Google `placeholder` image with your own
# before real traffic (Skaffold overwrites the tag). min_instance_count = 1 avoids cold
# starts (~16-19s), which blow the 5s MCP initialize() timeout and drop all tools that turn.
mcp_services = {
  legacy-dms = {
    image = "us-docker.pkg.dev/cloudrun/container/placeholder"
    ci_repository = {
      repository_name = "REPLACE-WITH-REPOSITORY-NAME"
      repository_url  = "REPLACE-WITH-REPOSITYRO-URL"
    }
    cd_repository = {
      repository_name = "REPLACE-WITH-REPOSITORY-NAME"
      repository_url  = "REPLACE-WITH-REPOSITORY-URL"
    }
    otel_service_name  = "legacy-dms"
    min_instance_count = 1
  }
  corporate-email = {
    image = "us-docker.pkg.dev/cloudrun/container/placeholder"
    ci_repository = {
      repository_name = "REPLACE-WITH-REPOSITORY-NAME"
      repository_url  = "REPLACE-WITH-REPOSITORY-URL"
    }
    cd_repository = {
      repository_name = "REPLACE-WITH-REPOSITORY-NAME"
      repository_url  = "REPLACE-WITH-REPOSITORY-URL"
    }
    otel_service_name  = "corporate-email"
    min_instance_count = 1
  }
  income-verification = {
    image = "us-docker.pkg.dev/cloudrun/container/placeholder"
    ci_repository = {
      repository_name = "REPLACE-WITH-REPOSITORY-NAME"
      repository_url  = "REPLACE-WITH-REPOSITORY-URL"
    }
    cd_repository = {
      repository_name = "REPLACE-WITH-REPOSITORY-NAME"
      repository_url  = "REPLACE-WITH-REPOSITORY-URL"
    }
    otel_service_name  = "income-verification"
    min_instance_count = 1
  }
}
github_auth = {
  secret_id         = "projects/{SECRET_PROJECT_ID}/secrets/{PAT-SECRET_NAME}"
  app_id_secret_id  = "projects/{SECRET_PROJECT_ID}/secrets/{APP-ID-SECRET_NAME}"
  secret_project_id = "{SECRET_PROJECT_ID}"
}

# Per-service toolspec paths (relative to terraform/ or absolute). The
# toolspec is uploaded as the MCP server spec on the Agent Registry entry so
# clients see the full tool catalogue.
mcp_tool_specs = {
  legacy-dms          = "src/legacy-dms/toolspec.json"
  corporate-email     = "src/corporate-email/toolspec.json"
  income-verification = "src/income-verification-api/toolspec.json"
}

# Prompt injection / jailbreak detection confidence threshold
# Options: LOW_AND_ABOVE, MEDIUM_AND_ABOVE, HIGH
model_armor_pi_jailbreak_confidence = "MEDIUM_AND_ABOVE"

# Sensitive Data Protection enforcement (ENABLED or DISABLED).
# When ENABLED, the model-armor module also creates a DLP inspect template
# (US_SOCIAL_SECURITY_NUMBER), a DLP de-identify template (replace with
# infoType), and binds the Model Armor service agent to roles/dlp.{user,reader}.
# The response Model Armor template's sdp_settings.advanced_config is wired to
# those DLP templates so SSNs in MCP responses are redacted in flight.
model_armor_sdp_enforcement = "ENABLED"

# Name of the Agent Gateway resource (also used as a prefix for the network
# attachment, authz extensions, and authz policies).
agent_gateway_name = "agent-gateway"

# Dedicated subnet for the Agent Gateway PSC-I network attachment AND the
# relocated MCP internal LB VIP. Min /28, RFC1918, must NOT overlap
# 10.0.0.0/24, 10.0.1.0/24, or 10.0.2.0/24 (Agent Gateway egress restrictions).
agent_gateway_subnet_cidr = "10.20.0.0/28"

# When true, allow traffic through the Agent Gateway if an authz extension
# fails. Set false in production to fail-closed.
agent_gateway_authz_fail_open = true

# DNS peering: lets the gateway resolve customer-VPC private DNS zones so it
# can reach upstream MCP servers by hostname. Each domain MUST end with a trailing dot. Set the whole var
# to null to skip entirely.
# `target_project` defaults to var.project_id and `target_network` defaults
# to the VPC this module creates — only set them to peer against a different
# project/network.
agent_gateway_dns_peering_config = {
  domains = []
}

# Optional: Override the default list of Google APIs to register. Map key is
# the service short name; value is the human-readable display name surfaced in
# the Agent Registry UI.
agent_registry_google_apis = {
  aiplatform           = "Vertex AI Platform"
  cloudresourcemanager = "Cloud Resource Manager"
  discoveryengine      = "Discovery Engine"
  logging              = "Logging"
  monitoring           = "Monitoring"
  oauth2               = "OAuth2"
  telemetry            = "Telemetry"
  trace                = "Trace"
  agentregistry        = "Agent Registry"
  iap                  = "Identity-Aware Proxy"
  modelarmor           = "Model Armor"
  iamcredentials       = "IAM Credentials"
}

# Optional: Override or add custom (non-Google) services to register
agent_registry_custom_services = [
  {
    id           = "github"
    display_name = "Github"
    url          = "https://github.com"
  }
]