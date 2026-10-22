---
stepsCompleted: ["step-01-validate-prerequisites", "step-02-design-epics", "step-03-create-stories", "step-04-final-validation"]
inputDocuments:
  - _bmad-output/specs/spec-mortgage-agent-deployment-agent-20260828/SPEC.md
  - _bmad-output/planning-artifacts/prds/prd-mortgage-agent-deployment-agent-20260828/prd.md
  - _bmad-output/planning-artifacts/architecture/architecture-mortgage-agent-deployment-skill-2026-08-28/ARCHITECTURE-SPINE.md
---

# terraform-google-secure-cicd - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for the native Antigravity CLI skill designed to deploy the `examples/mortgage-agent` example. It decomposes the requirements from the SPEC, PRD, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements & Capabilities (from SPEC)

CAP-1: Guide through prerequisites (gcloud Auth, Org, Project, IAM, Domain, Org Policies). Success: runs gcloud auth, identifies missing Domain, halts on `restrictNonCmekServices` or `PERMISSION_DENIED`. (Derived from FR-1)
CAP-2: Gather `terraform.tfvars` interactively. Success: sanitizes inputs (trailing dot) and validates uniqueness of 6 GitHub URLs. (Derived from FR-2)
CAP-3: Review infra plan. Success: runs `init` and `plan`, writes output, pauses for explicit approval. (Derived from FR-3)
CAP-4: Seed CI repos and deploy ADK agent. Success: runs `apply`, templates manifests, copies service source and root-level `/build` policies/configs, pushes to `main`, executes ADK/IAM scripts. (Derived from FR-4)
CAP-5: Context-aware status reporting. Success: interrupts loop to report current/pending steps. (Derived from FR-5)

### NonFunctional Requirements

NFR-1: If the agent's execution is halted midway, running the agent again must safely resume the process. It must verify the current state (e.g., detecting if terraform state exists, checking if repos already have code) before re-executing steps to avoid errors or duplicated data.

### Additional Requirements

- The skill operates as a Checkpoint Pipeline (sequential pipeline of discrete stages) and executes a read-only `check_state` function before executing any stage to natively satisfy idempotency.
- The skill MUST NOT use a local state file (AD-1) and MUST query the actual environment for the successful end-state.
- The skill MUST use Python's `subprocess.run` to execute external tools directly (AD-2) and MUST use non-interactive automation flags (e.g., `terraform apply -auto-approve`) for any command that natively prompts for user input.
- If a subprocess returns a non-zero exit code, the skill MUST pass both `stdout` and `stderr` to an LLM context to generate a diagnosis and remediation step, present it, and prompt for interactive retry (AD-3).
- Interactive shell commands (like `gcloud auth login`) MUST NOT capture output so the user can interact with the browser/terminal prompts.
- Subprocess Execution convention: Use `capture_output=True, text=True` to ensure both stdout and stderr can be passed to the LLM upon failure.
- User Prompts convention: Use standard Antigravity CLI prompt utilities for yes/no and text input gathering.
- Stack requirements: Python >= 3.10, Terraform <= 1.5.7, Git, envsubst, Google Cloud SDK.

### UX Design Requirements

None (CLI tool)

### FR Coverage Map

CAP-1: Epic 1 - Guide through prerequisites (gcloud Auth, Org, Project, IAM, Domain, Org Policies).
CAP-2: Epic 1 - Gather `terraform.tfvars` interactively with sanitization and validation.
CAP-3: Epic 2 - Review infra plan, write output, pause for explicit approval.
CAP-4: Epic 2 & Epic 3 - Epic 2 handles the `terraform apply`. Epic 3 handles the repo seeding, boundaries, ADK deployment, and IAM scripts.
CAP-5: Epic 3 - Context-aware status reporting via interruption.

## Epic List

### Epic 1: Interactive Configuration & Prerequisites
Users can interactively validate all GCP prerequisites, authenticate their local environment, and generate a sanitized, validated configuration for the deployment. This epic establishes the foundational **Checkpoint Pipeline** orchestrator (stateless tracking) and the **AI-Assisted Error Remediation** loop required by the Architecture.
**Capabilities covered:** CAP-1, CAP-2

### Epic 2: Infrastructure Provisioning & Approval Gate
Users can safely review the proposed infrastructure changes and provision the core GCP resources with idempotency and AI-assisted error recovery. This epic includes capturing and returning the Terraform outputs necessary for downstream pipeline stages.
**Capabilities covered:** CAP-3, CAP-4 (Terraform apply portion)

### Epic 3: CI/CD Pipeline Seeding & Deployment Automation
Users can automatically seed the required CI repositories across directory boundaries (hydrating manifests with Terraform outputs), deploy the Reasoning Engine ADK agent, and query the execution status on demand.
**Capabilities covered:** CAP-4 (Git & ADK portion), CAP-5

## Epic 1: Interactive Configuration & Prerequisites

Users can interactively validate all GCP prerequisites, authenticate their local environment, and generate a sanitized, validated configuration for the deployment. This epic establishes the foundational Checkpoint Pipeline orchestrator (stateless tracking) and the AI-Assisted Error Remediation loop required by the Architecture.

### Story 1.1: Core Pipeline Orchestrator & AI Remediation Loop

As a platform engineer,
I want a pipeline orchestrator that executes stages sequentially and diagnoses shell errors using AI,
So that the deployment is safely resumable and I get intelligent help if a command fails.

**Acceptance Criteria:**

**Given** the agent is executed from the terminal
**When** the pipeline starts
**Then** it must sequentially invoke registered stages
**And** it must execute a `check_state` function before each stage to skip completed work

