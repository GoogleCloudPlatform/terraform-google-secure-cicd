# Standalone Multi Project CI/CD example

This end to end example showcases the [`secure-ci`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/secure-ci) and [`secure-cd`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/maodules/secure-cd) modules working together to create a secure software build and deploy pipeline. This example also deploys the [`cloudbuild-private-pool`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/cloudbuild-private-pool) and [`workerpool-gke-ha-vpn`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/workerpool-gke-ha-vpn) modules to enable deploying to private GKE clusters from Cloud Build.

This example also creates GKE clusters and accompanying VPC networks for sample target environments in separate projects.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

TODO

## Outputs

TODO

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
