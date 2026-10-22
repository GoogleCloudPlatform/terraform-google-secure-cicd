---
title: Mortgage Agent Deployment Skill
status: finalized
created: 2026-08-28
updated: 2026-08-28
---

# Product Brief: Mortgage Agent Deployment Skill

## Executive Summary

The Mortgage Agent Deployment Skill is an Antigravity CLI skills designed to streamline the complex deployment process of the `mortgage-agent` example within the Secure CI/CD Pipeline repository. By combining guided user instructions with automated infrastructure and pipeline execution, this skill transforms a tedious and error-prone setup into a seamless experience. 

## The Problem

Deploying the `mortgage-agent` example today is fraught with friction for users. The primary pain points include:
- **Complex Prerequisites & Hard Blockers:** Users must navigate intricate requirements including specific GCP project structures, billing, extensive IAM roles, and a mandatory public DNS domain. Furthermore, organizational policies such as `constraints/gcp.restrictNonCmekServices` act as hard blockers if enforced.
- **Error-Prone Configuration:** Gathering secrets, project numbers, and correctly updating the `terraform.tfvars` file is difficult and complex.
- **Tedious Repository Management:** Users are required to manually create 6 distinct source repositories (CI and CD repos for `legacy-dms`, `corporate-email`, and `income-verification`) to support the secure pipelines, and seed them with templated code.
- **Strict Execution Ordering:** The actual steps to deploy must be followed in a precise order: Terraform apply -> templating `skaffold.yaml` -> pushing to CI repos -> deploying the agent to the Reasoning Engine -> granting per-MCP egress IAM policies. It is easy to get wrong when reading a manual `README.md`.

## The Solution

The Mortgage Agent Deployment Skill acts as a hybrid guide and automator.

**As a Guide:** 
It walks users through the necessary manual prerequisites, explaining what GCP resources or configurations must be established first, and waits patiently for the user to complete them. 
*Domain Registration:* The example mandates a public DNS domain. If the user lacks one, the skill will prompt them and offer to guide them through registering a new domain using Google Cloud Domains (which starts at ~$12/year). The skill will provide the exact steps: navigating to Cloud Domains in the console, searching/purchasing the domain, and crucially, ensuring they select the option to have Cloud DNS automatically set up a public zone.
*Critically, it handles organizational constraints gracefully:* it informs the user that `constraints/gcp.restrictNonCmekServices` is a deployment blocker. If the user indicates they cannot resolve or bypass this constraint, the skill halts the process and clearly explains that deployment is impossible in the current environment.

**As an Automator:** 
Once prerequisites are met, the skill takes over the heavy lifting:
- Automates the complex `tfvars` configuration based on user inputs.
- Creates the 6 required GitHub repositories for the CI/CD pipelines.
- Runs the Terraform lifecycle (`init`, `plan`, `apply`).
- Uses `envsubst` to dynamically template the Cloud Run and Skaffold manifests.
- Commits and pushes the initial source code to the CI repositories to trigger the secure pipelines.
- Runs the Python script to deploy the reasoning engine ADK agent.
- Executes the final bash scripts to configure IAP IAM egress policies.

## What Makes This Different

Instead of just providing a script or a static README, this skill provides an interactive, context-aware deployment companion. It bridges the gap between manual prerequisites that require human judgment (like org policies, domain registration, or billing setup) and the tedious mechanical tasks (like repo creation and terraform applies) that machines do best.

## Who This Serves

Software engineers and platform operators of all experience levels who need to deploy the `mortgage-agent` example on Google Cloud to test, learn, or adapt the Secure CI/CD Pipeline patterns.

## Success Criteria

- A user can successfully deploy the `mortgage-agent` example end-to-end using the skill.
- Reduction in manual deployment errors related to configuration and step ordering.
- Users blocked by organizational policies fail fast with clear, actionable explanations rather than obscure deployment errors.

## Scope

**In Scope:**
- Interactive guidance for manual prerequisites (Project, Billing, IAM, Public DNS).
- Organizational policy blocker detection and graceful halting (e.g., `restrictNonCmekServices`).
- Automated generation/updating of `terraform.tfvars`.
- Automated creation of the 6 required GitHub repositories for the pipelines.
- Automated execution of `terraform init`, `plan`, and `apply`.
- Automated templating of manifests, CI repository seeding, and pipeline triggering.
- Automated reasoning engine agent deployment and IAP egress policy binding.

**Out of Scope:**
- Creating the Google Cloud Organization or Billing Accounts on behalf of the user.
- Modifying the underlying Terraform module source code.
- Disabling organizational policies on behalf of the user.

## Vision

As the repository adds more complex, end-to-end examples, this deployment skill pattern can be generalized into a universal "Example Deployer" skill, making the entire `examples/` directory instantly accessible and deployable for any engineer in minutes.
