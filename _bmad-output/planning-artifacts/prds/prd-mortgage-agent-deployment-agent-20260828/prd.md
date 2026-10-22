---
title: Mortgage Agent Deployment Skill
status: draft
created: 2026-08-28
updated: 2026-08-28
---

# Product Requirements Document: Mortgage Agent Deployment Skill

## 1. Vision

The Mortgage Agent Deployment Skill is an Antigravity CLI skill designed to streamline the complex deployment process of the `mortgage-agent` example within the Secure CI/CD Pipeline repository. By combining guided user instructions with automated infrastructure and pipeline execution, this skill transforms a tedious and error-prone setup into a seamless experience.

## 2. Target User and Journeys

**Target User:**
Software engineers and platform operators of all experience levels who need to deploy the `mortgage-agent` example on Google Cloud to test, learn, or adapt the Secure CI/CD Pipeline patterns.

**User Journeys:**

> **UJ-1. Alex deploys the Mortgage Agent from scratch.**
> Alex, a Platform Engineer, opens the terminal in the repository and invokes the Mortgage Agent Deployment Skill.
>
> **Phase 1: Introduction & Prerequisites**
> The skill greets Alex and briefly explains what the `mortgage-agent` example provisions. It then initiates an interactive checklist for prerequisites: Organization, Project, IAM Permissions, Public Domain, and Org Policies. Alex realizes he hasn't set up a Public Domain yet. The skill detects this and provides the exact Cloud Domains registration instructions. (If Alex hadn't had an Organization, the skill would state it's required but *not* attempt to guide him through creating one. If his Organization enforced `restrictNonCmekServices`, the skill would halt entirely).
> 
> **Phase 2: Configuration Gathering**
> Once Alex confirms all prerequisites are met, the skill asks him sequentially for the values needed to populate `terraform.tfvars`, including asking for the URLs of the 6 pre-created GitHub repositories.
> 
> **Phase 3: Execution & Status**
> The skill runs `terraform plan`, saves the output to a file, and asks Alex for permission to proceed. After approval, the skill begins the automated deployment (Terraform apply, Repo seeding, ADK agent deployment). Mid-deployment, Alex types, "Where are we at?" The skill pauses, reads its state, and responds, "Currently running `terraform apply`. Still pending: CI repository seeding, Agent deployment, and IAM egress bindings."

## 3. Glossary

- **ADK Agent** — Agent Development Kit agent, deployed to reasoning engines.
- **MCP Server** — Model Context Protocol server (e.g., legacy-dms, corporate-email).
- **Secure CI/CD Pipeline** — The CI/CD process running in Cloud Build/Cloud Deploy for the MCP servers.

## 4. Features

### 4.1 Guided Setup & Prerequisites
**Description:** The skill interactively guides the user through the manual prerequisites required to deploy the mortgage-agent.

**Functional Requirements:**

#### FR-1: Prerequisite Interactive Checklist
The skill must interactively step the user through required prerequisites (Org, Project, IAM, Domain, Org Policies, gcloud Auth). 
*   **gcloud Authentication:** Check if `gcloud` is authenticated and configured with the correct active/quota project. If not, prompt the user. If they agree, the skill must automatically run `gcloud auth login`, set the active/quota project, and run `gcloud auth application-default login`.
*   **Domain:** Provide exact Cloud Domains registration instructions if missing.
*   **Org Policies:** If `constraints/gcp.restrictNonCmekServices` is enforced and cannot be bypassed, the skill must halt deployment. If the skill lacks `roles/orgpolicy.policyViewer` or otherwise receives a `PERMISSION_DENIED` error when checking policies, it must gracefully prompt the user to verify the policy manually rather than crashing.
*   **Organization:** If missing, state the requirement but explicitly *do not* guide the user on how to create one.

#### FR-2: Interactive Configuration Gathering
The skill must prompt the user sequentially for all required `terraform.tfvars` values, including asking for the URLs of the 6 pre-created GitHub repositories (CI and CD for the 3 services).
*   **Input Sanitization:** Automatically format strict fields (e.g., ensuring `dns_zone_domain` has a trailing dot).
*   **Uniqueness Validation:** Ensure that the 6 provided GitHub URLs are unique and explicitly formatted correctly to prevent duplicate repo overwrites.

### 4.2 Automated Deployment Execution
**Description:** The skill automates the execution of terraform and subsequent deployment scripts and git operations.

**Functional Requirements:**

#### FR-3: Terraform Plan & Approval Gate
The skill must execute `terraform init` and `terraform plan`. It must write the `plan` output to a file artifact, notify the user of its location, and pause execution to prompt for an explicit "yes/no" approval before proceeding.

#### FR-4: Automated Pipeline Seeding & Infrastructure Provisioning
Upon user approval, the skill must execute `terraform apply`. Once complete, it must automatically seed the 3 CI repositories. For each MCP service (`legacy-dms`, `corporate-email`, `income-verification`), the skill must:
1. Run `envsubst` to template the Cloud Run and Skaffold manifests.
2. Create a temporary staging directory.
3. Copy the service's source code (`src/<service>`), the templated `cloud_run/<service>.yaml`, and the `skaffold.yaml` into the directory.
4. Copy `cloudbuild-ci.yaml` and the `policies/` directory from the root `/build` directory into the staging directory.
5. Initialize a local git repository, explicitly check out or create the `main` branch (to avoid pushing to `master` or existing branches by accident), commit the files, and push to the user-provided CI repository URL to trigger the secure pipelines.
6. Once the pipelines are triggered, execute the Python script to deploy the reasoning engine ADK agent.
7. Execute the bash scripts to configure IAP IAM egress policies.

#### FR-5: Context-Aware Status Reporting
The skill must be able to interrupt its execution loop to respond to user inquiries about its current status (e.g., "Where are we?"), clearly stating the current running step and the remaining pending steps.

#### NFR-1: Idempotency & Resumability
If the skill's execution is halted midway (e.g., internet drops, quota limit hit after `terraform apply`), running the skill again must safely resume the process. It must verify the current state (e.g., detecting if terraform state exists, checking if repos already have code) before re-executing steps to avoid errors or duplicated data.

## 5. Non-Goals (Explicit)
- Automatically creating GitHub repositories via API.
- Creating the Google Cloud Organization or Billing Accounts on behalf of the user.
- Modifying the underlying Terraform module source code.
- Disabling organizational policies on behalf of the user.

## 6. MVP Scope

### 6.1 In Scope
- Interactive guidance for manual prerequisites.
- Policy blocker detection.
- Interactive `tfvars` generation.
- Terraform init, plan (with approval gate), and apply.
- Git ops to seed CI repos.
- Python ADK deploy and IAM bash script execution.
- Context-aware status reporting.

### 6.2 Out of Scope for MVP
- Generating the 6 GitHub repos automatically.

## 7. Success Metrics

**Primary**
- **SM-1**: End-to-end deployment success rate. Validates FR-1 through FR-4.

**Secondary**
- **SM-2**: Time taken to deploy (excluding manual prerequisite waiting). Validates FR-4.
