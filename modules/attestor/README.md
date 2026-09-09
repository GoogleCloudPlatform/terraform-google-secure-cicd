# Binary Authorization Attestors Module

This module provisions Google Cloud Binary Authorization attestors and the underlying Cloud KMS infrastructure required to securely sign and verify container images.

Binary Authorization is a service on Google Cloud that provides software supply-chain security for applications that run in the cloud. By using this module, you can create multiple attestors (e.g., for build, security, and quality gates) that ensure only trusted, verified container images are deployed to your Google Kubernetes Engine (GKE) or Cloud Run environments.

## Features

This module provisions the following resources:

* **Cloud KMS Key Ring**: Creates a regional Key Management Service (KMS) key ring to securely store the cryptographic keys used for signing.
* **Binary Authorization Attestors**: Dynamically creates one or more attestors based on a provided list of prefixes.
* **KMS Crypto Keys**: Automatically generates the asymmetric signing keys for each attestor via the official `terraform-google-modules/kubernetes-engine//modules/binary-authorization` sub-module.

## Prerequisites

### APIs

Ensure the following APIs are enabled in your GCP project:

* `binaryauthorization.googleapis.com`
* `cloudkms.googleapis.com`

### IAM Roles

The identity executing this Terraform module needs the following minimum roles (or equivalent permissions) on the target project:

* `roles/binaryauthorization.attestorsAdmin` (To create and manage the attestors)
* `roles/cloudkms.admin` (To create the KMS key ring and crypto keys)

## Usage

Basic usage of this module is as follows:

```hcl
module "binauthz_attestors" {
  source = "path/to/this/module"

  project_id            = "my-gcp-project-id"
  primary_location      = "us-central1"

  # Creates three distinct attestors and their corresponding KMS keys
  attestor_names_prefix = ["build", "security", "qa"]
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| attestor\_names\_prefix | A list of Binary Authorization attestors to create. The first attestor specified in this list will be used as the build-attestor during the CI phase. | `list(string)` | n/a | yes |
| primary\_location | Region used for key-ring | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| binauth\_attestor\_ids | IDs of Attestors |
| binauth\_attestor\_names | Names of Attestors |
| binauth\_attestor\_project\_id | Project ID where attestors get created |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
