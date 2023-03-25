# Standalone Single Project CI/CD example

This end to end example showcases the [`secure-ci`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/secure-ci) and [`secure-cd`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/maodules/secure-cd) modules working together to create a secure software build and deploy pipeline. This example also deploys the [`cloudbuild-private-pool`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/cloudbuild-private-pool) and [`workerpool-gke-ha-vpn`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/workerpool-gke-ha-vpn) modules to enable deploying to private GKE clusters from Cloud Build.

This example also creates GKE clusters and accompanying VPC networks for multiple smaple environments in a single project for simplified deployment and demonstration purposes.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_name | Name of intended deployed application; to be used as a prefix for certain resources | `string` | `"my-app"` | no |
| env1\_name | Name of environment 1 | `string` | `"dev"` | no |
| env2\_name | Name of environment 2 | `string` | `"qa"` | no |
| env3\_name | Name of environment 3 | `string` | `"prod"` | no |
| labels | A set of key/value label pairs to assign to the resources deployed by this blueprint. | `map(string)` | `{}` | no |
| project\_id | Project ID in which all resources will be deployed | `string` | n/a | yes |
| region | Location in which all regional resources will be deployed | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| app\_source\_repo | URL of the created CSR app soure repo |
| cloudbuild\_cd\_repo\_name | URL of the created CSR app soure repo |
| console\_walkthrough\_link | URL to open the in-console walkthrough. |
| gar\_repo | Artifact Registry repo |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
