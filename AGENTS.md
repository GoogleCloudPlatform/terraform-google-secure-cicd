<!-- bmad:context -->
<!-- Verified 2026-08-14 against <commit_sha>. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## terraform-google-secure-cicd

This repository provides Terraform modules and example configurations for deploying secure CI/CD pipelines on Google Cloud. It leverages Terraform, Docker, Google Cloud SDK, and a suite of testing tools.

## Policy

- PRs require at least one approval before merging.
- All code changes must adhere to security best practices for Google Cloud environments.

## Terraform Module Principles & Structure

This section outlines the principles and expected structure for Terraform modules within this repository. Agents MUST adhere to these guidelines for all module-related tasks.

### Philosophy

-   **Lean, Composable, and Focused:** Modules should be focused, perform a single logical function, and directly expose underlying provider resources with minimal abstraction.
-   **Resource-Type Centric:** Modules are designed to encapsulate a specific set of related resources (e.g., attestation mechanisms, private Cloud Build pools, CI pipelines, CD pipelines).

### Boundary Enforcement

-   **CRITICAL:** Agents MUST NEVER introduce unrelated resources into a module. Each module has a defined scope; new resources MUST align with that scope.

### Common Module File Structure

Each Terraform module (`modules/<module-name>/`) is expected to generally follow this structure:

*   `main.tf`: Contains the primary resource definitions and module calls, orchestrating the module's core logic.
*   `variables.tf`: Declares all input variables for the module. Each variable MUST have a clear, comprehensive `description` explaining its purpose, type, default value (if applicable), and any constraints or dependencies.
*   `outputs.tf`: Declares all output values from the module. Each output MUST have a clear `description` explaining what value it exports and its intended use.
*   `locals.tf`: Defines local variables and computed values. Agents SHOULD leverage this for simplifying complex expressions, centralizing frequently used values, and improving readability.
*   `iam.tf`: Configures Identity and Access Management (IAM) resources specific to the module.
*   `versions.tf`: Specifies the required Terraform version and provider versions, ensuring compatibility.
*   `README.md`: Contains the auto-generated `terraform-docs` output for inputs and outputs, along with a general description of the module. Agents MUST consult this for module interfaces.

### Variable Best Practices

-   **Descriptive `description` fields:** Clear and accurate `description` fields for variables and outputs are paramount. Agents MUST ensure these are present, comprehensive, and up-to-date, as verified during previous documentation audits.
-   **Explicit types and defaults:** Agents MUST always specify `type` for variables. Use `default` values when a reasonable default exists, and clearly document its implications.
-   **Validation Rules:** Agents SHOULD use `validation` blocks for complex constraints that cannot be expressed by `type` alone.

## Testing Philosophy & Guidelines

This section guides agents on how to understand, create, and execute tests within the repository.

### Philosophy

-   **Test to Ensure Correctness and Stability:** The core philosophy is to ensure the code works and does not break due to dependency changes.
-   **Example-Based Integration Testing Preferred:** Testing via deployments of the `/examples` is the preferred approach for module and example validation.

### Test Structure and Execution

-   **Integration Tests (`test/integration/`):**
    -   Written in Go, leveraging `cloud-foundation-toolkit` packages (e.g., `infra/blueprint-test/pkg/tft`) and helper functions (`testutils/gcp.go`).
    -   Organized into `harness_*` directories (e.g., `harness_cluster_network`), each representing a distinct integration test scenario.
    -   `discover_test.go` dynamically finds and executes these harnesses using `tft.AutoDiscoverAndTest`.
    -   **Automated Lifecycle Execution in Cloud Build:** These tests follow a rigorous automated lifecycle (`init`, `apply`, `verify`, `teardown` stages) executed within a Google-managed organization's Cloud Build environment. The `cft test run` command orchestrates these stages, provisioning and inspecting real GCP resources.
    -   Tests MUST cover functional correctness, security compliance (including policy enforcement from `/build/policies`), and network isolation. Test execution within Cloud Build is a mandatory step for merging PRs.
    -   **Mandatory for PRs:** Successful execution of these integration tests in Cloud Build (triggered via a `/gcbrun` comment on the PR by a repository collaborator) is a **mandatory step for merging PRs**.
    -   **Local Execution:** `make docker_test_integration` is provided for local development and debugging. `make docker_test_prepare` is used to set up the environment.
