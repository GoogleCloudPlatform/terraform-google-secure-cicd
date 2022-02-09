# Secure CI/CD Blueprint

This repository contains Terraform modules and example configurations to enable Google Cloud customers to quickly deploy a secure CI/CD pipeline, implementing many of the functions outlined in the [Shifting Left on Security](https://cloud.google.com/solutions/shifting-left-on-security) report.

The Terraform modules in this repository provide an opinionated architecture that incorporates and documents best practices for secure application delivery architecture.

## Usage

Basic usage of this module is as follows:

```hcl
# Secure-CI
module "ci_pipeline" {
  source                  = "GoogleCloudPlatform/terraform-google-secure-cicd//secure-ci"

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
  source           = "GoogleCloudPlatform/terraform-google-secure-cicd//secure-cd"

  project_id              = var.project_id
  primary_location        = "us-central1"
  gar_repo_name           = module.ci_pipeline.app_artifact_repo
  manifest_wet_repo       = "app-wet-manifests"
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

A project with the following APIs enabled must be used to host the
resources of this module:

CI/CD Project
- Cloud Resource Manager API `cloudresourcemanager.googleapis.com`
- Cloud Billing API `cloudbilling.googleapis.com`
- Storage API `storage-api.googleapis.com`
- Service Usage API `serviceusage.googleapis.com`
- Cloud Build API `cloudbuild.googleapis.com`
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
