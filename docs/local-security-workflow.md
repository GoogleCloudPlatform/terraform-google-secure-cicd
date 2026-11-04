# Shift-Left Local Security & AI Agent Workflow Guide

This guide details how to install, configure, and use the **Secure Coding Skills**, **Rules**, and **Lifecycle Hooks** from the upstream repository [`h3xar0n/secure-coding-agy-config`](https://github.com/h3xar0n/secure-coding-agy-config) within your local workspace.

This workflow is **local-first**: all security scanning, threat modeling, and code remediations execute directly on the developer's machine using Antigravity (AGY) AI skills and local lifecycle hooks.

---

## Architecture Overview

```
   ┌─────────────────────────────────────────────────────────────────┐
   │             LOCAL DEVELOPER / AGENT WORKSPACE (INNER LOOP)       │
   │                                                                 │
   │  1. Code Implementation & TDD ("Prove-It" Pattern)              │
   │  2. Threat Modeling & Architectural Risk Assessment             │
   │                                                                 │
   │  3. Choose Local Security Engine in AGY Hook:                   │
   │     ┌────────────────────────┐      ┌────────────────────────┐  │
   │     │     Option A: SEMGREP  │  OR  │   Option B: CODEMENDER │  │
   │     │ (Rule-based Fast SAST) │      │ (Agentic Scan & Repair)│  │
   │     └────────────────────────┘      └────────────────────────┘  │
   │                                                                 │
   │  4. Local Remediation & Review (inside IDE before pushing)      │
   └────────────────────────────────┬────────────────────────────────┘
                                    │ Clean Code (git push)
                                    ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │                 GOOGLE CLOUD CI/CD (OUTER LOOP)                 │
   │                                                                 │
   │  • Immutable Cloud Build & Cloud Deploy Pipeline                │
   │  • Container Analysis & Vulnerability Attestation               │
   │  • Binary Authorization Admission Control                       │
   └─────────────────────────────────────────────────────────────────┘
```

---

## 1. Installation: Adding Skills & Rules to Your Repository

Antigravity automatically discovers and loads skills, rules, and hooks located in the `.agents/` directory of your workspace.

### Step 1: Copy Configuration from Upstream

Run the following commands in the root of your application repository:

```bash
# 1. Clone the upstream secure coding configuration to a temporary directory
git clone https://github.com/h3xar0n/secure-coding-agy-config.git /tmp/secure-coding-config

# 2. Copy the .agents/ directory (skills, rules, and hooks) into your workspace
cp -r /tmp/secure-coding-config/.agents/ ./

# 3. (Optional) If you use Claude Code alongside Antigravity:
if [ -d "/tmp/secure-coding-config/.claude" ]; then
  cp -r /tmp/secure-coding-config/.claude/ ./
  cp /tmp/secure-coding-config/CLAUDE.md ./ 2>/dev/null || true
fi

# 4. Clean up temporary clone
rm -rf /tmp/secure-coding-config
```

### Step 2: Verify Installed Components

After copying, confirm the directory structure under `.agents/`:

```text
.agents/
├── hooks_semgrep.json             # Semgrep lifecycle hook definition
├── hooks_codemender.json          # CodeMender lifecycle hook definition
├── rules/
│   └── security_workflow.md       # Mandatory security rules for AI code generation
└── skills/
    ├── threat_modeling/           # Threat modeling and architectural risk analysis
    ├── test_driven_development/   # "Prove-It" test-driven development workflow
    └── secure_coding/             # OWASP Top 10 security scanning and remediation
```

---

## 2. Choosing Your Local Security Engine (Semgrep vs. CodeMender)

You can choose either **Semgrep** or **CodeMender** as your active local security engine.

| Engine | Type | Strengths | Best For | Hook Setup |
| :--- | :--- | :--- | :--- | :--- |
| **Semgrep** | Rule-based Static Analyzer | Instant execution, offline scanning, zero API quota dependency, standard OWASP rules | Fast local SAST checks with minimal overhead | `cp .agents/hooks_semgrep.json .agents/hooks.json` |
| **CodeMender** | Agentic AI Analysis & Repair | Context-aware semantic reasoning, direct code patch synthesis | Automated intelligent code review & repair | `cp .agents/hooks_codemender.json .agents/hooks.json` |

### Setting Up the Active Hook

To activate your chosen engine, copy the corresponding hook file to `.agents/hooks.json`:

```bash
# Option A: Enable Semgrep as your local engine
cp .agents/hooks_semgrep.json .agents/hooks.json

# OR

# Option B: Enable CodeMender as your local engine
cp .agents/hooks_codemender.json .agents/hooks.json
```

---

## 3. Local Prerequisites

### If Using Semgrep:
Ensure `semgrep` is installed locally:
```bash
# Using pip
pip install semgrep

# Or using Homebrew (macOS / Linux)
brew install semgrep
```

Verify the installation:
```bash
semgrep --version
```

### (Optional) Configuring a Native Git Pre-Push Hook
If you also want local checks to run when pushing manually via terminal (outside Antigravity), set up a repository-level Git pre-push hook:

1. Create `.githooks/pre-push`:

```bash
#!/usr/bin/env bash
set -e

echo "🔒 [Local Hook] Running pre-push security analysis..."

if command -v semgrep &> /dev/null; then
  echo "🔍 Running Semgrep SAST scan..."
  semgrep scan --config=auto --error --exclude="test/*" --exclude="_bmad-output/*"
  echo "✅ All local security checks passed."
else
  echo "⚠️ WARNING: Semgrep is not installed locally. Run 'pip install semgrep' to enable local security gates."
fi
```

2. Enable the hook for this repository:
```bash
chmod +x .githooks/pre-push
git config core.hooksPath .githooks
```

---

## 4. Using the Skills in Your Daily Workflow

### A. Threat Modeling Skill
Activate before introducing new endpoints, Cloud Run services, or database integrations:
> **Prompt:** *"Run a threat model on the new API endpoint and analyze potential authentication and data leakage risks."*

* **What it does:** Uses STRIDE methodology to inspect request/response boundaries, IAM permissions, and network exposure, outputting concrete security recommendations.

### B. Test-Driven Development ("Prove-It" Pattern)
Activate when implementing secure features or fixing identified vulnerabilities:
> **Prompt:** *"Use the test-driven development skill to write a failing unit test proving this endpoint rejects unauthenticated requests before writing the implementation."*

* **What it does:** Implements the red-green-refactor cycle with security-focused assertions to ensure fixes are thoroughly test-verified.

### C. Secure Coding Review & Remediation
Activate before committing code:
> **Prompt:** *"Review my recent code changes using the secure coding skill against OWASP Top 10 and Google Cloud security best practices."*

* **What it does:** Analyzes the workspace diff for common security anti-patterns and guides drop-in fixes.

---

## 5. Summary: Local-First Safety

* **Local Scans & Auto-Fixes:** Vulnerabilities are identified and remediated in the IDE in milliseconds before code leaves your machine.
* **Non-Disruptive:** Hooks are scoped exclusively to the workspace and do not impact global Git configuration.
* **Complementary to CI/CD:** Local checks ensure only vetted, clean code is pushed to Google Cloud CI/CD for build, container scanning, and deployment.