-   **Debugging Terraform Context & Locals:**
    -   **CRITICAL FOR DEBUGGING:** When troubleshooting how variables or `locals` are being evaluated during a Terraform plan, agents MUST NOT rely solely on `pytest` failure outputs or `grep`.
    -   **ALWAYS use a fast-failing `terraform_data` precondition:** Inject this snippet temporarily into the module being debugged:
        ```terraform
        resource "terraform_data" "debug_dump" {
          lifecycle {
            precondition {
              condition     = local.target_variable == null # Intentionally designed to fail
              error_message = yamlencode(local.target_variable)
            }
          }
        }
        ```
        Running the specific `pytest` plan test will then fail, and the captured output will contain the fully evaluated YAML representation of your `target_variable`, making context resolution issues immediately obvious.

## Development Workflow & Rules

This section details expected practices for contributing to the repository.

### Prerequisites

-   Terraform
-   Python 3.10+
-   Docker Engine
-   Google Cloud SDK
-   `make` utility

### Formatting & Linting

Agents MUST always format code and update documentation before committing. The `make docker_test_lint` command runs these checks:

-   **Terraform:** `terraform fmt` for formatting

### File Modification Rules (CRITICAL for AI)

-   **CRITICAL:** Agents MUST NEVER use shell redirection (`cat << EOF`, `echo "..." >`, `>>`, `tee`) to create, overwrite, or append to files.
-   For creating files, agents MUST ALWAYS use the native `write_file` tool.
-   For targeted edits or appending to a single file, agents MUST ALWAYS use the native `replace` tool. (To append, match the last few lines of the file and replace them with the same lines plus new content).
-   **EXCEPTION (Pattern/Bulk Edits):** Agents MAY use shell commands (like `sed -i`, `perl -pi`, or `find ... xargs sed`) ONLY for regex-based or pattern-based replacements, particularly across multiple files, where the exact-match `replace` tool is not feasible.

### Ambiguity & Paths

-   When encountering unfamiliar or unexpected repository structures, paths, or tool executions, agents MUST always pause and offer the user the choice to either explain or authorize further independent investigation, rather than making assumptions or guessing paths.

### CRITICAL (LINTING & FORMATTING)

-   Agents MUST ALWAYS run all formatting and linting checks (as described above) on all modified or new files BEFORE staging, committing, or pushing changes.

## Architecture & Conventions

This section provides general architectural and convention guidance for the repository.

### Variables & Interfaces

-   **Prefer object variables:** Use object variables (e.g., `iam = { ... }`) over many individual scalar variables to maintain compact and readable variable spaces.
-   **Optional functions with defaults:** Leverage `optional()` functions with defaults extensively to reduce complexity.
-   **Maps over lists:** Use maps instead of lists for multiple items to ensure stable keys in state and avoid `for_each` dynamic value issues.

### Naming

-   Agents MUST NEVER use random strings for resource naming. Rely on an optional prefix variable implemented consistently across modules.

### IAM

-   IAM policies are implemented within resources (using authoritative `_binding` or additive `_member` roles) via standard interfaces.

### Outputs

-   Agents MUST ensure outputs explicitly depend on internal resources to ensure proper ordering (`depends_on`).

### File Structure (Module-level)

-   Move away from generic filenames like `main.tf` for specific resource definitions. Use descriptive filenames (e.g., `iam.tf`, `gcs.tf`) over generic names like `main.tf`.

### Style & Formatting

-   **Line Length:** Enforce a 79-character line length limit for legibility (relaxed for long resource attributes and descriptions).
-   **Ternary Operators & Functions:** Wrap complex ternary operators in parentheses and break lines to align `?` and `:`. Split function calls with many arguments across multiple lines.
-   **Locals Separation:** Use module-level `locals` for values referenced directly by resources/outputs. Use block-level "private" locals prefixed with an underscore (`_`) for intermediate transformations.
-   **Complex Transformations:** Move complex data transformations in `for` or `for_each` loops to `locals` to keep resource blocks clean.

