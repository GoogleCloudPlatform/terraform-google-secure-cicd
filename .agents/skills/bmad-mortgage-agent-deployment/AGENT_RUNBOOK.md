# Agent Runbook: Mortgage Agent Deployment

This runbook guides the agent in deploying the mortgage-agent example.

---

# Stage 1: Prerequisites

### 1.1: Welcome, Introduction & Architecture Overview
- Greet the user, introduce the deployment process, and provide an overview of what the **Mortgage Assistant Agent** is:
  - **What is the Mortgage Agent?**
    The Mortgage Agent is an enterprise reference implementation of an AI agent built with the **Google Agent Development Kit (ADK)** and hosted on **Vertex AI Reasoning Engine (Agent Runtime)**. It functions as an automated underwriting assistant for loan officers processing mortgage applications.
  - **Core Responsibilities:**
    - **Document Retrieval (`legacy-dms`):** Connects to a document management service to retrieve applicant tax forms (e.g., 1040s) and pay stubs.
    - **Income Verification (`income-verification`):** Queries a verification API to cross-reference reported wages and employer data.
    - **Underwriting Calculation:** Computes debt-to-income (DTI) metrics and surfaces discrepancies between tax returns and employer reports.
    - **Corporate Communications (`corporate-email`):** Interacts with the company inbox to read communications and draft applicant updates.
  - **Key Enterprise Architecture Pillars:**
    - **Zero-Trust Identity & Access:** Uses granular **Agent Identity** and an **Agent Gateway** with Identity-Aware Proxy (IAP) policies to enforce least-privilege egress (e.g., restricting email access to read-only tools).
    - **In-Flight Data Protection (Model Armor + Cloud DLP):** Automatically detects and redacts sensitive PII (such as Social Security Numbers) from tool outputs before they reach the model or user.
    - **Dynamic Discovery (MCP):** Uses the Model Context Protocol to discover backend microservice tools via Google Agent Registry at startup.
    - **Secure Software Supply Chain:** Backend microservices run on Cloud Run, provisioned through secure CI/CD pipelines featuring private Cloud Build pools, vulnerability scanning, and Binary Authorization signing.

### 1.2: Install Local Dependencies
- The agent will check for the presence of `uv` and `gettext-base`.
- If `uv` is not found, it will be installed by running: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- If `gettext-base` is not found, it will be installed by running: `sudo apt-get update && sudo apt-get install -y gettext-base`

### 1.3: Check gcloud Authentication
- **User Account:** Run `gcloud auth print-access-token` to check for active user credentials. If it fails, instruct the user to run `gcloud auth login`.
- **Application Default Credentials:** Run `gcloud auth application-default print-access-token` to check for active application default credentials. If it fails, instruct the user to run `gcloud auth application-default login`.

### 1.4: Confirm GCP Project
- Run `gcloud config get-value project` to find the currently configured project.
- If a project is found, ask the user for confirmation: "I've detected the project '[PROJECT_NAME]' is configured. Do you want to use this one for the deployment?".
- If the user agrees, proceed. If the user disagrees, or if no project was initially configured, prompt the user to enter the correct Project ID.
- Run `gcloud config set project [CHOSEN_PROJECT_ID]` to ensure the correct project is active for all subsequent commands.

### 1.5: Enable Required Google Cloud APIs
- Run the following command to enable all necessary APIs. If an API is already enabled, the command will be ignored for that API.
  ```bash
  gcloud services enable \
     cloudkms.googleapis.com \
     compute.googleapis.com \
     serviceusage.googleapis.com \
     cloudresourcemanager.googleapis.com \
     iam.googleapis.com \
     storage.googleapis.com \
     dns.googleapis.com \
     clouddeploy.googleapis.com
  ```

### 1.6: Check for Public DNS Zone
- Ask the user if they have a public DNS zone.
- If not, provide instructions on how to create one using Google Cloud Domains.

### 1.7: Check for Organization Policies
- Run `gcloud resource-manager org-policies describe constraints/gcp.restrictNonCmekServices --project=[PROJECT_ID]`.
- If the policy is enforced, halt and explain the blocker.
- Handle `PERMISSION_DENIED` errors gracefully.

---

# Stage 2: Configuration

