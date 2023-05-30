# Secure CI/CD pipeline

This repository contains Terraform modules and example configurations to enable Google Cloud customers to quickly deploy a secure CI/CD pipeline, implementing many of the functions outlined in the [Shifting Left on Security](https://cloud.google.com/solutions/shifting-left-on-security) report.

The Terraform modules in this repository provide an opinionated architecture that incorporates and documents best practices for secure application delivery architecture.

### Tagline
Create a CI/CD pipeline that follows security best practices.

### Detailed
Set up a secure CI/CD pipeline that follows best practices for building, scanning, storing, and deploying containers to GKE.
You can choose whether to deploy your solution through the console directly or download as Terraform from GitHub to deploy later.

### Architecture
1. A developer pushes code for a container-based application to the App Source Code repository in Cloud Source Repositories. This repository must include a skaffold.yaml configuration file, a cloudbuild-ci.yaml configuration file, and templated Kubernetes manifests for the respective Kubernetes deployments, services and other objects.
1. Changes to the App Source Code repo will trigger a build of the containers as defined in the skaffold.yaml configuration.
1. Metadata about the built containers is stored in the build artifacts Cloud Storage bucket.
1. The resulting built containers will be scanned for container structure and CVE’s based on a customer-configurable security policy and stored in an Artifact Registry repository.
1. Upon passing all scans, the containers are signed by the Binary Authorization build attestor.
1. At the end of the build process, the pipeline creates a new Cloud Deploy release to rollout the newly built container images to the Dev environment.
1. After successful deployment, the Cloud Deploy operations Pub/Sub topic receives a confirmation message that triggers the post-deployment checks on the live application via Cloud Build.
1. Upon passing the post-deployment application security tests, the containers are signed by the security attestor.
1. The Cloud Deploy release is promoted, triggering a rollout to the QA environment. Steps 7-8 repeat, but the containers receive the quality attestor after passing through the QA environment.
1. The release is promoted for the final time, creating a rollout to the Prod environment.
1. The GKE clusters validate deployed containers based on the respective Binary Authorization policy, requiring additional attestors from the pipeline at each higher environment.
1. All Cloud Build and Cloud Deploy processes will run in a private Cloud Build worker pool hosted in a customer-managed VPC.

## Documentation
- [Architecture Diagram](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/blob/main/assets/secure_cicd_pipeline_v2.svg)

## Usage

Basic usage of this module is as follows:

```hcl
# Secure-CI
module "ci_pipeline" {
  source                  = "GoogleCloudPlatform/secure-cicd/google//modules/secure-ci"

  project_id              = var.project_id
  primary_location        = "us-central1"
  attestor_names_prefix   = ["build", "security", "quality"]
  app_build_trigger_yaml  = "cloudbuild-ci.yaml"
  runner_build_folder     = "../../../examples/app_cicd/cloud-build-builder"
  build_image_config_yaml = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name     = ".*"
}

# Secure-CD
module "cd_pipeline" {
  source           = "GoogleCloudPlatform/secure-cicd/google//modules/secure-cd"

  project_id              = var.project_id
  primary_location        = "us-central1"
  gar_repo_name           = module.ci_pipeline.app_artifact_repo
  cloudbuild_cd_repo      = "cloudbuild-cd-config-pc"
  deploy_branch_clusters  = {
    dev = {
      cluster               = "dev-cluster",
      project_id            = "gke-proj-dev",
      location              = "us-central1",
      required_attestations = ["projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/security-attestor"
      next_env              = "qa"
    },
    qa = {
      cluster               = "qa-cluster",
      project_id            = "gke-proj-prod",
      location              = "us-central1",
      required_attestations = ["projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/quality-attestor"
      next_env              = "prod"
    },
    prod = {
      cluster               = "prod-cluster",
      project_id            = "gke-proj-prod",
      location              = "us-central1",
      required_attestations = ["projects/${var.project_id}/attestors/quality-attestor", "projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = ""
      next_env              = ""
    },
  }
  app_deploy_trigger_yaml = "cloudbuild-cd.yaml"
  cache_bucket_name       = module.ci_pipeline.cache_bucket_name
  depends_on = [
    module.ci_pipeline
  ]
}
```

Functional examples are included in the
[examples](./examples/) directory.

### Build Configuration
Example Cloud Build configuration files are located in the [Build](./build/) folder. Push the `cloudbuild-ci.yaml` configuration to the application source code repository. Push the `cloudbuild-cd.yaml` configuration to the wet manifest repository. These build configurations offer a baseline for adhering to S3C application delivery practices within this blueprint, and are customizable as needed.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

The following dependencies must be available:

- [Google Cloud SDK](https://cloud.google.com/sdk/install) version 357.0.0 or later
- [Terraform][terraform] v1.0
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v4.3.0

### Service Account

A service account with the following roles must be used to provision
the resources of this blueprint:

- Project level:
  - CI/CD project
      - `roles/storage.admin`
      - `roles/artifactregistry.admin`
      - `roles/binaryauthorization.attestorsAdmin`
      - `roles/cloudbuild.builds.builder`
      - `roles/cloudbuild.workerPoolOwner`
      - `roles/clouddeploy.releaser`
      - `roles/cloudkms.admin`
      - `roles/cloudkms.publicKeyViewer`
      - `roles/containeranalysis.notes.editor`
      - `roles/compute.networkAdmin`
      - `roles/serviceusage.serviceUsageAdmin`
      - `roles/source.admin`
      - `roles/resourcemanager.projectIamAdmin`
      - `roles/viewer`
  - GKE projects
      - `roles/compute.networkAdmin`
      - `roles/binaryauthorization.policyEditor`
      - `roles/resourcemanager.projectIamAdmin`
      - `roles/serviceusage.serviceUsageViewer`
      - `roles/iam.serviceAccountUser`

The [Project Factory module][project-factory-module] and the
[IAM module][iam-module] may be used in combination to provision a
service account with the necessary roles applied.

### APIs

Projects with the following APIs enabled must be used to host the
resources of this module:

CI/CD Project
- Cloud Resource Manager API `cloudresourcemanager.googleapis.com`
- Cloud Billing API `cloudbilling.googleapis.com`
- Storage API `storage-api.googleapis.com`
- Service Usage API `serviceusage.googleapis.com`
- Cloud Build API `cloudbuild.googleapis.com`
- Cloud Deploy API `clouddeploy.googleapis.com`
- Pub/Sub API `pubsub.googleapis.com`
- Container Registry API `containerregistry.googleapis.com`
- IAM Credentials API `iamcredentials.googleapis.com`
- Cloud Source Repositories API `sourcerepo.googleapis.com`
- Artifact Registry API `artifactregistry.googleapis.com`
- Container Analysis API `containeranalysis.googleapis.com`
- Cloud KMS API `cloudkms.googleapis.com`
- Binary Authorization API `binaryauthorization.googleapis.com`
- Container Scanning API `containerscanning.googleapis.com`

GKE Projects:
- Cloud Resource Manager API `cloudresourcemanager.googleapis.com`
- Cloud Billing API `cloudbilling.googleapis.com`
- Storage API `storage-api.googleapis.com`
- Service Usage API `serviceusage.googleapis.com`
- Container Registry API `containerregistry.googleapis.com`
- IAM Credentials API `iamcredentials.googleapis.com`
- Artifact Registry API `artifactregistry.googleapis.com`
- Container Analysis API `containeranalysis.googleapis.com`
- Cloud KMS API `cloudkms.googleapis.com`
- Binary Authorization API `binaryauthorization.googleapis.com`
- Container Scanning API `containerscanning.googleapis.com`
- Kubernetes Engine API `container.googleapis.com`
- Cloud Trace API `cloudtrace.googleapis.com`
- Cloud Monitoring API `monitoring.googleapis.com`
- Coud Logging API `logging.googleapis.com`

The [Project Factory module][project-factory-module] can be used to
provision a project with the necessary APIs enabled.

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html
