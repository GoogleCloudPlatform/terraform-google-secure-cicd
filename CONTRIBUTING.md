# Contributing

This document provides guidelines for contributing to the module.

## Dependencies

The following dependencies must be installed on the development system:

- [Docker Engine][docker-engine]
- [Google Cloud SDK][google-cloud-sdk]
- [make]

## Generating Documentation for Inputs and Outputs

The Inputs and Outputs tables in the READMEs of the root module,
submodules, and example modules are automatically generated based on
the `variables` and `outputs` of the respective modules. These tables
must be refreshed if the module interfaces are changed.

### Execution

Run `make generate_docs` to generate new Inputs and Outputs tables.

## Integration Testing

Integration tests are used to verify the behavior of the root module,
submodules, and example modules. Additions, changes, and fixes should
be accompanied with tests.

**The authoritative execution of integration tests occurs in Google Cloud Build, orchestrated by `int.cloudbuild.yaml` files located in the `build/` directory.** Local execution using `make docker_test_integration` is provided for development and debugging purposes.

The integration tests are run using [Kitchen][kitchen],
[Kitchen-Terraform][kitchen-terraform], and [InSpec][inspec]. These
tools are packaged within a Docker image for convenience.

The general strategy for these tests is to verify the behavior of the
[example modules](./examples/), thus ensuring that the root module,
submodules, and example modules are all functionally correct.

### Test Environment
The easiest way to test the module is in an isolated test project. The setup for such a project is defined in [test/setup](./test/setup/) directory.

To use this setup, you need a service account with these permissions (on a Folder or Organization):
- Project Creator
- Project Billing Manager

The project that the service account belongs to must have the following APIs enabled (the setup won't
create any resources on the service account's project):
- Cloud Resource Manager
- Cloud Billing
- Service Usage
- Identity and Access Management (IAM)

Export the Service Account credentials to your environment like so:

```
export SERVICE_ACCOUNT_JSON=$(< credentials.json)
```

You will also need to set a few environment variables:
```
export TF_VAR_org_id="your_org_id"
export TF_VAR_folder_id="your_folder_id"
export TF_VAR_billing_account="your_billing_account_id"
```

With these settings in place, you can prepare a test project using Docker:
```
make docker_test_prepare
```

### Noninteractive Execution

Run `make docker_test_integration` to test all of the example modules
noninteractively, using the prepared test project.

### Interactive Execution

1. Run `make docker_run` to start the testing Docker container in
   interactive mode.

1. Run `kitchen_do create <EXAMPLE_NAME>` to initialize the working
   directory for an example module.

1. Run `kitchen_do converge <EXAMPLE_NAME>` to apply the example module.

1. Run `kitchen_do verify <EXAMPLE_NAME>` to test the example module.

1. Run `kitchen_do destroy <EXAMPLE_NAME>` to destroy the example module
   state.

## Terraform Module Development Guidelines

To ensure consistency, maintainability, and clarity across our Terraform modules, please adhere to the following guidelines:

### Module File Structure

Each Terraform module (`modules/<module-name>/`) should generally follow this file structure:

*   `main.tf`: Contains the primary resource definitions, module calls, and core logic of the module.
*   `variables.tf`: Declares all input variables for the module. Each variable *must* have a clear, comprehensive `description` explaining its purpose, type, default value (if applicable), and any constraints or dependencies.
*   `outputs.tf`: Declares all output values from the module. Each output *must* have a clear `description` explaining what value it exports and its intended use.
*   `locals.tf`: Used for defining local variables and computed values. This helps in simplifying complex expressions, centralizing frequently used values, and improving readability.
*   `iam.tf`: Dedicated to Identity and Access Management (IAM) resource definitions, if applicable to the module.
*   `versions.tf`: Specifies the required Terraform version and provider versions, ensuring compatibility.
*   `README.md`: Contains the auto-generated `terraform-docs` output for inputs and outputs, along with a general description of the module.

### Variable Best Practices

*   **Descriptive `description` fields:** As verified during our documentation audit, clear and accurate descriptions for variables and outputs are paramount. They enable both human and AI contributors to understand the module's interface without needing to delve into its implementation details.
*   **Explicit types and defaults:** Always specify `type` for variables. Use `default` values when a reasonable default exists, and clearly document its implications.
*   **Validation Rules:** Use `validation` blocks for complex constraints that cannot be expressed by `type` alone.

### Use of `locals.tf`

Leverage `locals.tf` to:

*   **Simplify expressions:** Break down complex logic into more manageable local variables.
*   **Centralize values:** Define values that are used multiple times across different resources within the module.
*   **Improve readability:** Give meaningful names to derived values, making the module's logic easier to follow.

## Domain Terminology

This section defines key terms, acronyms, and concepts specific to this project, enhancing clarity for all contributors.

*   **Secure CI/CD pipeline:** The primary focus of this repository, implementing best practices for continuous integration and continuous delivery on Google Cloud.
*   **Terraform modules:** Reusable infrastructure as code components provided in this repository for deploying Google Cloud resources.
*   **Google Cloud:** The cloud platform where the CI/CD pipelines and associated resources are deployed.
*   **GKE (Google Kubernetes Engine):** Google Cloud's managed Kubernetes service, a common deployment target for containers in this pipeline.
*   **Cloud Run:** Google Cloud's fully managed compute platform for deploying containerized applications.
*   **Binary Authorization:** A security control on Google Cloud that enforces deployment policies for images to GKE. It ensures only trusted images are deployed.
*   **Cloud Build:** Google Cloud's serverless CI/CD platform, used extensively in this repository for building, testing, and deploying.
*   **Cloud Deploy:** Google Cloud's managed service for continuous delivery to various runtime environments, including GKE.
*   **Artifact Registry:** Google Cloud's universal package manager, used here for storing container images.
*   **Attestation:** A verifiable record, typically cryptographic, that asserts facts about a software artifact, crucial for Binary Authorization.
*   **VPC (Virtual Private Cloud):** A virtual network on Google Cloud that provides network isolation and connectivity for your resources.
*   **Service Account:** A special type of Google account used by applications and services to make authorized API calls.
*   **Kitchen/Kitchen-Terraform/InSpec:** Tools used in conjunction for integration testing Terraform modules, bundled within a Docker image.

## Code Conventions and Linting

To maintain a consistent code style and quality across the repository, the following linters and formatters are used:

- **Terraform:** `terraform fmt` for formatting and `tflint` for linting.
- **Go:** `gofmt` for formatting.
- **Python:** `flake8` for linting.
- **Dockerfiles:** `hadolint` for linting.
- **Shell Scripts:** `shellcheck` for linting.

These tools are executed automatically as part of the `make docker_test_lint` command and are enforced in the CI/CD pipeline.

### Execution

Run `make docker_test_lint`.

[docker-engine]: https://www.docker.com/products/docker-engine
[flake8]: http://flake8.pycqa.org/en/latest/
[gofmt]: https://golang.org/cmd/gofmt/
[google-cloud-sdk]: https://cloud.google.com/sdk/install
[hadolint]: https://github.com/hadolint/hadolint
[inspec]: https://inspec.io/
[kitchen-terraform]: https://github.com/newcontext-oss/kitchen-terraform
[kitchen]: https://kitchen.ci/
[make]: https://en.wikipedia.org/wiki/Make_(software)
[shellcheck]: https://www.shellcheck.net/
[terraform-docs]: https://github.com/segmentio/terraform-docs
[terraform]: https://terraform.io/
