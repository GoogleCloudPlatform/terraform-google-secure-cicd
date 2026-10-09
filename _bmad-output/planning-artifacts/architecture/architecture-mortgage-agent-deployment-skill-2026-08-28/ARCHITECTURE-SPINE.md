---
name: 'Mortgage Agent Deployment Skill'
type: architecture-spine
purpose: build-substrate
altitude: feature
paradigm: 'Checkpoint Pipeline'
scope: 'The Antigravity CLI deployment skill implementation and execution flow'
status: final
created: 2026-08-28
updated: 2026-08-28
binds: [CAP-1, CAP-2, CAP-3, CAP-4, CAP-5]
sources: []
companions: []
---

# Architecture Spine — Mortgage Agent Deployment Skill

## Design Paradigm

**Checkpoint Pipeline**
The skill operates as a sequential pipeline of discrete stages (Prerequisites, Configuration, Infra Provisioning, Repo Seeding, ADK Deploy). Before executing any stage, it executes a read-only `check_state` function. If the state is already achieved (e.g., git repos are seeded, terraform state exists), the stage is skipped. This paradigm natively satisfies the idempotency constraints without relying on a local state file.

## Invariants & Rules

### AD-1 — Stateless Resumability
- **Binds:** CAP-4, CAP-5, NFR-1
- **Prevents:** Split-brain scenarios where a local state file diverges from actual GCP/Git infrastructure state.
- **Rule:** The skill MUST NOT use a local state file (e.g., `.deploy_state.json`) to track progress. It MUST query the actual environment for the **successful end-state** (e.g., checking specific `terraform output` values, verifying the remote Git CI repo HEAD actually contains the pushed files) rather than just the presence of intermediate artifacts (like a local `.terraform/` folder), to accurately determine if a stage is fully completed.

### AD-2 — Direct Subprocess Execution
- **Binds:** CAP-3, CAP-4
- **Prevents:** Logic drift between the official `README.md` instructions and the agent's internal implementation.
- **Rule:** The skill MUST use Python's `subprocess.run` (or equivalent) to execute external tools (`terraform`, `envsubst`, `git`, `bash`) directly. To prevent silent hangs when capturing output, it MUST use non-interactive automation flags (e.g., `terraform apply -auto-approve`) for any command that natively prompts for user input, and SHOULD enforce sensible timeouts. It MUST NOT replace these with native Python library equivalents (like `GitPython`) unless strictly necessary.

### AD-3 — AI-Assisted Error Remediation
- **Binds:** All pipeline execution stages.
- **Prevents:** Frustrating user experiences where the skill halts on cryptic shell errors (e.g., Terraform quota limits, Git auth failures) and forces a full restart.
- **Rule:** If a subprocess returns a non-zero exit code, the skill MUST catch the error, pass **both `stdout` and `stderr`** (or a merged output) to an LLM context to generate a human-readable diagnosis and remediation step, present this to the user, and prompt for an interactive retry `(y/n)` of that specific stage.

## Consistency Conventions

| Concern | Convention |
| --- | --- |
| Subprocess Execution | Use `capture_output=True, text=True` to ensure both `stdout` and `stderr` can be passed to the LLM upon failure. Exceptions apply for inherently interactive shell commands (like `gcloud auth login`) which MUST NOT capture output so the user can interact with the browser/terminal prompts. |
| User Prompts | Use standard Antigravity CLI prompt utilities for yes/no and text input gathering. |

## Stack

| Name | Version |
| --- | --- |
| Python | >= 3.10 |
| Terraform | <= 1.5.7 (per repository constraints) |
| Git | Standard system binary |
| envsubst | Standard system binary (gettext) |
| Google Cloud SDK (gcloud) | Standard system binary |

## Structural Seed

```text
{antigravity-skill-root}/
  __init__.py
  skill.py             # Main entry point and BMad skill registration
  pipeline.py          # The Checkpoint Pipeline orchestrator
  stages/              # Individual pipeline stages
    prerequisites.py   # GCP/IAM/Domain checks
    configuration.py   # tfvars generation
    terraform.py       # init, plan, apply
    git_ops.py         # envsubst, git clone/commit/push
    adk_deploy.py      # python deploy script & IAM bash scripts
```

## Capability → Architecture Map

| Capability / Area | Lives in | Governed by |
| --- | --- | --- |
| CAP-1 (Prerequisites) | `stages/prerequisites.py` | Checkpoint Pipeline, AD-1 |
| CAP-2 (Config/tfvars) | `stages/configuration.py` | Checkpoint Pipeline |
| CAP-3 (TF Plan Gate) | `stages/terraform.py` | AD-2, AD-3 |
| CAP-4 (Apply, Git, ADK) | `stages/terraform.py`, `stages/git_ops.py`, `stages/adk_deploy.py` | AD-1, AD-2, AD-3 |
| CAP-5 (Status) | `pipeline.py` | Checkpoint Pipeline |

## Deferred
- Specific LLM prompt structure used for the AI Diagnosis in AD-3 (to be handled during implementation).
- How the Antigravity CLI context provides the LLM client (assumed to be available in the standard skill `context`).
