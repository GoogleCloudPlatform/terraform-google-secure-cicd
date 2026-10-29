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
The skill operates as a sequential pipeline of discrete stages (Prerequisites, Configuration, Infra Provisioning, Repo Seeding, ADK Deploy) orchestrated by an Agent reading a Markdown Runbook. Before executing any stage, it executes a read-only `check_state` function via direct shell commands. If the state is already achieved (e.g., git repos are seeded, terraform state exists), the stage is skipped. This paradigm natively satisfies the idempotency constraints without relying on a local state file.

## Invariants & Rules

### AD-1 — Stateless Resumability
- **Binds:** CAP-4, CAP-5, NFR-1
- **Prevents:** Split-brain scenarios where a local state file diverges from actual GCP/Git infrastructure state.
- **Rule:** The skill MUST NOT use a local state file (e.g., `.deploy_state.json`) to track progress. It MUST query the actual environment for the **successful end-state** (e.g., checking specific `terraform output` values, verifying the remote Git CI repo HEAD actually contains the pushed files) rather than just the presence of intermediate artifacts (like a local `.terraform/` folder), to accurately determine if a stage is fully completed.

### AD-2 — Selective Shell Script Encapsulation
- **Binds:** CAP-3, CAP-4
- **Prevents:** Logic drift between the official `README.md` instructions and the skill's internal implementation, prevents context-window exhaustion from line-by-line Agent execution, and prevents LLM API timeouts during long-running infrastructure provisioning.
- **Rule:** The skill MUST use the Agent's native tool to execute simple external cli commands directly (`terraform init`, `terraform plan`, validations). However, long-running operations (`terraform apply`) and complex multi-step transactional operations (`envsubst`, `git`) MUST be encapsulated in standalone bash scripts (`scripts/*.sh`). To prevent silent hangs when capturing output, these scripts MUST use non-interactive automation flags (e.g., `terraform apply -auto-approve`) for any command that natively prompts for user input, and SHOULD enforce sensible timeouts.

### AD-3 — Native AI-Assisted Error Remediation
- **Binds:** All pipeline execution stages.
- **Prevents:** Frustrating user experiences where the skill halts on cryptic shell errors (e.g., Terraform quota limits, Git auth failures) and forces a full restart.
- **Rule:** If a direct command or script returns a non-zero exit code, the Agent MUST natively catch the error, pass **both `stdout` and `stderr`** (or a merged output) to its LLM context to generate a human-readable diagnosis and remediation step, present this to the user, and prompt for an interactive retry `(y/n)` of that specific stage.

## Consistency Conventions

| Concern | Convention |
| --- | --- |
| `run_command` Execution | Use `capture_output=True, text=True` (or the Agent's equivalent native shell tool) to ensure both `stdout` and `stderr` can be passed to the LLM upon failure. Exceptions apply for inherently interactive shell commands (like `gcloud auth login`) which MUST NOT capture output; instead, the Agent must pause the runbook and instruct the user to run them manually to interact with the browser/terminal prompts. |
| User Prompts | Use standard Antigravity CLI prompt utilities (via the Agent's native chat interface) for yes/no and text input gathering. |

## Stack

| Name | Version |
| --- | --- |
| Terraform | <= 1.5.7 (per repository constraints) |
| Git | Standard system binary |
| envsubst | Standard system binary (gettext) |
| Google Cloud SDK (gcloud) | Standard system binary |

## Structural Seed

```text
{antigravity-skill-root}/
  AGENT_RUNBOOK.md     # The Checkpoint Pipeline orchestrator instructions
  scripts/             # Encapsulated logic to protect against timeouts and context exhaustion
    01-terraform-apply.sh   # auto-approve apply
    02-git-ops-and-adk.sh   # envsubst, git clone/commit/push, and adk deploy scripts
```

## Capability → Architecture Map

| Capability / Area | Lives in | Governed by |
| --- | --- | --- |
| CAP-1 (Prerequisites) | `AGENT_RUNBOOK.md` | Checkpoint Pipeline, AD-1 |
| CAP-2 (Config/tfvars) | `AGENT_RUNBOOK.md` | Checkpoint Pipeline |
| CAP-3 (TF Plan Gate) | `AGENT_RUNBOOK.md` | AD-2, AD-3 |
| CAP-4 (Apply, Git, ADK) | `scripts/01-terraform-apply.sh`, `scripts/02-git-ops-and-adk.sh` | AD-1, AD-2, AD-3 |
| CAP-5 (Status) | `AGENT_RUNBOOK.md` | Checkpoint Pipeline |

## Deferred
- Specific LLM prompt structure used for the AI Diagnosis in AD-3 (to be handled during implementation).
- How the Antigravity CLI context provides the LLM client (assumed to be available in the standard skill `context`).