### 2.1: Gather Configuration Values
- **User-Provided Values:** Prompt the user for the following information:
    - Public DNS Domain Name (e.g., `example.com`).
    - Terraform Service Account Email.
    - **The URLs for the 6 required Git repositories.** The agent must explain that for each of the three microservices, a separate repository for Continuous Integration (CI - source code) and Continuous Delivery (CD - deployment configs) is required, and then ask for them individually:
        - **Legacy DMS Service:**
            - CI Repository URL (e.g., `https://github.com/user/legacy-dms-ci.git`)
            - CD Repository URL (e.g., `https://github.com/user/legacy-dms-cd.git`)
        - **Corporate Email Service:**
            - CI Repository URL (e.g., `https://github.com/user/corporate-email-ci.git`)
            - CD Repository URL (e.g., `https://github.com/user/corporate-email-cd.git`)
        - **Income Verification Service:**
            - CI Repository URL (e.g., `https://github.com/user/income-verification-ci.git`)
            - CD Repository URL (e.g., `https://github.com/user/income-verification-cd.git`)
    - The names (not the values) of the Secret Manager secrets for the GitHub PAT and App ID.

- **Automatically-Derived Values:** The agent will obtain the following values programmatically:
    - `project_id`: From the project confirmed in Stage 1.5.
    - `project_number`: By running `gcloud projects describe [PROJECT_ID] --format='value(projectNumber)'`.
    - `org_id`: By running `gcloud projects get-ancestors [PROJECT_ID] --format='get(id)'` and extracting the organization ID.

### 2.2: Generate terraform.tfvars
- Read the content of the `examples/mortgage-agent/terraform.example.tfvars` template file.
- Programmatically replace the placeholder values using the variables gathered in Stage 2.1. This includes `project_id`, `project_number`, `org_id`, `dns_zone_domain`, the domain in `mcp_internal_dns_zone`, repository URLs, and secret names.
- **CRITICAL RULE:** Do NOT modify the `image` attribute for any service in the `mcp_services` map. The value `"us-docker.pkg.dev/cloudrun/container/placeholder"` is the correct, final value and must be preserved.
- Save the final, generated content to `examples/mortgage-agent/terraform.tfvars`.

---

# Stage 3: Infrastructure Provisioning

### 3.1: Terraform Plan
- Change directory to `examples/mortgage-agent`.
- Run `terraform init`.
- Run `terraform plan -out=tfplan`.
- Save the plan output to a file and show it to the user.
- Ask for explicit approval to proceed.

### 3.2: Terraform Apply
- Run the script `.agents/skills/bmad-mortgage-agent-deployment/scripts/01-terraform-apply.sh` from the root directory.

---
 
# Stage 4: Application Deployment
 
### 4.1: Render Skaffold and Cloud Run YAMLs
- For every MCP service, create the definitive `skaffold.yaml` and `cloud_run/*.yaml` files out of their respective `.tmpl` templates.
- Because `envsubst` pulls from the environment, ensure each service is processed in a single shell command that resolves the variables from Terraform beforehand. `DOMAIN_NAME` is the Public DNS Domain Name supplied by the user in Stage 2.1.
- Execute from the project's root folder, looping through each service:
```bash
  # Example for 'legacy-dms':
  cd examples/mortgage-agent
  export PROJECT_ID=$(terraform output -raw project_id)
  export REGION=$(terraform output -raw region)
  export MCP_INGRESS=$(terraform output -raw mcp_cloud_run_ingress_annotation)
  export BUCKET_NAME=$(terraform output -raw cloudbuild_bucket)
  export DOMAIN_NAME=[PUBLIC_DNS_DOMAIN]
  cd src/legacy-dms
  envsubst '${PROJECT_ID} ${REGION} ${MCP_INGRESS} ${BUCKET_NAME}' < skaffold.yaml.tmpl > skaffold.yaml
  cd ../../cloud_run
  envsubst '${PROJECT_ID} ${REGION} ${MCP_INGRESS} ${DOMAIN_NAME}' < legacy-dms.yaml.tmpl > legacy-dms.yaml
```
- Do the exact same for `corporate-email` and `income-verification-api`.
- Go back to the project root directory before moving to the next step.
### 4.2: Seed the CI Repositories
- Run the `.agents/skills/bmad-mortgage-agent-deployment/scripts/02-git-ops-and-adk.sh` script from the project root, one time for each MCP service.
- **Arguments:** the script requires `<service_name> <git_email> <git_name>`. Request the Git author email and name from the user for these seed commits.
- **Environment:** the script depends on `GITHUB_PAT_SECRET` and `CI_REPO_URL`. Ensure both are exported within the same shell session that invokes the script.
- **CRITICAL — service names:** loop through the source directory names exactly in this sequence:
  1. `legacy-dms`
  2. `corporate-email`
  3. `income-verification-api`
