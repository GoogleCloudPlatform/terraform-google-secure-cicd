# Secure CD Module

This module creates a secure Continuous Deployment (CD) pipeline using Google Cloud Deploy, Cloud Build, and Binary Authorization. It facilitates the automated, secure rollout of containerized applications to various target environments (GKE, Anthos, or Cloud Run) while enforcing strict security gates.

To ensure only trusted artifacts are deployed, this module configures Binary Authorization policies on the target clusters, requiring specific attestations (e.g., build, vulnerability scan, QA approval) before a deployment is allowed to proceed.

## Features

This module provisions the following resources:

* **Cloud Deploy Pipeline & Targets**: Creates a delivery pipeline and deployment targets (GKE, Anthos, or Cloud Run) based on your environment definitions.
* **Cloud Build Triggers**: Sets up Pub/Sub-driven Cloud Build triggers that execute the actual deployment manifests (e.g., `cloudbuild-cd.yaml`) when Cloud Deploy initiates a rollout.
* **Source Code Repositories**: Supports native Cloud Source Repositories (CSR) or 2nd-gen Cloud Build repository connections (GitHub/GitLab) for storing your CD configuration files.
* **Binary Authorization Policies**: Enforces `REQUIRE_ATTESTATION` rules on the target clusters, ensuring images are signed by the required attestors before deployment.
* **Pub/Sub Notifications**: Creates a Pub/Sub topic to handle Cloud Deploy operational notifications.
* **IAM & Security**: Provisions a dedicated Cloud Deploy execution Service Account and configures all necessary cross-service IAM bindings (e.g., allowing Cloud Build to impersonate the execution SA, granting GKE developer roles, and allowing the BinAuthz service agent to verify attestations).

## Prerequisites

### APIs

Ensure the following APIs are enabled in your GCP project:

* `clouddeploy.googleapis.com`
* `cloudbuild.googleapis.com`
* `binaryauthorization.googleapis.com`
* `pubsub.googleapis.com`
* `sourcerepo.googleapis.com` (If using CSR)
* `secretmanager.googleapis.com` (If using GitHub/GitLab auth)

### IAM Roles

The identity executing this Terraform module needs the following minimum roles (or equivalent permissions) on the target project:

* `roles/binaryauthorization.policyEditor` (To configure cluster admission rules)
* `roles/cloudbuild.builds.editor` (To create deployment triggers)
* `roles/cloudbuild.connectionAdmin` (To create 2nd-gen repository connections)
* `roles/clouddeploy.admin` (To create the delivery pipeline and targets)
* `roles/iam.serviceAccountAdmin` (To create the Cloud Deploy execution service account)
* `roles/pubsub.admin` (To create the Cloud Deploy operations topic)
* `roles/resourcemanager.projectIamAdmin` (To grant necessary roles to the execution and build service accounts)
* `roles/source.admin` (To create the CSR repository, if applicable)

## Usage

### Basic Usage (Cloud Source Repositories & GKE)

```hcl
module "cd_pipeline" {
  source = "GoogleCloudPlatform/terraform-google-secure-cicd//secure-cd"

  project_id                 = "my-gcp-project-id"
  primary_location           = "us-central1"
  repository_type            = "CSR"
  csr_cloudbuild_cd_repo     = "my-cd-config-repo"
  gar_repo_name              = "my-app-image-repo"
  app_deploy_trigger_yaml    = "cloudbuild-cd.yaml"
  cache_bucket_name          = "my-build-cache-bucket"
  clouddeploy_pipeline_name  = "my-app-delivery-pipeline"
  cloudbuild_service_account = "build-sa@my-gcp-project-id.iam.gserviceaccount.com"

  deploy_branch_clusters = {
    "dev" = {
      cluster               = "dev-cluster"
      anthos_membership     = ""
      project_id            = "my-gcp-project-id"
      location              = "us-central1"
      required_attestations = ["projects/my-gcp-project-id/attestors/build-attestor"]
      env_attestation       = "projects/my-gcp-project-id/attestors/security-attestor"
      next_env              = "qa"
      target_type           = "gke"
    },
    "qa" = {
      cluster               = "qa-cluster"
      anthos_membership     = ""
      project_id            = "my-gcp-project-id"
      location              = "us-central1"
      required_attestations = [
        "projects/my-gcp-project-id/attestors/build-attestor",
        "projects/my-gcp-project-id/attestors/security-attestor"
      ]
      env_attestation       = "projects/my-gcp-project-id/attestors/qa-attestor"
      next_env              = ""
      target_type           = "gke"
    }
  }
}
```

### Usage with GitLab (2nd Gen Repositories)