**Given** a stage executes a shell command via `subprocess.run`
**When** the command returns a non-zero exit code
**Then** the agent must capture both `stdout` and `stderr`
**And** pass the output to the LLM to generate a diagnosis
**And** prompt the user to interactively retry the stage (y/n)

### Story 1.2: Interactive Prerequisites & gcloud Authentication Check

As a platform engineer,
I want the agent to verify my GCP prerequisites and authenticate my gcloud CLI,
So that I don't fail later in the deployment due to missing permissions or configurations.

**Acceptance Criteria:**

**Given** the prerequisites stage begins
**When** the agent checks `gcloud` authentication status
**Then** it must prompt the user if authentication is missing or misconfigured
**And** execute `gcloud auth login`, `config set project`, and `auth application-default login` interactively if the user agrees

**Given** the user is missing a Public Domain
**When** prompted
**Then** the agent must output the exact Cloud Domains registration instructions

**Given** the organization policies are checked
**When** `constraints/gcp.restrictNonCmekServices` is enforced
**Then** the agent must gracefully halt with an explanation
**And** gracefully handle `PERMISSION_DENIED` errors without crashing if the user lacks `policyViewer` roles

### Story 1.3: Interactive tfvars Configuration Gathering

As a platform engineer,
I want to be prompted for the required deployment variables and have them validated,
So that my `terraform.tfvars` is generated without formatting errors.

**Acceptance Criteria:**

**Given** the configuration stage begins
**When** prompting the user for variables
**Then** it must automatically sanitize strict fields (e.g., ensuring `dns_zone_domain` has a trailing dot)

**Given** the user provides the 6 GitHub repository URLs
**When** the input is submitted
**Then** the agent must validate that all 6 URLs are unique and correctly formatted before proceeding
**And** write the final variables to `terraform.tfvars`

### Story 2.1: Terraform Plan & Interactive Approval Gate

As a platform engineer,
I want to review the exact infrastructure changes before they are applied,
So that I don't accidentally provision incorrect or destructive changes to my GCP project.

**Acceptance Criteria:**

**Given** the configuration stage has completed successfully
**When** the terraform stage begins
**Then** the agent must execute `terraform init` and `terraform plan`

**Given** the `terraform plan` completes successfully
**When** presenting the results to the user
**Then** the agent must write the full plan output to a file artifact
**And** notify the user of the file's location
**And** pause execution to prompt for an explicit "yes/no" approval before proceeding

**Given** the user is prompted for approval
**When** the user inputs "no" or rejects the plan
**Then** the agent must gracefully halt execution without throwing a fatal error
**And** leave the environment unchanged

### Story 2.2: Terraform Apply & Output Extraction

As a platform engineer,
I want the agent to automatically apply the approved infrastructure and pass the outputs to the next stage,
So that the CI/CD pipeline seeding has the correct dynamic values to template the manifests.

**Acceptance Criteria:**

**Given** the user explicitly approves the terraform plan
**When** executing the apply
**Then** the agent must run `terraform apply -auto-approve` (using non-interactive flags per architecture)

**Given** the terraform apply completes successfully
**When** finalizing the terraform stage
**Then** the agent must extract the outputs (e.g., via `terraform output -json`)
**And** return/persist these values so downstream pipeline stages can consume them

### Story 3.1: CI Repository Seeding & Manifest Templating

As a platform engineer,
I want the agent to automatically template my manifests and push the correct files to my CI repositories,
So that I don't have to manually copy files across directories and run git commands for multiple services.

**Acceptance Criteria:**

**Given** the terraform stage completes and provides outputs
**When** the repository seeding stage runs for a service (e.g., `legacy-dms`)
**Then** the agent must template the Cloud Run and Skaffold manifests using `envsubst` populated with the terraform outputs

**Given** the staging directory is prepared for a service
**When** assembling the files to commit
**Then** the agent must copy the service's source code (`src/<service>`), the templated `cloud_run/<service>.yaml`, and the `skaffold.yaml`
**And** it must explicitly copy `cloudbuild-ci.yaml` and the `policies/` directory from the repository's root `/build` directory into the staging folder

**Given** the staging folder is fully assembled
**When** executing the git push
**Then** the agent must explicitly check out or create the `main` branch to avoid pushing to `master`
**And** push the commit to the correct CI repository URL gathered in the configuration stage
**And** it MUST NOT use the `--force` or `-f` flag during push, safely failing (and triggering AI remediation) if the remote repository already contains conflicting code

### Story 3.2: Reasoning Engine ADK Deployment & IAM Config

As a platform engineer,
I want the agent to automatically deploy the ADK agent and configure IAM policies after my repos are seeded,
So that the Reasoning Engine is fully functional without manual script execution.

**Acceptance Criteria:**

**Given** the CI repositories have been successfully seeded and pushed
**When** the ADK deployment stage begins
**Then** the agent must execute the Python script to deploy the reasoning engine ADK agent
**And** execute the bash scripts to configure IAP IAM egress policies using the subprocess wrapper

### Story 3.3: Context-Aware Status Interruption

As a platform engineer,
I want to be able to ask the agent for its current status during a long deployment,
So that I know the agent hasn't hung and I can see how much work is left.

**Acceptance Criteria:**

**Given** the agent is executing a long-running subprocess (like terraform or git pushing)
**When** the user attempts to query status
**Then** the agent must handle this gracefully (e.g., by intercepting `SIGINT` / Ctrl+C to pause and show a status menu instead of immediately killing the process, OR by using non-blocking asynchronous stdout readers)
**And** output the currently running pipeline step
**And** list all remaining pipeline steps that are still pending
**And** resume its execution without breaking the underlying subprocess if the user chooses to continue