- **CRITICAL — repository mapping:** the third service has different naming conventions depending on the context. When handling `income-verification-api`, make sure to set `CI_REPO_URL` to the `income-verification-ci` URL obtained in Stage 2.1.
- This script populates only the CI repository. The CD repositories are established via Terraform but left empty: since there is only a single environment, no CD trigger is set up and the delivery is handled entirely by the CI build.
### 4.3: Final Status
- Report the final status of the application deployment to the user.
---
 
# Stage 5: Agent Deployment and Permissions
 
### 5.1: Allow Egress for All Agents Across Endpoints
- **Execute this prior to deploying the agent.** The agent requires external access during deployment to pull packages from github.com and reach the essential Google APIs.
- The script depends on `PROJECT_ID`, `PROJECT_NUMBER`, `ORG_ID`, and `REGION` being exported in the environment, and will terminate if any is absent. Resolve them all in the same shell session before running.
- Switch directory to `examples/mortgage-agent`.
```bash
  export PROJECT_ID=$(terraform output -raw project_id)
  export REGION=$(terraform output -raw region)
  export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
  export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID --format='get(id)' | tail -1)
  ./scripts/grant_agent_mcp_egress.sh --bind-all-agents --endpoints
```
 
### 5.2: Deploy the Agent
- Build and execute the `deploy_agent.py` script. By using `--enable-agent-identity`, this script calls `grant_agent_mcp_egress.sh` in the background and pulls `ORG_ID` and `PROJECT_NUMBER` from the environment (it will halt if they are missing). Resolve these variables from `examples/mortgage-agent`, and then move to the agent directory:
```bash
  export PROJECT_ID=$(terraform output -raw project_id)
  export REGION=$(terraform output -raw region)
  export AGENT_GATEWAY_ID=$(terraform output -raw agent_gateway_id)
  export MCP_INVOKER_SA=$(terraform output -raw agent_mcp_invoker_email)
  export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
  export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID --format='get(id)' | tail -1)
  cd src/mortgage_agent
  uv sync
  uv run python deploy_agent.py \
  --project=$PROJECT_ID \
  --region=$REGION \
  --enable-agent-identity \
  --agent-name=mortgage-agent \
  --agent-gateway=$AGENT_GATEWAY_ID \
  --mcp-invoker-sa=$MCP_INVOKER_SA \
  --model-endpoint-location=global
```
- Record the numeric `reasoningEngines/` ID printed on completion; it is needed in Stages 5.3 and 5.4. Then return to `examples/mortgage-agent` with `cd ../../`.
 
### 5.3: Grant Agent Per-MCP-Server Egress
- As in Stage 5.1, the four variables must be present in the shell session that executes the script. Run this from `examples/mortgage-agent`.
- Provide the specific agent with unrestricted access to `legacy-dms` and `income-verification`.
```bash
  export PROJECT_ID=$(terraform output -raw project_id)
  export REGION=$(terraform output -raw region)
  export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
  export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID --format='get(id)' | tail -1)
  ./scripts/grant_agent_mcp_egress.sh \
     --mcp \
     --agent-id [AGENT_ID] \
     --mcp-filter "legacy-dms income-verification"
```
- Execute the script one more time to give conditional access for `corporate-email`.
```bash
  export PROJECT_ID=$(terraform output -raw project_id)
  export REGION=$(terraform output -raw region)
  export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
  export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID --format='get(id)' | tail -1)
  ./scripts/grant_agent_mcp_egress.sh \
     --mcp \
     --agent-id [AGENT_ID] \
     --mcp-filter "corporate-email" \
     --condition-expression "api.getAttribute('iap.googleapis.com/mcp.tool.isReadOnly', false) == true || api.getAttribute('iap.googleapis.com/mcp.toolName','')==''" \
     --condition-title "ReadOnlyToolsOnly" \
     --condition-description "Restrict [AGENT_ID] to read-only tools on corporate-email"
```
 
### 5.4: Verify the Bindings
- Guide the user to the [Policies tab](https://console.cloud.google.com/agent-platform/policies/iam) to double-check the policies applied to the Endpoints and MCP Servers.
- Should the endpoints lack policies, execute the script with this configuration
```bash
  export PROJECT_ID=$(terraform output -raw project_id)
  export REGION=$(terraform output -raw region)
  export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
  export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID --format='get(id)' | tail -1)
  ./scripts/grant_agent_mcp_egress.sh --agent-id [AGENT_ID] --endpoints
```
 
### 5.5: Final Report
- Inform the user that the agent is fully deployed and ready for testing in the Agent Platform Playground.
