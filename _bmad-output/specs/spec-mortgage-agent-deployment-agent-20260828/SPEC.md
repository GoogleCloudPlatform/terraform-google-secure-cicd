---
id: SPEC-mortgage-agent-deployment-agent-20260828
companions:
  - ../planning-artifacts/architecture/architecture-terraform-google-secure-cicd-2026-08-28/ARCHITECTURE-SPINE.md
sources:
  - _bmad-output/planning-artifacts/prds/prd-mortgage-agent-deployment-agent-20260828/prd.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Mortgage Agent Deployment Skill Spec

## Why

To solve the friction and high error rate software engineers experience when attempting to deploy the `mortgage-agent` example. The current manual process involves complex prerequisites (org policies, domain registration), error-prone `tfvars` configuration, tedious repository management, and strict execution ordering. This skill transforms the process into a seamless, guided, and automated experience.

## Capabilities

- **CAP-1**
  - **intent:** User is interactively guided through mandatory prerequisites (gcloud Auth, Org, Project, IAM, Domain, Org Policies).
  - **success:** Agent checks `gcloud` auth/project settings and (if user agrees) interactively runs `gcloud auth login`, sets active/quota projects, and runs `gcloud auth application-default login`. Agent correctly identifies missing Domain and provides registration instructions; Agent gracefully halts and explains if `constraints/gcp.restrictNonCmekServices` is enforced or if it receives a `PERMISSION_DENIED` reading the policy.

- **CAP-2**
  - **intent:** User provides configuration values interactively to populate `terraform.tfvars`.
  - **success:** Agent sanitizes inputs (e.g., trailing dot on `dns_zone_domain`) and validates the uniqueness of the 6 provided GitHub repository URLs before proceeding.

- **CAP-3**
  - **intent:** User reviews the infrastructure plan before it is applied.
  - **success:** Agent runs `terraform init` and `plan`, writes the output to a file, and successfully pauses execution until explicit user approval is granted.

- **CAP-4**
  - **intent:** System automatically seeds the CI repositories and deploys the ADK agent after infrastructure is provisioned.
  - **success:** Agent successfully runs `terraform apply`, templates manifests, copies the service source code and the root-level `/build` directory policies/CI configs into temporary directories, explicitly pushes to the `main` branch of the respective CI repos, and executes the ADK deployment and IAM scripts.

- **CAP-5**
  - **intent:** User can ask for the current deployment status at any time during execution.
  - **success:** Agent successfully interrupts its loop to report the currently running step and the remaining pending steps.

## Constraints

- Execution must be idempotent and safely resumable: the agent must verify current state (e.g., terraform state existence, repo code presence) before re-executing steps if halted midway.

## Non-goals

- Automatically creating GitHub repositories via API.
- Creating the Google Cloud Organization or Billing Accounts on behalf of the user.
- Modifying the underlying Terraform module source code.
- Disabling organizational policies on behalf of the user.

## Success signal

- A user can successfully deploy the `mortgage-agent` example end-to-end from an empty project state to a running CI/CD pipeline and Reasoning Engine agent, with zero manual configuration errors.
