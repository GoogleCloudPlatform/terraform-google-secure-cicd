# Secure CI Module

This module creates a secure Continuous Integration (CI) pipeline using Google Cloud Build and Artifact Registry. It facilitates a software build process with built-in security checks, supporting native Cloud Source Repositories (CSR) as well as 2nd-gen Cloud Build connections for GitHub and GitLab.

To securely build container images, this pipeline focuses on implementing the "Securing artifacts before deployment" section of the [Shifting left on security report](https://cloud.google.com/solutions/shifting-left-on-security). The module implements security best practices such as: using Artifact Registry to store immutable container images, running container analysis scans to test container structure and check for CVEs, and preparing images for secure deployment.

## Features

This module provisions the following resources:

* **Source Code Repositories**: Supports native Cloud Source Repositories (CSR) or 2nd-gen Cloud Build repository connections for GitHub and GitLab.
* **Cloud Build Triggers**: Executes the integration pipeline upon pushing code changes to the application source code repository.
* **Artifact Registry**: A Docker repository for storing built container images.
* **Storage Bucket**: A GCS bucket to store build artifacts and cache, with optional Customer-Managed Encryption Key (CMEK) support.
* **Custom Builder Image**: Automatically builds and pushes a custom Skaffold builder image to Artifact Registry for use in the pipeline.
* **IAM & Security**: Provisions a dedicated least-privilege Service Account for Cloud Build execution and supports Cloud Build Private Pools.

## Prerequisites

### APIs

Ensure the following APIs are enabled in your GCP project:

* `cloudbuild.googleapis.com`
* `artifactregistry.googleapis.com`
* `sourcerepo.googleapis.com` (If using CSR)
* `containerscanning.googleapis.com`
* `secretmanager.googleapis.com` (If using GitHub/GitLab auth)

### IAM Roles

The identity executing this Terraform module needs the following minimum roles (or equivalent permissions) on the target project:

* `roles/artifactregistry.admin` (To create the Artifact Registry repository)
* `roles/cloudbuild.builds.editor` (To create triggers and submit the custom builder image build)
* `roles/cloudbuild.connectionAdmin` (To create 2nd-gen repository connections)
* `roles/iam.serviceAccountAdmin` (To create the `build-sa` service account)
* `roles/iam.serviceAccountUser` (To act as the `build-sa` when submitting the custom builder image)
* `roles/resourcemanager.projectIamAdmin` (To grant roles to the `build-sa` service account)
* `roles/secretmanager.secretAccessor` (To allow Cloud Build to access Git authentication secrets)
* `roles/source.admin` (To create the CSR repository, if applicable)
* `roles/storage.admin` (To create the cache bucket)
* `roles/serviceusage.serviceUsageAdmin` (To enable the Container Scanning API)

## Usage

### Basic Usage (Cloud Source Repositories)

```hcl
module "ci_pipeline" {
  source                  = "GoogleCloudPlatform/terraform-google-secure-cicd//secure-ci"

  project_id              = "my-gcp-project-id"
  primary_location        = "us-central1"
  repository_type         = "CSR"
  csr_app_source_repo     = "my-app-source"
  attestor_names_prefix   = ["build", "security", "quality"]
  app_build_trigger_yaml  = "cloudbuild-ci.yaml"
  build_image_config_yaml = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name     = "main"
}
```

### Usage with GitHub (2nd Gen Repositories)

```hcl
module "ci_pipeline" {
  source                  = "GoogleCloudPlatform/terraform-google-secure-cicd//secure-ci"

  project_id              = "my-gcp-project-id"
  primary_location        = "us-central1"
  repository_type         = "GITHUB"

  ci_repository = {
    repository_name = "my-github-repo"
    repository_url  = "https://github.com/my-org/my-app.git"
  }

  github_auth = {
    secret_id         = "projects/123/secrets/github-pat"
    app_id_secret_id  = "projects/123/secrets/github-app-id"
    secret_project_id = "my-secrets-project"
  }

  attestor_names_prefix   = ["build", "security", "quality"]
  app_build_trigger_yaml  = "cloudbuild-ci.yaml"
  build_image_config_yaml = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name     = "main"
}
```

### Build Configuration

The template `cloudbuild-ci.yaml` build configuration runs container structure and vulnerability scans, and creates Binary Authorization attestations based on their results. Add the configuration file to the root of your source repository to trigger the CI phase.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_level\_name | (VPC-SC) Access Level full name. When providing this variable, additional identities will be added to the access level, these are required to work within an enforced VPC-SC Perimeter. | `string` | `null` | no |
| additional\_substitutions | Parameters to be substituted in the build specification. All keys should begin with an underscore. | `map(string)` | `{}` | no |
| app\_build\_trigger\_yaml | Name of application cloudbuild yaml file | `string` | n/a | yes |
| attestor\_names\_prefix | A list of Binary Authorization attestors to create. The first attestor specified in this list will be used as the build-attestor during the CI phase. | `list(string)` | n/a | yes |
| bucket\_kms\_key | KMS Key id to be used to encrypt bucket. | `string` | `null` | no |
| cache\_bucket\_name | Name of cloudbuild artifact and cache GCS bucket | `string` | `""` | no |
| ci\_repository | The CI repository to configure. The key is a short name for the service. | <pre>object({<br>    repository_name = string<br>    repository_url  = string<br>  })</pre> | `null` | no |
| cloudbuild\_private\_pool | Cloud Build private pool self-link | `string` | `""` | no |
| cloudbuild\_service\_account\_roles | IAM roles given to the Cloud Build service account to enable security scanning operations | `list(string)` | <pre>[<br>  "roles/artifactregistry.admin",<br>  "roles/binaryauthorization.attestorsVerifier",<br>  "roles/cloudbuild.builds.builder",<br>  "roles/cloudbuild.connectionViewer",<br>  "roles/clouddeploy.developer",<br>  "roles/clouddeploy.releaser",<br>  "roles/cloudkms.cryptoOperator",<br>  "roles/containeranalysis.notes.attacher",<br>  "roles/containeranalysis.notes.occurrences.viewer",<br>  "roles/serviceusage.serviceUsageConsumer",<br>  "roles/source.writer",<br>  "roles/storage.admin",<br>  "roles/cloudbuild.workerPoolUser",<br>  "roles/ondemandscanning.admin",<br>  "roles/logging.logWriter"<br>]</pre> | no |
| clouddeploy\_pipeline\_name | Cloud Deploy pipeline name | `string` | `"deploy-pipeline"` | no |
| csr\_app\_source\_repo | Name of repo that contains app source code along with cloudbuild yaml | `string` | `"app-source"` | no |
| gar\_repo\_name\_suffix | Docker artifact registry repo to store app build images | `string` | `"app-image-repo"` | no |
| github\_auth | Authentication configuration for GitHub. Required only if repo\_type is 'GITHUBv2'. | <pre>object({<br>    secret_id         = string<br>    app_id_secret_id  = string<br>    secret_project_id = string<br>  })</pre> | `null` | no |
| gitlab\_auth | Authentication configuration for GitLab. Required only if repo\_type is 'GITLABv2'. | <pre>object({<br>    read_authorizer_credential_secret_id = string<br>    authorizer_credential_secret_id      = string<br>    webhook_secret_id                    = string<br>    enterprise_host_uri                  = optional(string)<br>    enterprise_service_directory         = optional(string)<br>    enterprise_ca_certificate            = optional(string)<br>    secret_project_id                    = string<br>  })</pre> | `null` | no |
| labels | A set of key/value label pairs to assign to the resources deployed by this blueprint. | `map(string)` | `{}` | no |
| primary\_location | Primary Google Cloud region for deploying resources like Artifact Registry, Cloud Storage buckets, and Cloud Build triggers. | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |
| repository\_type | The type of the repository. Must be one of 'GITHUB', 'GITLAB', or 'CSR'. | `string` | n/a | yes |
| trigger\_branch\_name | A regular expression to match one or more branches for the build trigger. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| app\_artifact\_repo | GAR Repo created to store runner images |
| binauth\_attestor\_ids | IDs of Attestors |
| binauth\_attestor\_names | Names of Attestors |
| binauth\_attestor\_project\_id | Project ID where attestors get created |
| build\_sa\_email | Cloud Build Service Account email address |
| cache\_bucket\_name | The name of the storage bucket for cloud build. |
| ci\_build\_trigger\_id | ID of the CI Cloud Build trigger. |
| skaffold\_builder\_image\_tag | The full path to the built Skaffold builder image in Artifact Registry. |
| source\_repo\_name | Name of the created CSR repos |
| source\_repo\_url | URLS of the created CSR repos |
| standalone\_bucket\_kms\_key | KMS Key for standalone bucket. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