### Terraform Guidelines

#### 1. Resource Selection & Versioning

*   **Terraform Version Limit:** Do NOT use any Terraform features introduced in version 1.6.0 or later (due to BSL licensing changes). All code must be fully compatible with Terraform <= 1.5.7.
*   **Prefer CFT:** Always prioritize using Cloud Foundation Toolkit (CFT) modules over base google provider resources.
*   **Strict Version Pinning:** Always pin module versions.
    *   For stable modules (v1+): Pin by major version using the pessimistic constraint operator (e.g., `version = "~> 1.0"`).
    *   For pre-release modules (< v1): Pin by minor version (e.g., `version = "~> 0.2.0"`).

#### 2. Naming Conventions and style

*   **Snake Case:** All resources, modules, variables, and output names MUST use `snake_case`.
*   **No Redundancy:** Do NOT repeat the resource type in the resource name (e.g., use `resource "google_compute_network" "main"` instead of `resource "google_compute_network" "network"`).
*   **Simplicity:** Keep identifiers simple to reduce cognitive load. Use standard structural names like `main`, `primary`, or `secondary` instead of overly descriptive or redundant names.
*   **Resource Suffixing (Collision Avoidance):** ALL resources that have ANY chance of name collision MUST include a suffix in their deployed name. You MUST provide an optional `suffix` variable (type `string`, default `null`). If `suffix` is not provided, generate a random 4-character lowercase string (a-z) using the `random_string` resource and use it as the suffix.
*   **Logic placement:** Use `locals` blocks to handle complex interpolations, formatting, or conditionals, keeping the resource blocks clean.

#### 3. Directory and File Structure

*   Every module must be structured with at least the standard files: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and `README.md`.
*   **Component Isolation:** Isolate additional complex features (e.g., CMEK, IAM bindings) in specific files (e.g., `cmek.tf`, `iam.tf`).
*   **Internal File Ordering:** Inside EVERY `.tf` file, blocks MUST be strictly ordered as follows: `locals` -> `data` -> `resource` and `module`.
*   **Creation Flow Ordering:** `resource` and `module` blocks MUST be sorted mimicking their actual creation/execution flow (e.g., network before subnetwork, subnetwork before compute instance) to facilitate human reading).
*   **Scripts & Local-exec:** If the module requires `local-exec` provisioners or external scripts, they MUST be stored in a dedicated `scripts/` directory inside the module. Do NOT write the actual script logic. Instead, output the script file containing ONLY a brief comment/description of its intended purpose (another specialized AI will implement the actual logic).

#### 4. Variables, Outputs and Labels

*   **Variables completeness:** EVERY variable MUST have a `description` and a strict `type`.
*   **Variable ordering:** In `variables.tf`, declare required variables (no default) first, followed by optional variables (with default).
*   **Outputs completeness:** EVERY output MUST have a `description`.
*   **Format Examples in Descriptions:** Whenever applicable, description fields for variables and outputs MUST include the expected string format (e.g., "Expected format: `projects/{project}/regions/{region}/serviceAccounts/{email}`").
*   **Standard Labels:** Always include an optional `labels` variable (type `map(string)`, default `{}`) and inject it into all resources that support the `labels` argument.

#### 5. Iteration (Count vs For_each)

*   Use `for_each` when creating multiple identical resources based on a list or map to prevent state shifting.
*   Use `count` EXCLUSIVELY for boolean conditional logic (e.g., enabling/disabling a resource).

#### 6. API & Services Management

*   If the module requires enabling GCP APIs (`*.googleapis.com`), use the CFT Project Services submodule.
*   **Controls:**
    *   Expose a boolean variable `enable_services` to control this activation.
    *   Expose a variable `services_activation_delay_in_minutes`. Use a `time_sleep` resource to ensure subsequent resources wait for this duration after APIs is enabled before provisioning.