```hcl
module "cd_pipeline" {
  source = "GoogleCloudPlatform/terraform-google-secure-cicd//secure-cd"

  project_id                 = "my-gcp-project-id"
  primary_location           = "us-central1"
  repository_type            = "GITLAB"
  gar_repo_name              = "my-app-image-repo"
  app_deploy_trigger_yaml    = "cloudbuild-cd.yaml"
  cache_bucket_name          = "my-build-cache-bucket"
  clouddeploy_pipeline_name  = "my-app-delivery-pipeline"
  cloudbuild_service_account = "build-sa@my-gcp-project-id.iam.gserviceaccount.com"

  cd_repository = {
    repository_name = "my-gitlab-cd-repo"
    repository_url  = "https://gitlab.com/my-org/my-cd-configs.git"
  }

  gitlab_auth = {
    read_authorizer_credential_secret_id = "projects/123/secrets/gitlab-read-token"
    authorizer_credential_secret_id      = "projects/123/secrets/gitlab-authorizer-token"
    webhook_secret_id                    = "projects/123/secrets/gitlab-webhook-secret"
    secret_project_id                    = "my-secrets-project"
  }

  deploy_branch_clusters = {
    "prod" = {
      cluster               = "prod-cluster"
      anthos_membership     = ""
      project_id            = "my-gcp-project-id"
      location              = "us-central1"
      required_attestations = ["projects/my-gcp-project-id/attestors/qa-attestor"]
      env_attestation       = ""
      next_env              = ""
      target_type           = "gke"
    }
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_level\_name | (VPC-SC) Access Level full name. When providing this variable, additional identities will be added to the access level, these are required to work within an enforced VPC-SC Perimeter. | `string` | `null` | no |
| additional\_substitutions | Parameters to be substituted in the build specification. All keys should begin with an underscore. | `map(string)` | `{}` | no |
| app\_deploy\_trigger\_yaml | Name of application cloudbuild yaml file for deployment | `string` | n/a | yes |
| cache\_bucket\_name | cloud build artifact bucket name | `string` | n/a | yes |
| cd\_repository | The CD repository to configure. The key is a short name for the service. | <pre>object({<br>    repository_name = string<br>    repository_url  = string<br>  })</pre> | `null` | no |
| cloudbuild\_private\_pool | Cloud Build private pool self-link | `string` | `""` | no |
| cloudbuild\_service\_account | Cloud Build SA email address | `string` | n/a | yes |
| clouddeploy\_pipeline\_name | Cloud Deploy pipeline name | `string` | n/a | yes |
| csr\_cloudbuild\_cd\_repo | Name of the CSR repo that stores the Cloud Build CD phase configs - for post-deployment checks | `string` | `null` | no |
| deploy\_branch\_clusters | A list of environment deployments, ordered by 'env\_number'. target\_type can be one of `gke`, `anthos_cluster`, or `run`. See [clouddeploy\_target Terraform docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_target) for more details | <pre>map(object({<br>    name                  = string<br>    cluster               = string<br>    anthos_membership     = string<br>    project_id            = string<br>    location              = string<br>    required_attestations = list(string)<br>    env_attestation       = string<br>    env_number            = number<br>    target_type           = string<br>  }))</pre> | `{}` | no |
| gar\_repo\_name | Docker artifact registry repo to store app build images | `string` | n/a | yes |
| github\_auth | Authentication configuration for GitHub. Required only if repo\_type is 'GITHUBv2'. | <pre>object({<br>    secret_id         = string<br>    app_id_secret_id  = string<br>    secret_project_id = string<br>  })</pre> | `null` | no |
| gitlab\_auth | Authentication configuration for GitLab. Required only if repo\_type is 'GITLABv2'. | <pre>object({<br>    read_authorizer_credential_secret_id = string<br>    authorizer_credential_secret_id      = string<br>    webhook_secret_id                    = string<br>    enterprise_host_uri                  = optional(string)<br>    enterprise_service_directory         = optional(string)<br>    enterprise_ca_certificate            = optional(string)<br>    secret_project_id                    = string<br>  })</pre> | `null` | no |
| primary\_location | Primary Google Cloud region for deploying resources like Cloud Build triggers and Cloud Deploy pipelines. | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |
| repository\_type | The type of the repository. Must be one of 'GITHUB', 'GITLAB', or 'CSR'. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| binauthz\_policy\_required\_attestations | Binary Authorization policy required attestation in GKE projects |
| cd\_repo\_name | Name of the CD source repository |
| clouddeploy\_delivery\_pipeline\_id | ID of the Cloud Deploy delivery pipeline |
| clouddeploy\_target\_id | ID(s) of Cloud Deploy targets |
| clouddeploy\_target\_names\_ordered | Names of Cloud Deploy targets in promotion order |
| deploy\_trigger\_names | Names of CD Cloud Build triggers |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