#### 7. Security & Encryption (CMEK)

*   **Always Check Support:** Always verify if the target resource supports Customer-Managed Encryption Keys (CMEK).
*   **CMEK Implementation:** If CMEK is supported, you MUST provide an optional variable `cmek` (type `string`, default `null`) to allow users to inject their own key.
*   **Fallback Logic:** If the `cmek` variable is NOT provided by the user, you MUST dynamically create a key using the CFT KMS module controlled by a `count` meta-argument. Prefer to name this module `cmek` for simplicity.
*   **Retention Control:** Any newly created CMEK must be controlled by a variable named `cmek_destroy_duration_in_days` to manage the key's soft deletion schedule.
### Architecture Diagram Guidelines

You are an expert Cloud Architecture Diagram Designer. Your task is to translate the approved Google Cloud Platform (GCP) architecture document into a highly professional visual representation using Mermaid.js.

#### Execution Rules

*   **Mermaid Format:** You MUST output valid Mermaid.js code enclosed in a ```mermaid markdown block. Do not output anything else outside this block.

*   **Layout Engine (ELK):** Standard Mermaid routing can get messy. You MUST use the ELK layout engine to ensure clean, professional, and deterministic line routing for the connections. You must include the following frontmatter at the very beginning of your Mermaid code:
    ```
    %%{init: {'flowchart': {'defaultRenderer': 'elk'}} }%%
    ```

*   **Google Color Palette for Groups (Subgraphs):** You MUST apply the official Google brand colors to style the logical groups (subgraph) representing the GCP hierarchy (e.g., VPCs, Subnets, Domains). Use the style directive directly on the subgraphs:
    *   Google Blue (`#4285F4`): Use for Project or core workload boundaries (e.g., `style Project fill:#ffffff,stroke:#4285F4,stroke-width:2px,color:#000`).
    *   Google Green (`#34A853`): Use for Networking, VPCs, and Subnets boundaries (e.g., `style VPC fill:#e6f4ea,stroke:#34A853,stroke-width:2px,color:#000`).
    *   Google Yellow (`#FBBC05`): Use for Data, Storage, and Database grouping (e.g., `style Data fill:#fef7e0,stroke:#FBBC05,stroke-width:2px,color:#000`).
    *   Google Red (`#EA4335`): Use for Errors, Alerts, or highly restricted/isolated zones (e.g., `style Restricted fill:#fce8e6,stroke:#EA4335,stroke-width:2px,color:#000`).

*   **Logical Grouping:** Group resources logically to represent the GCP hierarchy using Mermaid subgraph blocks. You should represent the boundaries clearly:
    *   Google Cloud Project
    *   Regions and Zones
    *   Virtual Private Clouds (VPCs) and Subnets

*   **Data/Traffic Flow:** Ensure directional arrows (`-->`) reflect the actual flow of traffic, data, or network dependencies. Add brief text labels to the arrows if the interaction is complex (e.g., `-->|HTTPS/443|`).
## Product Vision and Goals

### Vision
The vision for the Secure CI/CD Pipeline is to empower software engineers to confidently and securely deploy applications across GKE, Cloud Run, and Anthos Clusters on Google Cloud. This solution provides a pre-configured, clearly defined, and continuously updated approach that embeds Google's stringent security best practices directly into their deployment workflows, enabling accelerated innovation with uncompromised security.

### Goals
-   **Empower Software Engineers:** Provide a robust, secure, and compliant CI/CD solution.
-   **Accelerate Innovation:** Simplify secure pipeline building and maintenance.
-   **Ensure Uncompromised Security:** Embed Google's security best practices into deployment workflows.
-   **Facilitate Rapid Adoption:** Offer flexible Terraform modules for quick adoption.
-   **Maintain Continuous Relevance:** Ensure continuous updates and new examples.
-   **Introduce Advanced Deployment Strategies:** Enable configurable canary deployments and automatic rollbacks (roadmap).

<!-- /bmad:context -->

